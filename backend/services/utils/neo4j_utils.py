# Helpers that transform neo4j driver objects into the
# { nodes, links } shape the frontend force-graph expects.

from neo4j.time import Date, DateTime


def _serialize_value(value):
    """Convert neo4j temporal types into dates as dd.mm.yyyy."""
    if isinstance(value, (Date, DateTime)):
        # both expose .to_native() -> datetime.date / datetime.datetime
        return value.to_native().strftime("%d.%m.%Y %H:%M:%S")
    if isinstance(value, list):
        return [_serialize_value(v) for v in value]
    return value


def _serialize_properties(entity):
    return {key: _serialize_value(value) for key, value in dict(entity).items()}


def addNode(node, nodes):
    # element_id is the stable identifier in neo4j driver 5+/6 (id is deprecated)
    if node.element_id not in nodes:
        nodes[node.element_id] = {
            "id": node.element_id,
            "labels": list(node.labels),
            "properties": _serialize_properties(node),
        }


def addRelationship(n, r, m, links):
    links.append({
        "id": r.element_id,
        "source": n.element_id,
        "target": m.element_id,
        "type": r.type,
        "properties": _serialize_properties(r),
    })
