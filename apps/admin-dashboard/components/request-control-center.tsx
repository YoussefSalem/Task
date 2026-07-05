"use client";

import { useMemo, useState, type ReactNode } from "react";
import {
  Download,
  Flag,
  Image as ImageIcon,
  MessageSquare,
  Phone,
  Play,
  Search,
  Video,
  WalletCards,
  X,
} from "lucide-react";
import type {
  ChatMessage,
  Customer,
  Job,
  Provider,
  RequestMedia,
  VoipCall,
} from "@/lib/types";
import { useAdminData } from "@/components/admin-data-provider";
import { FormDialog } from "@/components/functional-dialogs";
import { SearchableSelect } from "@/components/searchable-select";
import { cn } from "@/lib/utils";

const tabs = [
  "Overview",
  "Media",
  "Provider offers",
  "Communication",
  "Timeline",
  "Payment",
  "Cancellation",
];

export function RequestControlCenter({
  job,
  close,
  notify,
}: {
  job: Job;
  close: () => void;
  notify: (message: string) => void;
}) {
  const { db, actions } = useAdminData();
  const current = db.jobs.find((item) => item.id === job.id) ?? job;
  const customer = db.customers.find((item) => item.id === current.customerId);
  const assigned = db.providers.find((item) => item.id === current.providerId);
  const [tab, setTab] = useState("Overview");
  const [preview, setPreview] = useState<RequestMedia | null>(null);
  const [chatSearch, setChatSearch] = useState("");
  const [sender, setSender] = useState("All");
  const [flagMessage, setFlagMessage] = useState<ChatMessage | null>(null);
  const [reviewCall, setReviewCall] = useState<VoipCall | null>(null);
  const [supportNote, setSupportNote] = useState(false);
  const messages = useMemo(
    () =>
      (current.messages ?? []).filter(
        (message) =>
          (sender === "All" || message.senderType === sender.toLowerCase()) &&
          `${message.id} ${message.senderName} ${message.text}`
            .toLowerCase()
            .includes(chatSearch.toLowerCase()),
      ),
    [chatSearch, current.messages, sender],
  );
  const download = (url: string, fileName: string) => {
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    notify(`${fileName} download started`);
  };
  const exportTranscript = () => {
    const content = (current.messages ?? [])
      .map(
        (m) =>
          `[${new Date(m.sentAt).toLocaleString()}] ${m.senderType.toUpperCase()} ${m.senderName} (${m.senderId}): ${m.deleted ? "[deleted]" : m.text}`,
      )
      .join("\n");
    download(
      `data:text/plain;charset=utf-8,${encodeURIComponent(content)}`,
      `${current.id}-chat-transcript.txt`,
    );
  };
  return (
    <div
      className="fixed inset-0 z-[100] overflow-y-auto bg-black/75 backdrop-blur-md"
      onMouseDown={close}
    >
      <div
        className="ml-auto min-h-full w-full max-w-6xl border-l border-white/[.08] bg-[#101013] shadow-2xl"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 z-20 border-b border-white/[.08] bg-[#101013]/95 px-5 py-4 backdrop-blur-xl">
          <div className="flex items-start gap-4">
            <div className="flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="text-base font-semibold">{current.id}</h2>
                <Status value={current.status} />
                <span className="rounded-md bg-white/[.05] px-2 py-1 text-[9px] text-zinc-500">
                  Customer {current.customerId}
                </span>
                {assigned && (
                  <span className="rounded-md bg-indigo-500/10 px-2 py-1 font-mono text-[9px] text-indigo-300">
                    {assigned.providerId}
                  </span>
                )}
              </div>
              <p className="mt-1 text-[11px] text-zinc-500">
                {current.category} · {current.service} · created{" "}
                {new Date(current.createdAt).toLocaleString()}
              </p>
            </div>
            <button onClick={close} className="icon-btn">
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="mt-4 flex gap-2 overflow-x-auto">
            {tabs.map((item) => (
              <button
                key={item}
                onClick={() => setTab(item)}
                className={cn(
                  "whitespace-nowrap rounded-lg px-3 py-2 text-[10px]",
                  tab === item
                    ? "bg-indigo-500 text-white"
                    : "bg-white/[.035] text-zinc-500 hover:text-white",
                )}
              >
                {item}
                {item === "Communication" &&
                  ` (${(current.messages?.length ?? 0) + (current.calls?.length ?? 0)})`}
                {item === "Provider offers" &&
                  ` (${current.offers?.length ?? 0})`}
              </button>
            ))}
          </div>
        </div>
        <div className="p-5">
          {tab === "Overview" && (
            <Overview job={current} customer={customer} assigned={assigned} />
          )}
          {tab === "Media" && (
            <MediaGrid
              media={current.media ?? []}
              preview={setPreview}
              download={download}
            />
          )}
          {tab === "Provider offers" && <Offers job={current} />}
          {tab === "Communication" && (
            <div className="space-y-6">
              <div className="flex flex-wrap gap-2">
                <div className="flex flex-1 items-center gap-2 rounded-xl border border-white/[.08] px-3">
                  <Search className="h-3.5 w-3.5 text-zinc-600" />
                  <input
                    value={chatSearch}
                    onChange={(e) => setChatSearch(e.target.value)}
                    placeholder="Search message ID, sender or text…"
                    className="h-10 flex-1 bg-transparent text-xs outline-none"
                  />
                </div>
                <SearchableSelect
                  value={sender}
                  onChange={setSender}
                  allowEmpty={false}
                  options={["All", "Customer", "Provider", "Admin", "System"].map(
                    (value) => ({ label: value === "All" ? "All senders" : value, value }),
                  )}
                />
                <button onClick={exportTranscript} className="btn-secondary">
                  <Download className="h-3.5 w-3.5" /> Export transcript
                </button>
                <button
                  onClick={() => setSupportNote(true)}
                  className="btn-primary"
                >
                  Internal support note
                </button>
              </div>
              <Chat messages={messages} flag={setFlagMessage} />
              <Calls
                calls={current.calls ?? []}
                review={setReviewCall}
                download={download}
              />
            </div>
          )}
          {tab === "Timeline" && <Timeline job={current} />}
          {tab === "Payment" && <Payment job={current} />}
          {tab === "Cancellation" && (
            <Cancellation job={current} notify={notify} />
          )}
        </div>
      </div>
      {preview && (
        <div
          className="fixed inset-0 z-[130] grid place-items-center bg-black/85 p-6"
          onMouseDown={() => setPreview(null)}
        >
          <div
            className="w-full max-w-4xl rounded-2xl border border-white/[.1] bg-[#151518] p-4"
            onMouseDown={(e) => e.stopPropagation()}
          >
            <div className="mb-3 flex items-center justify-between">
              <div>
                <b className="text-xs">{preview.fileName}</b>
                <p className="text-[9px] text-zinc-500">
                  {preview.mimeType} · {(preview.size / 1024 / 1024).toFixed(2)}{" "}
                  MB · {new Date(preview.uploadedAt).toLocaleString()}
                </p>
              </div>
              <button className="icon-btn" onClick={() => setPreview(null)}>
                <X className="h-4 w-4" />
              </button>
            </div>
            {preview.type === "photo" ? (
              <div
                className="aspect-video rounded-xl bg-contain bg-center bg-no-repeat"
                style={{ backgroundImage: `url(${preview.url})` }}
              />
            ) : (
              <video
                controls
                className="aspect-video w-full rounded-xl bg-black"
                src={preview.url}
              />
            )}
          </div>
        </div>
      )}
      <FormDialog
        open={!!flagMessage}
        onClose={() => setFlagMessage(null)}
        title={`Flag message · ${flagMessage?.id ?? ""}`}
        fields={[
          {
            name: "note",
            label: "Safety review reason",
            type: "textarea",
            required: true,
          },
        ]}
        submitLabel="Flag for review"
        onSubmit={(v) => {
          if (flagMessage) {
            actions.flagMessage(current.id, flagMessage.id, v.note);
            notify("Message flagged and added to the audit log");
          }
        }}
      />
      <FormDialog
        open={!!reviewCall}
        onClose={() => setReviewCall(null)}
        title={`Review call · ${reviewCall?.id ?? ""}`}
        fields={[
          {
            name: "note",
            label: "Review note",
            type: "textarea",
            required: true,
          },
          {
            name: "outcome",
            label: "Outcome",
            type: "select",
            required: true,
            options: [
              { label: "Reviewed", value: "reviewed" },
              { label: "Flag for safety", value: "flagged" },
              { label: "Link new complaint", value: "complaint" },
            ],
          },
        ]}
        submitLabel="Save review"
        onSubmit={async (v) => {
          if (!reviewCall) return;
          if (v.outcome === "complaint") {
            const created = await actions.createComplaint({
              title: `VoIP call review · ${reviewCall.id}`,
              description: v.note,
              severity: "High",
              jobId: current.id,
              customerId: current.customerId,
              providerId: current.providerId,
              customer: current.customer,
            });
            await actions.reviewCall(current.id, reviewCall.id, {
              reviewed: true,
              flagged: true,
              reviewNote: v.note,
              complaintId: created.id,
            });
          } else
            await actions.reviewCall(current.id, reviewCall.id, {
              reviewed: true,
              flagged: v.outcome === "flagged",
              reviewNote: v.note,
            });
          notify("Call review saved");
        }}
      />
      <FormDialog
        open={supportNote}
        onClose={() => setSupportNote(false)}
        title={`Internal support note · ${current.id}`}
        fields={[
          { name: "note", label: "Note", type: "textarea", required: true },
        ]}
        onSubmit={(v) => {
          actions.addJobNote(current.id, v.note);
          notify("Internal support note saved");
        }}
      />
    </div>
  );
}

function Overview({
  job,
  customer,
  assigned,
}: {
  job: Job;
  customer: Customer | undefined;
  assigned: Provider | undefined;
}) {
  const accepted = job.offers?.find((o) => o.id === job.acceptedOfferId);
  return (
    <div className="space-y-5">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          ["Customer", `${job.customer} · ${customer?.phone ?? "—"}`],
          ["Customer email", customer?.email ?? "—"],
          ["Service", `${job.category} / ${job.service}`],
          [
            "Budget",
            `EGP ${(job.customerBudget ?? job.amount).toLocaleString()}`,
          ],
          ["Address", job.address ?? "—"],
          [
            "GPS",
            job.gps
              ? `${job.gps.lat.toFixed(5)}, ${job.gps.lng.toFixed(5)}`
              : "—",
          ],
          ["Area / city", `${job.area} / ${job.city ?? "—"}`],
          ["Scheduled", job.scheduled],
          ["Urgency", job.priority ?? "Normal"],
          [
            "Assigned provider",
            assigned
              ? `${assigned.name} · ${assigned.providerId}`
              : "Unassigned",
          ],
          [
            "Accepted offer",
            accepted ? `${accepted.id} · EGP ${accepted.price}` : "None",
          ],
          ["Payment", `${job.paymentMethod} · ${job.paymentStatus}`],
        ].map(([a, b]) => (
          <Info key={a} label={a} value={b} />
        ))}
      </div>
      <div className="rounded-2xl border border-white/[.07] bg-white/[.02] p-4">
        <div className="eyebrow">Customer problem description</div>
        <p className="mt-3 text-sm leading-6 text-zinc-300">
          {job.problemDescription ?? "No description supplied."}
        </p>
      </div>
    </div>
  );
}
function MediaGrid({
  media,
  preview,
  download,
}: {
  media: RequestMedia[];
  preview: (m: RequestMedia) => void;
  download: (url: string, name: string) => void;
}) {
  return media.length ? (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {media.map((m) => (
        <div
          key={m.id}
          className="overflow-hidden rounded-2xl border border-white/[.08] bg-white/[.02]"
        >
          <div
            className="aspect-video bg-cover bg-center"
            style={{ backgroundImage: `url(${m.thumbnail ?? m.url})` }}
          />
          <div className="p-4">
            <div className="flex items-center gap-2">
              {m.type === "video" ? (
                <Video className="h-4 w-4 text-cyan-400" />
              ) : (
                <ImageIcon className="h-4 w-4 text-indigo-400" />
              )}
              <b className="truncate text-xs">{m.fileName}</b>
            </div>
            <p className="mt-2 text-[9px] text-zinc-600">
              {m.id} · {(m.size / 1024 / 1024).toFixed(2)} MB ·{" "}
              {new Date(m.uploadedAt).toLocaleString()}
            </p>
            <p className="mt-1 text-[9px] text-zinc-600">
              Uploaded by {m.uploadedByType}: {m.uploadedByName} · linked{" "}
              {m.jobId}
            </p>
            <div className="mt-3 flex gap-2">
              <button
                onClick={() => preview(m)}
                className="btn-secondary flex-1 justify-center"
              >
                <Play className="h-3 w-3" />
                Preview
              </button>
              <button
                onClick={() => download(m.url, m.fileName)}
                className="btn-secondary"
              >
                <Download className="h-3 w-3" />
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  ) : (
    <Empty text="No request media uploaded" />
  );
}
function Offers({ job }: { job: Job }) {
  const { db } = useAdminData();
  return (
    <div className="space-y-5">
      <div className="grid gap-3 sm:grid-cols-3">
        <Info label="Providers received" value={job.providersReceived ?? 0} />
        <Info label="Providers opened" value={job.providersOpened ?? 0} />
        <Info label="Offers submitted" value={job.offers?.length ?? 0} />
      </div>
      <div className="space-y-3">
        {(job.offers ?? []).map((offer) => {
          const provider = db.providers.find((p) => p.id === offer.providerId);
          return (
            <div
              key={offer.id}
              className={cn(
                "rounded-2xl border p-4",
                offer.status === "Accepted"
                  ? "border-emerald-500/30 bg-emerald-500/[.05]"
                  : "border-white/[.07] bg-white/[.02]",
              )}
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <b className="text-xs">{offer.id}</b>
                    <Status value={offer.status} />
                    {provider && (
                      <span className="font-mono text-[9px] text-indigo-300">
                        {provider.providerId}
                      </span>
                    )}
                  </div>
                  <p className="mt-2 text-xs">
                    {provider?.name} · {provider?.phone} · {provider?.rating}★
                  </p>
                  <p className="mt-2 text-[11px] text-zinc-500">
                    “{offer.message}”
                  </p>
                </div>
                <div className="text-right">
                  <div className="text-lg font-semibold">
                    EGP {offer.price.toLocaleString()}
                  </div>
                  <div className="text-[9px] text-zinc-500">
                    {offer.distanceKm ?? "—"} km · arrival{" "}
                    {offer.arrivalMinutes}m · completion{" "}
                    {offer.completionMinutes}m
                  </div>
                </div>
              </div>
              <div className="mt-3 text-[9px] text-zinc-600">
                Created {new Date(offer.createdAt).toLocaleString()} · decision{" "}
                {offer.decidedAt
                  ? new Date(offer.decidedAt).toLocaleString()
                  : "pending"}
              </div>
            </div>
          );
        })}
      </div>
      <div className="rounded-xl border border-dashed border-white/[.08] p-4 text-[10px] text-zinc-500">
        Ignored / unopened providers:{" "}
        {Math.max(0, (job.providersReceived ?? 0) - (job.providersOpened ?? 0))}{" "}
        · Opened without offer:{" "}
        {Math.max(0, (job.providersOpened ?? 0) - (job.offers?.length ?? 0))}
      </div>
    </div>
  );
}
function Chat({
  messages,
  flag,
}: {
  messages: ChatMessage[];
  flag: (m: ChatMessage) => void;
}) {
  return (
    <section>
      <div className="mb-3 flex items-center gap-2">
        <MessageSquare className="h-4 w-4 text-indigo-400" />
        <h3 className="text-xs font-semibold">Chat history</h3>
      </div>
      <div className="space-y-2">
        {messages.map((m) => (
          <div
            key={m.id}
            className={cn(
              "rounded-2xl border p-4",
              m.flagged
                ? "border-red-500/30 bg-red-500/[.04]"
                : "border-white/[.07] bg-white/[.02]",
            )}
          >
            <div className="flex items-center gap-2">
              <b className="text-xs">{m.senderName}</b>
              <span className="rounded bg-white/[.05] px-2 py-0.5 text-[9px] text-zinc-500">
                {m.senderType} · {m.senderId}
              </span>
              <span className="ml-auto text-[9px] text-zinc-600">
                {new Date(m.sentAt).toLocaleString()}
              </span>
            </div>
            <p
              className={cn(
                "mt-3 text-xs leading-5",
                m.deleted && "italic text-zinc-600",
              )}
            >
              {m.deleted ? "Message deleted" : m.text}
            </p>
            <div className="mt-3 flex items-center gap-2 text-[9px] text-zinc-600">
              <span>{m.id}</span>
              <span>{m.delivered ? "Delivered" : "Sending"}</span>
              <span>{m.read ? "Read" : "Unread"}</span>
              {m.edited && <span>Edited</span>}
              {m.flagged ? (
                <span className="text-red-400">Flagged</span>
              ) : (
                <button
                  onClick={() => flag(m)}
                  className="ml-auto text-amber-400"
                >
                  <Flag className="mr-1 inline h-3 w-3" />
                  Flag
                </button>
              )}
            </div>
          </div>
        ))}
        {!messages.length && <Empty text="No messages match this search" />}
      </div>
    </section>
  );
}
function Calls({
  calls,
  review,
  download,
}: {
  calls: VoipCall[];
  review: (c: VoipCall) => void;
  download: (url: string, name: string) => void;
}) {
  return (
    <section>
      <div className="mb-3 flex items-center gap-2">
        <Phone className="h-4 w-4 text-emerald-400" />
        <h3 className="text-xs font-semibold">VoIP call history</h3>
        <span className="text-[9px] text-zinc-600">
          Provider-neutral adapter · Twilio, Agora, Vonage, WebRTC and Daily.co
          ready
        </span>
      </div>
      <div className="space-y-2">
        {calls.map((call) => (
          <div
            key={call.id}
            className="rounded-2xl border border-white/[.07] p-4"
          >
            <div className="flex flex-wrap items-center gap-2">
              <b className="text-xs">{call.id}</b>
              <Status value={call.status} />
              <span className="text-[10px] text-zinc-500">
                {call.caller} → {call.receiver}
              </span>
              <span className="ml-auto text-[10px]">
                {Math.floor(call.durationSeconds / 60)}:
                {String(call.durationSeconds % 60).padStart(2, "0")}
              </span>
            </div>
            <p className="mt-2 text-[9px] text-zinc-600">
              {call.direction} · started{" "}
              {new Date(call.startTime).toLocaleString()} ·{" "}
              {call.recordingStatus} · {call.integration}
            </p>
            <div className="mt-3 flex flex-wrap gap-2">
              {call.recordingStatus === "Available" && call.recordingUrl ? (
                <>
                  <button
                    onClick={() =>
                      new Audio(call.recordingUrl).play().catch(() => {})
                    }
                    className="btn-secondary"
                  >
                    <Play className="h-3 w-3" />
                    Play recording
                  </button>
                  <button
                    onClick={() =>
                      download(call.recordingUrl!, `${call.id}.wav`)
                    }
                    className="btn-secondary"
                  >
                    <Download className="h-3 w-3" />
                    Download
                  </button>
                </>
              ) : call.recordingStatus === "Available" ? (
                <span className="rounded-lg bg-amber-500/10 px-3 py-2 text-[10px] text-amber-400">
                  Recording file unavailable
                </span>
              ) : null}
              <button onClick={() => review(call)} className="btn-secondary">
                {call.reviewed ? "Update review" : "Review call"}
              </button>
              {call.flagged && (
                <span className="rounded-lg bg-red-500/10 px-3 py-2 text-[10px] text-red-400">
                  Safety flagged
                </span>
              )}
            </div>
          </div>
        ))}
        {!calls.length && <Empty text="No VoIP calls recorded" />}
      </div>
    </section>
  );
}
function Timeline({ job }: { job: Job }) {
  const comm: Job["timeline"] = [
    ...(job.messages ?? []).map((m) => ({
      id: m.id,
      label: `${m.senderName} sent a message`,
      at: m.sentAt,
      actor: m.senderName,
      actorType: m.senderType,
      actorId: m.senderId,
      metadata: { messageId: m.id },
    })),
    ...(job.calls ?? []).map((c) => ({
      id: c.id,
      label: `Call ${c.status.toLowerCase()}`,
      at: c.startTime,
      actor: c.caller,
      actorType: "customer" as const,
      actorId: c.customerId,
      metadata: { callId: c.id, duration: c.durationSeconds },
    })),
  ];
  const events = [...job.timeline, ...comm].sort(
    (a, b) => new Date(b.at).getTime() - new Date(a.at).getTime(),
  );
  return (
    <div className="space-y-2">
      {events.map((event) => (
        <div
          key={event.id}
          className="relative ml-2 border-l border-indigo-500/30 py-3 pl-6"
        >
          <span className="absolute -left-1 top-5 h-2 w-2 rounded-full bg-indigo-400" />
          <div className="flex flex-wrap items-center gap-2">
            <b className="text-xs">{event.label}</b>
            <span className="rounded bg-white/[.05] px-2 py-0.5 text-[9px] text-zinc-500">
              {event.actorType ?? "system"}
            </span>
          </div>
          <p className="mt-1 text-[9px] text-zinc-600">
            {new Date(event.at).toLocaleString()} · {event.actor}{" "}
            {event.actorId ? `(${event.actorId})` : ""}
          </p>
          {event.metadata && (
            <pre className="mt-2 overflow-x-auto text-[9px] text-zinc-600">
              {JSON.stringify(event.metadata, null, 2)}
            </pre>
          )}
        </div>
      ))}
    </div>
  );
}
function Payment({ job }: { job: Job }) {
  const p = job.payment;
  if (!p) return <Empty text="No payment record linked" />;
  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3 rounded-2xl border border-white/[.08] bg-white/[.025] p-5">
        <WalletCards className="h-6 w-6 text-indigo-400" />
        <div>
          <div className="text-lg font-semibold">
            EGP {p.amount.toLocaleString()}
          </div>
          <div className="text-[10px] text-zinc-500">
            {p.method} · {p.status}
          </div>
        </div>
        <Status value={p.status} />
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          ["Service price", p.servicePrice],
          ["Customer budget", p.customerOfferPrice],
          ["Accepted offer", p.acceptedOfferPrice ?? 0],
          ["Platform commission", p.platformCommission],
          ["Provider earnings", p.providerEarnings],
          ["Discount", p.discount],
          ["Wallet used", p.walletAmount],
          ["Card paid", p.cardAmount],
          ["Instapay paid", p.instapayAmount],
          ["Refund", p.refundAmount],
          ["Outstanding", p.outstandingAmount],
          ["Promo code", p.promoCode ?? "None"],
          ["Transaction ID", p.transactionId ?? "Pending"],
          ["Provider reference", p.providerReference ?? "—"],
          [
            "Payment time",
            p.paidAt ? new Date(p.paidAt).toLocaleString() : "Not paid",
          ],
        ].map(([a, b]) => (
          <Info
            key={String(a)}
            label={String(a)}
            value={typeof b === "number" ? `EGP ${b.toLocaleString()}` : b}
          />
        ))}
      </div>
    </div>
  );
}
function Cancellation({
  job,
  notify,
}: {
  job: Job;
  notify: (m: string) => void;
}) {
  const { db, actions } = useAdminData();
  const c = job.cancellation;
  const customer = db.customers.find((item) => item.id === job.customerId);
  const [note, setNote] = useState("");
  if (!c) return <Empty text="This request has not been cancelled" />;
  const update = async (patch: Partial<typeof c>, message: string) => {
    await actions.updateCancellation(job.id, patch);
    notify(message);
  };
  const phone = (customer?.phone ?? "").replace(/[^\d+]/g, "");
  return (
    <div className="space-y-5">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          ["Cancelled by", c.cancelledBy],
          ["Cancellation time", new Date(c.cancelledAt).toLocaleString()],
          ["Stage", c.stage],
          ["Reason", c.reason],
          ["Refund", c.refundStatus],
          ["Follow-up", c.followUpStatus],
          [
            "Support owner",
            db.admins.find((a) => a.id === c.supportOwnerId)?.name ??
              "Unassigned",
          ],
        ].map(([a, b]) => (
          <Info key={a} label={a} value={b} />
        ))}
      </div>
      <div className="flex flex-wrap gap-2">
        <a
          href={phone ? `tel:${phone}` : undefined}
          onClick={(event) => {
            if (!phone) {
              event.preventDefault();
              notify("No customer phone is stored for this request");
            }
          }}
          className="btn-secondary"
        >
          <Phone className="h-3 w-3" />
          Call customer
        </a>
        <a
          href={phone ? `https://wa.me/${phone.replace(/^\+/, "")}` : undefined}
          onClick={(event) => {
            if (!phone) {
              event.preventDefault();
              notify("No customer phone is stored for this request");
            }
          }}
          target="_blank"
          rel="noreferrer"
          className="btn-secondary"
        >
          WhatsApp customer
        </a>
        <button
          onClick={() =>
            update({ followUpStatus: "Contacted" }, "Marked as contacted")
          }
          className="btn-secondary"
        >
          Mark contacted
        </button>
        <button
          onClick={async () => {
            await actions.changeJobStatus(job.id, "Scheduled");
            await update(
              { followUpStatus: "Recovered" },
              "Request reopened and recovered",
            );
          }}
          className="btn-primary"
        >
          Reopen request
        </button>
        <button
          onClick={async () => {
            await actions.createPromo({
              code: `SORRY${job.id.slice(-4)}`,
              description: `Recovery offer for ${job.id}`,
              discountType: "fixed",
              discount: 100,
              maxUses: 1,
              endsAt: new Date(Date.now() + 30 * 86400000).toISOString(),
              enabled: true,
            });
            notify("Apology promo created");
          }}
          className="btn-secondary"
        >
          Send apology promo
        </button>
      </div>
      <div className="flex gap-2">
        <input
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="Add follow-up note…"
          className="input flex-1"
        />
        <button
          disabled={!note.trim()}
          onClick={async () => {
            await update(
              { followUpNotes: [note.trim(), ...c.followUpNotes] },
              "Follow-up note saved",
            );
            setNote("");
          }}
          className="btn-primary"
        >
          Save note
        </button>
      </div>
      {c.followUpNotes.map((n, i) => (
        <div
          key={i}
          className="rounded-xl border border-white/[.06] p-3 text-xs"
        >
          {n}
        </div>
      ))}
    </div>
  );
}
function Info({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="rounded-xl border border-white/[.06] bg-white/[.02] p-3">
      <div className="text-[9px] uppercase tracking-wide text-zinc-600">
        {label}
      </div>
      <div className="mt-1 text-xs text-zinc-200">{value}</div>
    </div>
  );
}
function Status({ value }: { value: string }) {
  const good = [
    "Paid",
    "Completed",
    "Accepted",
    "Answered",
    "Approved",
    "Wallet Deducted",
  ].includes(value);
  const bad = [
    "Cancelled",
    "Rejected",
    "Failed",
    "Refunded",
    "Missed",
    "Suspicious",
  ].includes(value);
  return (
    <span
      className={cn(
        "rounded-full px-2 py-1 text-[9px]",
        good
          ? "bg-emerald-500/10 text-emerald-400"
          : bad
            ? "bg-red-500/10 text-red-400"
            : "bg-amber-500/10 text-amber-400",
      )}
    >
      {value}
    </span>
  );
}
function Empty({ text }: { text: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-white/[.1] py-16 text-center text-xs text-zinc-600">
      {text}
    </div>
  );
}
