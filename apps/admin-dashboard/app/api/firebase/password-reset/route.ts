import { z } from "zod";
import { firebaseAdminAuth, firebaseAdminDb } from "@/lib/firebase/admin";
import { dashboardUrl, sendPasswordResetEmail } from "@/lib/email/invitations";
import { errorMessage, requestId, serverLog } from "@/lib/server/logger";

export const runtime = "nodejs";

const schema = z.object({
  email: z.string().trim().email(),
});

export async function POST(request: Request) {
  const id = requestId(request);
  try {
    const { email } = schema.parse(await request.json());
    const normalizedEmail = email.toLowerCase();
    const url = dashboardUrl();
    const resetLink = await firebaseAdminAuth.generatePasswordResetLink(
      normalizedEmail,
      {
        url: `${url}/login`,
        handleCodeInApp: false,
      },
    );
    const sent = await sendPasswordResetEmail({
      to: normalizedEmail,
      resetLink,
      dashboardUrl: url,
    });
    await firebaseAdminDb.collection("auditLogs").add({
      actorId: "system",
      actorName: "Password reset",
      action: "auth.password_reset_email_sent",
      entityType: "admin",
      entityId: normalizedEmail,
      detail: `Sent password reset email via Resend to ${normalizedEmail}`,
      provider: sent.provider,
      messageId: sent.messageId,
      createdAt: sent.sentAt,
    });
    serverLog("info", "Password reset email sent through Resend", {
      requestId: id,
      email: normalizedEmail,
      messageId: sent.messageId,
    });
    return Response.json({ ok: true });
  } catch (error) {
    const message = errorMessage(error);
    serverLog("error", "Password reset email failed", {
      requestId: id,
      route: "/api/firebase/password-reset",
      error: message,
      code: (error as { code?: string }).code,
    });
    return Response.json({ error: message }, { status: 500 });
  }
}
