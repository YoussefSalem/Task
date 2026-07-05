import type { AiExecution, AiMemory } from "@/lib/types";

export function memoryFromExecution(execution: AiExecution): Partial<AiMemory> | null {
  const entityType = execution.context.resolvedEntityType;
  const entityId = execution.context.resolvedEntityId;
  if (!entityType || !entityId) return null;
  return {
    id: `${execution.actorId}-last-record`,
    scope: "admin",
    key: "last-record",
    value: `${entityType}:${entityId}`,
    recordType: entityType,
    recordId: entityId,
  };
}
