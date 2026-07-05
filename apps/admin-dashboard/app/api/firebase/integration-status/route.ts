import { requireFirebaseAdmin, firebaseApiError } from "@/lib/firebase/server-auth";
import { activeAiProvider } from "@/lib/integrations/api-center";

export const runtime = "nodejs";

const has = (name: string) => Boolean(process.env[name]?.trim());

export async function GET(request: Request) {
  try {
    await requireFirebaseAdmin(request);
    const ai = await activeAiProvider();
    const aiProvider =
      "record" in ai && ai.record ? ai.record.providerName : "provider" in ai ? ai.provider : "disabled";
    const aiConfigured = Boolean(ai.credentials.apiKey);
    return Response.json({
      firebase: {
        configured: has("NEXT_PUBLIC_FIREBASE_PROJECT_ID"),
        label: "Firebase project",
      },
      firestore: {
        configured: has("NEXT_PUBLIC_FIREBASE_PROJECT_ID"),
        label: "Cloud Firestore",
      },
      storage: {
        configured: has("NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET"),
        label: "Firebase Storage",
      },
      maps: {
        configured: has("NEXT_PUBLIC_GOOGLE_MAPS_API_KEY"),
        label: "Google Maps",
      },
      resend: {
        configured:
          has("RESEND_API_KEY") &&
          has("RESEND_FROM_EMAIL") &&
          has("RESEND_FROM_NAME"),
        label: "Resend email",
      },
      gemini: {
        configured: aiConfigured || has("GEMINI_API_KEY"),
        label: `AI provider (${aiProvider})`,
        model:
          ("record" in ai && ai.record?.defaultModel) ||
          ("defaultModel" in ai ? ai.defaultModel : "") ||
          process.env.GEMINI_MODEL?.trim() ||
          process.env.OPENAI_MODEL?.trim() ||
          "not selected",
      },
    });
  } catch (error) {
    return firebaseApiError(error);
  }
}
