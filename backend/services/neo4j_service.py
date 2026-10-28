# communication with neo4j database and api for use in frontend

# query neo4j
# transform results

from neo4j import GraphDatabase
from services.utils import neo4j_utils


class Neo4jService:
    def __init__(self, uri, user, password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))

    def close(self):
        self.driver.close()

    def _to_graph(self, nodes_iter, rels_iter):
        """Collapse driver nodes/relationships into the { nodes, links } shape."""
        nodes = {}
        links = []

        for node in nodes_iter:
            neo4j_utils.addNode(node, nodes)

        for rel in rels_iter:
            neo4j_utils.addRelationship(rel.start_node, rel, rel.end_node, links)

        return {
            "nodes": list(nodes.values()),
            "links": links,
        }

    def get_sub_graph_by_name(self, name, depth=1):
        """
        Find a source node whose `name` matches (case-insensitive, contains)
        and return the whole subgraph reachable within `depth` hops.

        Uses apoc.path.subgraphAll which returns the deduplicated set of nodes
        and the relationships between them - exactly what a graph view needs.
        """
        query = """
        MATCH (source:Substation)
        WHERE toLower(source.name) CONTAINS toLower($name)
        WITH source
        LIMIT 1
        CALL apoc.path.subgraphAll(source, { maxLevel: $depth })
        YIELD nodes, relationships
        RETURN nodes, relationships
        """

        with self.driver.session() as session:
            record = session.run(query, name=name, depth=depth).single()

            if record is None:
                # no node matched the given name
                return {"nodes": [], "links": []}

            return self._to_graph(record["nodes"], record["relationships"])