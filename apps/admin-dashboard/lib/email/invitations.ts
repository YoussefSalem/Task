import { decryptCredentials, loadProductionIntegration } from "@/lib/integrations/api-center";

type InvitationEmailInput = {
  to: string;
  name: string;
  roleName: string;
  invitedBy: string;
  dashboardUrl: string;
  setupLink: string;
  expiresAt?: string;
};

type InvitationEmailResult = {
  provider: "resend";
  messageId: string;
  sentAt: string;
};

function requiredEnv(name: string) {
  const value = process.env[name]?.trim();
  if (!value)
    throw new Error(
      `Email provider is not configured. Set ${name} before sending email.`,
    );
  return value;
}

async function resendApiKey() {
  const configured = await loadProductionIntegration("resend").catch(() => null);
  if (configured?.enabled) {
    const credentials = decryptCredentials(configured.encryptedCredentials);
    if (credentials.apiKey?.trim()) return credentials.apiKey.trim();
  }
  return requiredEnv("RESEND_API_KEY");
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function resendFrom() {
  const name = requiredEnv("RESEND_FROM_NAME");
  const email = requiredEnv("RESEND_FROM_EMAIL");
  if (email.includes("<") || email.includes(">"))
    throw new Error(
      "RESEND_FROM_EMAIL must be a plain email address. Put the sender name in RESEND_FROM_NAME.",
    );
  return `${escapeHtml(name)} <${email}>`;
}

function invitationHtml(input: InvitationEmailInput) {
  const expiry = input.expiresAt
    ? `<p style="margin:18px 0 0;color:#fbbf24;font-size:12px;line-height:1.6">This invitation expires on ${escapeHtml(new Date(input.expiresAt).toLocaleString("en-US", { dateStyle: "medium", timeStyle: "short" }))}.</p>`
    : "";
  return `
  <div style="margin:0;background:#08080a;padding:32px;font-family:Inter,Arial,sans-serif;color:#f4f4f5">
    <div style="max-width:620px;margin:0 auto;border:1px solid rgba(255,255,255,.10);border-radius:24px;background:#111114;overflow:hidden">
      <div style="padding:28px 28px 18px;border-bottom:1px solid rgba(255,255,255,.08)">
        <div style="font-size:12px;letter-spacing:.16em;text-transform:uppercase;color:#8b5cf6;font-weight:700">Task Admin Dashboard</div>
        <h1 style="margin:14px 0 0;font-size:26px;line-height:1.2;color:#fff">You’re invited to Task Admin</h1>
        <p style="margin:10px 0 0;color:#a1a1aa;font-size:14px;line-height:1.7">Hi ${input.name}, ${input.invitedBy} invited you to join the Task operations dashboard as <strong style="color:#fff">${input.roleName}</strong>.</p>
      </div>
      <div style="padding:28px">
        <p style="margin:0 0 18px;color:#d4d4d8;font-size:14px;line-height:1.7">Use the secure Firebase password setup link below to create your password and access the live dashboard.</p>
        <a href="${input.setupLink}" style="display:inline-block;background:#6366f1;color:#fff;text-decoration:none;font-weight:700;border-radius:14px;padding:14px 20px;font-size:14px">Set up password</a>
        ${expiry}
        <div style="margin-top:24px;padding:16px;border-radius:16px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08)">
          <div style="font-size:12px;color:#71717a">Dashboard URL</div>
          <a href="${input.dashboardUrl}" style="display:block;margin-top:6px;color:#c4b5fd;text-decoration:none;font-size:14px">${input.dashboardUrl}</a>
        </div>
        <p style="margin:22px 0 0;color:#71717a;font-size:12px;line-height:1.6">If the button does not work, copy and paste this secure setup link into your browser:</p>
        <p style="word-break:break-all;color:#a1a1aa;font-size:12px;line-height:1.6">${input.setupLink}</p>
      </div>
    </div>
  </div>`;
}

function invitationText(input: InvitationEmailInput) {
  return [
    `Hi ${input.name},`,
    "",
    `${input.invitedBy} invited you to join the Task Admin Dashboard as ${input.roleName}.`,
    "",
    `Dashboard: ${input.dashboardUrl}`,
    `Set up your password: ${input.setupLink}`,
    input.expiresAt ? `Invitation expires: ${new Date(input.expiresAt).toLocaleString("en-US")}` : "",
    "",
    "If you were not expecting this invitation, ignore this email.",
  ].filter(Boolean).join("\n");
}

export async function sendInvitationEmail(
  input: InvitationEmailInput,
): Promise<InvitationEmailResult> {
  const apiKey = await resendApiKey();
  const from = resendFrom();
  const replyTo = process.env.RESEND_REPLY_TO_EMAIL?.trim();
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      authorization: `Bearer ${apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [input.to],
      subject: "You’re invited to Task Admin",
      html: invitationHtml(input),
      text: invitationText(input),
      ...(replyTo ? { reply_to: replyTo } : {}),
    }),
  });
  const data = (await response.json().catch(() => ({}))) as {
    id?: string;
    message?: string;
    error?: string;
  };
  if (!response.ok) {
    throw new Error(
      data.message ||
        data.error ||
        `Resend rejected the invitation email with HTTP ${response.status}`,
    );
  }
  return {
    provider: "resend",
    messageId: data.id ?? "resend-message",
    sentAt: new Date().toISOString(),
  };
}

type PasswordResetEmailInput = {
  to: string;
  resetLink: string;
  dashboardUrl: string;
};

function passwordResetHtml(input: PasswordResetEmailInput) {
  return `
  <div style="margin:0;background:#08080a;padding:32px;font-family:Inter,Arial,sans-serif;color:#f4f4f5">
    <div style="max-width:620px;margin:0 auto;border:1px solid rgba(255,255,255,.10);border-radius:24px;background:#111114;overflow:hidden">
      <div style="padding:28px 28px 18px;border-bottom:1px solid rgba(255,255,255,.08)">
        <div style="font-size:12px;letter-spacing:.16em;text-transform:uppercase;color:#8b5cf6;font-weight:700">Task Admin Dashboard</div>
        <h1 style="margin:14px 0 0;font-size:26px;line-height:1.2;color:#fff">Reset your password</h1>
        <p style="margin:10px 0 0;color:#a1a1aa;font-size:14px;line-height:1.7">We received a request to reset the password for your Task Admin account.</p>
      </div>
      <div style="padding:28px">
        <p style="margin:0 0 18px;color:#d4d4d8;font-size:14px;line-height:1.7">Use the secure password reset link below. If you did not request this, you can ignore this email.</p>
        <a href="${input.resetLink}" style="display:inline-block;background:#6366f1;color:#fff;text-decoration:none;font-weight:700;border-radius:14px;padding:14px 20px;font-size:14px">Reset password</a>
        <div style="margin-top:24px;padding:16px;border-radius:16px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08)">
          <div style="font-size:12px;color:#71717a">Dashboard URL</div>
          <a href="${input.dashboardUrl}" style="display:block;margin-top:6px;color:#c4b5fd;text-decoration:none;font-size:14px">${input.dashboardUrl}</a>
        </div>
        <p style="margin:22px 0 0;color:#71717a;font-size:12px;line-height:1.6">If the button does not work, copy and paste this secure reset link into your browser:</p>
        <p style="word-break:break-all;color:#a1a1aa;font-size:12px;line-height:1.6">${input.resetLink}</p>
      </div>
    </div>
  </div>`;
}

function passwordResetText(input: PasswordResetEmailInput) {
  return [
    "Reset your Task Admin password",
    "",
    "Use this secure password reset link:",
    input.resetLink,
    "",
    `Dashboard: ${input.dashboardUrl}`,
    "",
    "If you did not request this, ignore this email.",
  ].join("\n");
}

export async function sendPasswordResetEmail(input: PasswordResetEmailInput) {
  const apiKey = await resendApiKey();
  const from = resendFrom();
  const replyTo = process.env.RESEND_REPLY_TO_EMAIL?.trim();
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      authorization: `Bearer ${apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [input.to],
      subject: "Reset your Task Admin password",
      html: passwordResetHtml(input),
      text: passwordResetText(input),
      ...(replyTo ? { reply_to: replyTo } : {}),
    }),
  });
  const data = (await response.json().catch(() => ({}))) as {
    id?: string;
    message?: string;
    error?: string;
  };
  if (!response.ok) {
    throw new Error(
      data.message ||
        data.error ||
        `Resend rejected the password reset email with HTTP ${response.status}`,
    );
  }
  return {
    provider: "resend" as const,
    messageId: data.id ?? "resend-message",
    sentAt: new Date().toISOString(),
  };
}

export function dashboardUrl() {
  return (
    process.env.ADMIN_DASHBOARD_URL?.trim() ||
    process.env.NEXT_PUBLIC_ADMIN_DASHBOARD_URL?.trim() ||
    "https://task-admin-eg.web.app"
  ).replace(/\/$/, "");
}
