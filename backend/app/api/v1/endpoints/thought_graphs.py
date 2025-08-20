from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional

from .... import models, schemas
from ....db.base import get_db
from ....core.security import get_current_user

router = APIRouter()

@router.post("/", response_model=schemas.ThoughtGraphResponse)
def create_thought_graph(
    graph: schemas.ThoughtGraphCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new thought graph"""
    db_graph = models.ThoughtGraph(
        title=graph.title,
        description=graph.description,
        created_by=current_user.id if current_user else None
    )
    db.add(db_graph)
    db.commit()
    db.refresh(db_graph)
    
    # Create nodes
    node_map = {}
    for node in graph.nodes:
        db_node = models.GraphNode(
            graph_id=db_graph.id,
            node_type=node.node_type,
            content=node.content,
            position_x=node.position_x,
            position_y=node.position_y,
            metadata=node.metadata
        )
        db.add(db_node)
        db.commit()
        db.refresh(db_node)
        node_map[node.id] = db_node.id
    
    # Create edges
    for edge in graph.edges:
        db_edge = models.GraphEdge(
            graph_id=db_graph.id,
            source_node_id=node_map[edge.source_node_id],
            target_node_id=node_map[edge.target_node_id],
            edge_type=edge.edge_type,
            label=edge.label
        )
        db.add(db_edge)
    
    db.commit()
    db.refresh(db_graph)
    return db_graph

@router.get("/{graph_id}", response_model=schemas.ThoughtGraphResponse)
def read_thought_graph(
    graph_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get a specific thought graph by ID"""
    db_graph = db.query(models.ThoughtGraph).filter(models.ThoughtGraph.id == graph_id).first()
    if not db_graph:
        raise HTTPException(status_code=404, detail="Thought graph not found")
    
    # Check permissions if needed
    # if db_graph.created_by and db_graph.created_by != current_user.id:
    #     raise HTTPException(status_code=403, detail="Not authorized to access this graph")
    
    return db_graph

@router.get("/", response_model=schemas.ThoughtGraphListResponse)
def list_thought_graphs(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """List all thought graphs"""
    # In a real app, you'd want to filter by user or implement proper permissions
    total = db.query(models.ThoughtGraph).count()
    graphs = db.query(models.ThoughtGraph).offset(skip).limit(limit).all()
    
    return {
        "total": total,
        "items": graphs
    }

@router.put("/{graph_id}", response_model=schemas.ThoughtGraphResponse)
def update_thought_graph(
    graph_id: int,
    graph_update: schemas.ThoughtGraphUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Update a thought graph"""
    db_graph = db.query(models.ThoughtGraph).filter(models.ThoughtGraph.id == graph_id).first()
    if not db_graph:
        raise HTTPException(status_code=404, detail="Thought graph not found")
    
    # Check permissions
    # if db_graph.created_by and db_graph.created_by != current_user.id:
    #     raise HTTPException(status_code=403, detail="Not authorized to update this graph")
    
    for var, value in vars(graph_update).items():
        if value is not None:
            setattr(db_graph, var, value)
    
    db.commit()
    db.refresh(db_graph)
    return db_graph

@router.delete("/{graph_id}")
def delete_thought_graph(
    graph_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Delete a thought graph"""
    db_graph = db.query(models.ThoughtGraph).filter(models.ThoughtGraph.id == graph_id).first()
    if not db_graph:
        raise HTTPException(status_code=404, detail="Thought graph not found")
    
    # Check permissions
    # if db_graph.created_by and db_graph.created_by != current_user.id:
    #     raise HTTPException(status_code=403, detail="Not authorized to delete this graph")
    
    db.delete(db_graph)
    db.commit()
    return {"message": "Thought graph deleted successfully"}
