"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/components/auth-provider";
import { readRealJobChat, readRealUserNotifications } from "@/lib/firebase/repository";
import type { RealChatMessage, RealChatThread, RealNotification } from "@/lib/firebase/real-schema-types";
import type { Complaint } from "@/lib/types";

/**
 * Read-only drill-down for one complaint: the real chat thread between the
 * customer and technician on the linked job, plus the customer's real
 * notification feed. Uses the Phase D read-only helpers
 * (readRealJobChat/readRealUserNotifications) added for exactly this purpose
 * - no writes happen from this component.
 */
export function ComplaintRealDataDialog({
  complaint,
  onClose,
}: {
  complaint: Complaint | null;
  onClose: () => void;
}) {
  const { user } = useAuth();
  const [thread, setThread] = useState<RealChatThread | null>(null);
  const [messages, setMessages] = useState<RealChatMessage[]>([]);
  const [notifications, setNotifications] = useState<RealNotification[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!complaint || !user) return;
    let cancelled = false;
    setLoading(true);
    void (async () => {
      const [chat, feed] = await Promise.all([
        complaint.jobId && complaint.providerId
          ? readRealJobChat(complaint.jobId, complaint.providerId, user)
          : Promise.resolve({ thread: null, messages: [] }),
        complaint.customerId ? readRealUserNotifications(complaint.customerId, user) : Promise.resolve([]),
      ]);
      if (cancelled) return;
      setThread(chat.thread);
      setMessages(chat.messages);
      setNotifications(feed);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [complaint, user]);

  if (!complaint) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="max-h-[85vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-zinc-950 p-5 text-zinc-200 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-sm font-semibold">Real data for {complaint.id}</h2>
          <button onClick={onClose} className="text-xs text-zinc-500 hover:text-zinc-300">
            Close
          </button>
        </div>
        {loading && <p className="text-xs text-zinc-500">Loading real job chat and notifications…</p>}
        {!loading && !complaint.jobId && (
          <p className="text-xs text-amber-500">This complaint has no linked job id - chat cannot be loaded.</p>
        )}
        <section className="mb-5">
          <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-500">
            Job chat {thread ? `with ${thread.technicianName || thread.technicianId}` : ""}
          </h3>
          {!loading && messages.length === 0 && (
            <p className="text-xs text-zinc-600">No messages found for this job/technician pair.</p>
          )}
          <ul className="space-y-1">
            {messages.map((message) => (
              <li key={message.id} className="rounded bg-white/[.03] p-2 text-xs">
                <span className="font-medium text-zinc-400">{message.senderRole}:</span>{" "}
                <span>{message.text}</span>
              </li>
            ))}
          </ul>
        </section>
        <section>
          <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-500">
            Customer&apos;s real notifications
          </h3>
          {!loading && notifications.length === 0 && (
            <p className="text-xs text-zinc-600">No notifications found for this customer.</p>
          )}
          <ul className="space-y-1">
            {notifications.map((notification) => (
              <li key={notification.id} className="rounded bg-white/[.03] p-2 text-xs">
                <span className="font-medium">{notification.title}</span>
                <span className="ml-2 text-zinc-500">{notification.body}</span>
                {!notification.read && <span className="ml-2 text-amber-500">unread</span>}
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}
