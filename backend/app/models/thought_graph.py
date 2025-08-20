from sqlalchemy import Column, String, Text, ForeignKey, JSON, Enum
from sqlalchemy.orm import relationship
from .base import BaseModel
import enum

class NodeType(str, enum.Enum):
    QUESTION = "question"
    STANDPOINT = "standpoint"
    ARGUMENT = "argument"
    COUNTER_QUESTION = "counter_question"

class EdgeType(str, enum.Enum):
    SUPPORTS = "supports"
    CHALLENGES = "challenges"
    RELATES = "relates"

class ThoughtGraph(BaseModel):
    __tablename__ = "thought_graphs"
    
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)  # Will be implemented with user auth
    
    # Relationships
    nodes = relationship("GraphNode", back_populates="graph", cascade="all, delete-orphan")
    edges = relationship("GraphEdge", back_populates="graph", cascade="all, delete-orphan")

class GraphNode(BaseModel):
    __tablename__ = "graph_nodes"
    
    graph_id = Column(Integer, ForeignKey("thought_graphs.id", ondelete="CASCADE"), nullable=False)
    node_type = Column(Enum(NodeType), nullable=False)
    content = Column(Text, nullable=False)
    position_x = Column(JSON, nullable=True)  # Store position data for the frontend
    position_y = Column(JSON, nullable=True)
    metadata = Column(JSON, nullable=True)  # Additional metadata
    
    # Relationships
    graph = relationship("ThoughtGraph", back_populates="nodes")
    source_edges = relationship("GraphEdge", 
                              foreign_keys="GraphEdge.source_node_id",
                              back_populates="source_node")
    target_edges = relationship("GraphEdge",
                              foreign_keys="GraphEdge.target_node_id",
                              back_populates="target_node")

class GraphEdge(BaseModel):
    __tablename__ = "graph_edges"
    
    graph_id = Column(Integer, ForeignKey("thought_graphs.id", ondelete="CASCADE"), nullable=False)
    source_node_id = Column(Integer, ForeignKey("graph_nodes.id", ondelete="CASCADE"), nullable=False)
    target_node_id = Column(Integer, ForeignKey("graph_nodes.id", ondelete="CASCADE"), nullable=False)
    edge_type = Column(Enum(EdgeType), nullable=False)
    label = Column(String(100), nullable=True)
    
    # Relationships
    graph = relationship("ThoughtGraph", back_populates="edges")
    source_node = relationship("GraphNode", 
                             foreign_keys=[source_node_id],
                             back_populates="source_edges")
    target_node = relationship("GraphNode",
                             foreign_keys=[target_node_id],
                             back_populates="target_edges")
