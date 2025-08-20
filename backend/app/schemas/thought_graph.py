from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class NodeType(str, Enum):
    QUESTION = "question"
    STANDPOINT = "standpoint"
    ARGUMENT = "argument"
    COUNTER_QUESTION = "counter_question"

class EdgeType(str, Enum):
    SUPPORTS = "supports"
    CHALLENGES = "challenges"
    RELATES = "relates"

# Base schemas
class GraphNodeBase(BaseModel):
    node_type: NodeType
    content: str
    position_x: Optional[float] = 0.0
    position_y: Optional[float] = 0.0
    metadata: Optional[Dict[str, Any]] = None

class GraphEdgeBase(BaseModel):
    source_node_id: int
    target_node_id: int
    edge_type: EdgeType
    label: Optional[str] = None

class ThoughtGraphBase(BaseModel):
    title: str
    description: Optional[str] = None

# Create schemas
class GraphNodeCreate(GraphNodeBase):
    pass

class GraphEdgeCreate(GraphEdgeBase):
    pass

class ThoughtGraphCreate(ThoughtGraphBase):
    nodes: List[GraphNodeCreate] = []
    edges: List[GraphEdgeCreate] = []

# Update schemas
class GraphNodeUpdate(BaseModel):
    content: Optional[str] = None
    position_x: Optional[float] = None
    position_y: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None

class GraphEdgeUpdate(BaseModel):
    edge_type: Optional[EdgeType] = None
    label: Optional[str] = None

class ThoughtGraphUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None

# Response schemas
class GraphNodeResponse(GraphNodeBase):
    id: int
    graph_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class GraphEdgeResponse(GraphEdgeBase):
    id: int
    graph_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class ThoughtGraphResponse(ThoughtGraphBase):
    id: int
    created_by: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    nodes: List[GraphNodeResponse] = []
    edges: List[GraphEdgeResponse] = []

    class Config:
        orm_mode = True

# For API responses
class ThoughtGraphListResponse(BaseModel):
    total: int
    items: List[ThoughtGraphResponse]
