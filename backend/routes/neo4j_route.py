from fastapi import APIRouter, Query
from services.neo4j_service import Neo4jService
from config import NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD

router = APIRouter()

neo4j_service = Neo4jService(NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD)

@router.get("/sub_graph")
def get_sub_graph(
    name: str = Query(..., min_length=1, description="Name of the source node to search for"),
    depth: int = Query(1, ge=1, le=10, description="How many hops out from the source node"),
):
    """Return the subgraph within `depth` hops of the source node matched by name."""
    return neo4j_service.get_sub_graph_by_name(name, depth)

