import type { AdminUser, DatabaseState } from "@/lib/types";
import { buildAiContext, type AiPageContext } from "@/lib/ai/context";
import { runAiExecution } from "@/lib/ai/execution-engine";

export function routeAiRequest(input: {
  actor: AdminUser;
  state: DatabaseState;
  prompt: string;
  page?: Partial<AiPageContext>;
}) {
  const context = buildAiContext({
    actor: input.actor,
    state: input.state,
    page: input.page,
  });
  return runAiExecution(context, input.prompt);
}
