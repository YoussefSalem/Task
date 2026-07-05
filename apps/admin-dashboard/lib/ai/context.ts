import type { AdminUser, AiMemory, DatabaseState } from "@/lib/types";

export interface AiPageContext {
  page: string;
  currentEntityType?: string;
  currentEntityId?: string;
}

export interface AiRuntimeContext {
  actor: AdminUser;
  state: DatabaseState;
  page: AiPageContext;
  memories: AiMemory[];
  now: Date;
}

export function buildAiContext(input: {
  actor: AdminUser;
  state: DatabaseState;
  page?: Partial<AiPageContext>;
}): AiRuntimeContext {
  return {
    actor: input.actor,
    state: input.state,
    page: { page: input.page?.page ?? "Unknown", ...input.page },
    memories: input.state.aiMemories.filter(
      (memory) =>
        memory.scope === "platform" || memory.actorId === input.actor.id,
    ),
    now: new Date(),
  };
}

export function recallLastRecord(context: AiRuntimeContext) {
  return context.memories
    .filter((memory) => memory.key === "last-record" && memory.recordId)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))[0];
}
