type LogLevel = "info" | "warn" | "error";

type LogContext = Record<string, unknown>;

function sanitize(value: unknown): unknown {
  if (typeof value === "string") {
    if (value.length > 240) return `${value.slice(0, 237)}...`;
    return value;
  }
  if (Array.isArray(value)) return value.map(sanitize);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, item]) => [
        key,
        /token|secret|key|password|authorization/i.test(key)
          ? "[redacted]"
          : sanitize(item),
      ]),
    );
  }
  return value;
}

export function requestId(request?: Request) {
  return (
    request?.headers.get("x-cloud-trace-context")?.split("/")?.[0] ||
    request?.headers.get("x-request-id") ||
    crypto.randomUUID()
  );
}

export function serverLog(
  level: LogLevel,
  message: string,
  context: LogContext = {},
) {
  const sanitizedContext = sanitize(context) as LogContext;
  const payload = {
    severity: level.toUpperCase(),
    service: "task-admin-dashboard",
    message,
    ...sanitizedContext,
    timestamp: new Date().toISOString(),
  };
  const line = JSON.stringify(payload);
  if (level === "error") console.error(line);
  else if (level === "warn") console.warn(line);
  else console.info(line);
}

export function errorMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  if (error instanceof Response) return error.statusText || `HTTP ${error.status}`;
  return "Unexpected server error";
}
