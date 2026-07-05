import {
  firebaseApiError,
  requireFirebaseAdmin,
} from "@/lib/firebase/server-auth";
import { resetDemoData } from "@/lib/firebase/demo-seed";
import { hasPermission } from "@/lib/permissions";
import { requestId } from "@/lib/server/logger";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const id = requestId(request);
  try {
    const actor = await requireFirebaseAdmin(request);
    if (
      actor.isDemoUser ||
      !hasPermission(actor.role, actor.permissions, "settings.edit")
    ) {
      throw new Response("Forbidden", { status: 403 });
    }
    const result = await resetDemoData({ id: actor.id, name: actor.name });
    return Response.json(result);
  } catch (error) {
    return firebaseApiError(error, {
      requestId: id,
      route: "/api/firebase/demo/reset",
    });
  }
}
