import type { AiRecommendation, AiRiskLevel } from "@/lib/types";

export function highestRisk(recommendations: AiRecommendation[]): AiRiskLevel {
  const order: AiRiskLevel[] = ["LOW", "MEDIUM", "HIGH", "CRITICAL"];
  return recommendations.reduce<AiRiskLevel>(
    (risk, item) => (order.indexOf(item.risk) > order.indexOf(risk) ? item.risk : risk),
    "LOW",
  );
}

export function executionStatus(risk: AiRiskLevel) {
  return risk === "HIGH" || risk === "CRITICAL" ? "Needs confirmation" : "Completed";
}
