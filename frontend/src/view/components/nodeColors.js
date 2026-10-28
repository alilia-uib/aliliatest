// Stable color per domain node type. A node may carry extra labels
// (e.g. "CIM", "Active") - coloring is always driven by the type label
// found here, never by those extras.

export const NODE_COLORS = {
  ACLineSegment: "#e6194b",
  ConformLoad: "#3cb44b",
  EnergyServicePoint: "#ffe119",
  BaseVoltage: "#4363d8",
  Bay: "#f58231",
  BusbarSection: "#911eb4",
  TransformerWinding: "#42d4f4",
  BusNode: "#f032e6",
  FaultInterrupter: "#bfef45",
  FaultIndicator: "#fabed4",
  GroundImpedance: "#469990",
  ConnectivityNode: "#dcbeff",
  ExternalNetworkInjection: "#9a6324",
  Fuse: "#c0c000", // mustard
  LoadBreakSwitch: "#800000",
  Disconnector: "#aaffc3",
  SynchronousMachine: "#808000",
  LinearShuntCompensator: "#ffd8b1",
  PetersenCoil: "#000075",
  EquivalentInjection: "#a9a9a9",
  PowerTransformer: "#ff4500",
  PowerTransformerEnd: "#1e90ff",
  PSRType: "#00ced1",
  RatioTapChanger: "#ff1493",
  SubGeographicalRegion: "#7cfc00",
  Substation: "#8b4513",
  Terminal: "#5f9ea0",
  VoltageLevel: "#d2691e",
  Line: "#6a5acd",
  UsagePoint: "#ff69b4",
  CurrentLimit: "#2e8b57",
  OperationalLimitSet: "#daa520",
  OperationalLimitType: "#b8860b",
  StationSupply: "#7b68ee",
  Breaker: "#dc143c",
  Jumper: "#00fa9a",
  Junction: "#4682b4",
  GroundDisconnector: "#9932cc",
  Ground: "#a0522d",
};

// Fallback for nodes whose labels don't include a known type.
export const DEFAULT_NODE_COLOR = "#cccccc";

// Resolve the domain type label for a node, ignoring non-type labels.
export function getNodeType(node) {
  return (node.labels || []).find((label) => label in NODE_COLORS) ?? null;
}

export function getNodeColor(node) {
  const type = getNodeType(node);
  return type ? NODE_COLORS[type] : DEFAULT_NODE_COLOR;
}
