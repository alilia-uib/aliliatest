// component for visualizing a neo4j subgraph in a react app

import { useState } from "react";
import ForceGraph2D from "react-force-graph-2d";
import { getNodeColor, getNodeType, NODE_COLORS } from "./nodeColors";

const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000").replace(/\/+$/, "");

export default function GraphView() {
  const [data, setData] = useState({ nodes: [], links: [] });
  const [name, setName] = useState("");
  const [depth, setDepth] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [selectedNode, setSelectedNode] = useState(null);

  const fetchGraph = async (e) => {
    e?.preventDefault();
    if (!name.trim()) return;

    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({ name: name.trim(), depth });
      const res = await fetch(`${API_BASE}/sub_graph?${params}`);
      if (!res.ok) throw new Error(`Request failed: ${res.status}`);
      const graph = await res.json();
      setData(graph);
      if (graph.nodes.length === 0) {
        setError(`No node found matching "${name}".`);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ width: "100%", height: "100%", position: "relative" }}>
      <form
        onSubmit={fetchGraph}
        style={{
          position: "absolute",
          top: 12,
          left: 12,
          zIndex: 10,
          display: "flex",
          gap: 8,
          alignItems: "center",
          background: "rgba(255,255,255,0.9)",
          padding: 8,
          borderRadius: 8,
        }}
      >
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Source node name (e.g. Vatne tra)"
          style={{ padding: "4px 8px" }}
        />
        <label style={{ fontSize: 14 }}>
          Depth:{" "}
          <input
            type="number"
            min={1}
            max={10}
            value={depth}
            onChange={(e) => setDepth(Number(e.target.value))}
            style={{ width: 56, padding: "4px" }}
          />
        </label>
        <button type="submit" disabled={loading}>
          {loading ? "Loading…" : "Search"}
        </button>
        {error && <span style={{ color: "crimson", fontSize: 13 }}>{error}</span>}
      </form>

      {selectedNode && (
        <div
          style={{
            position: "absolute",
            top: 12,
            right: 12,
            zIndex: 10,
            width: 320,
            maxHeight: "calc(100% - 24px)",
            overflowY: "auto",
            background: "rgba(255,255,255,0.96)",
            padding: 16,
            borderRadius: 8,
            boxShadow: "0 2px 8px rgba(0,0,0,0.2)",
            fontSize: 14,
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <strong>{selectedNode.labels?.join(", ") || "Node"}</strong>
            <button onClick={() => setSelectedNode(null)}>✕</button>
          </div>

          <table style={{ width: "100%", marginTop: 12, borderCollapse: "collapse" }}>
            <tbody>
              <tr>
                <td style={{ color: "#888", paddingRight: 8, verticalAlign: "top" }}>id</td>
                <td style={{ wordBreak: "break-all" }}>{selectedNode.id}</td>
              </tr>
              {Object.entries(selectedNode.properties ?? {}).map(([key, value]) => (
                <tr key={key}>
                  <td style={{ color: "#888", paddingRight: 8, verticalAlign: "top" }}>
                    {key}
                  </td>
                  <td style={{ wordBreak: "break-word" }}>
                    {typeof value === "object" ? JSON.stringify(value) : String(value)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {data.nodes.length > 0 && (
        <div
          style={{
            position: "absolute",
            bottom: 12,
            left: 12,
            zIndex: 10,
            maxHeight: "40%",
            overflowY: "auto",
            background: "rgba(255,255,255,0.9)",
            padding: 12,
            borderRadius: 8,
            fontSize: 13,
          }}
        >
          {[...new Set(data.nodes.map(getNodeType).filter(Boolean))]
            .sort()
            .map((type) => (
              <div
                key={type}
                style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}
              >
                <span
                  style={{
                    width: 12,
                    height: 12,
                    borderRadius: "50%",
                    background: NODE_COLORS[type],
                    display: "inline-block",
                  }}
                />
                {type}
              </div>
            ))}
        </div>
      )}

      <ForceGraph2D
        graphData={data}
        nodeLabel={(node) =>
          node.properties?.name ?? node.labels?.join(", ") ?? node.id
        }
        nodeColor={getNodeColor}
        linkLabel={(link) => link.type}
        linkDirectionalArrowLength={4}
        onNodeClick={(node) => setSelectedNode(node)}
        onBackgroundClick={() => setSelectedNode(null)}
      />
    </div>
  );
}
