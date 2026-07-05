"use client";
/* eslint-disable @next/next/no-img-element */

import { useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  CheckCircle2,
  Download,
  Eye,
  FileCheck2,
  FileClock,
  History,
  LockKeyhole,
  RefreshCcw,
  ShieldCheck,
  Trash2,
  Upload,
  X,
} from "lucide-react";
import { useAdminData } from "@/components/admin-data-provider";
import { usePermissions } from "@/components/use-permissions";
import { useAuth } from "@/components/auth-provider";
import type { StoredDocumentFile } from "@/lib/document-storage";
import { uploadFirebaseFile } from "@/lib/firebase/storage";
import {
  effectiveDocumentStatus,
  expiryMessage,
  verificationSummary,
} from "@/lib/provider-verification";
import type {
  Provider,
  ProviderDocument,
  ProviderDocumentStatus,
} from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { ConfirmDialog } from "@/components/functional-dialogs";
import { SearchableSelect } from "@/components/searchable-select";
import { cn } from "@/lib/utils";

export function ProviderVerificationCenter({
  providerId,
  close,
  notify,
}: {
  providerId: string;
  close: () => void;
  notify: (message: string) => void;
}) {
  const { db, actions } = useAdminData();
  const { can } = usePermissions();
  const { user } = useAuth();
  const provider = db.providers.find((item) => item.id === providerId);
  const requirements = useMemo(() => db.verificationRequirements.filter((item) => item.enabled).sort((a,b) => a.sortOrder-b.sortOrder), [db.verificationRequirements]);
  const [type, setType] = useState<string>("");
  const [customLabel, setCustomLabel] = useState("");
  const [expiry, setExpiry] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [reviewing, setReviewing] = useState<{
    document: ProviderDocument;
    status: ProviderDocumentStatus;
  } | null>(null);
  const [reviewNotes, setReviewNotes] = useState("");
  const [preview, setPreview] = useState<ProviderDocument | null>(null);
  const [deleting, setDeleting] = useState<ProviderDocument | null>(null);
  const [note, setNote] = useState("");
  const [documentFilter, setDocumentFilter] = useState("All");
  const summary = provider ? verificationSummary(provider) : null;
  useEffect(()=>{if(!type&&requirements[0])setType(requirements[0].type)},[requirements,type]);
  const filtered = useMemo(
    () =>
      provider?.documents.filter(
        (document) =>
          documentFilter === "All" ||
          effectiveDocumentStatus(document) === documentFilter,
      ) ?? [],
    [documentFilter, provider],
  );
  if (!provider) return null;
  if (!can("providers.approve"))
    return (
      <div className="fixed inset-0 z-[100] grid place-items-center bg-black/75 p-4">
        <div className="panel max-w-md p-8 text-center">
          <LockKeyhole className="mx-auto h-8 w-8 text-red-400" />
          <h2 className="mt-4 font-semibold">Restricted provider documents</h2>
          <p className="mt-2 text-xs text-zinc-500">
            Only Super Admins and Verification Officers can view or download
            identity documents.
          </p>
          <Button className="mt-5" onClick={close}>
            Close
          </Button>
        </div>
      </div>
    );
  const upload = async () => {
    if (!file) return notify("Choose a document to upload");
    if (type === "Custom document" && !customLabel.trim())
      return notify("Custom document name is required");
    setUploading(true);
    try {
      const stored = await uploadDocument(file,provider.id);
      await actions.uploadProviderDocument(provider.id, {
        ...stored,
        type,
        customLabel: customLabel || undefined,
        expiryDate: expiry || undefined,
        uploadedBy: user?.name ?? "Authenticated administrator",
        required: requirements.some((item) => item.type === type && item.required),
      });
      setFile(null);
      setExpiry("");
      setCustomLabel("");
      notify(`${type} uploaded for review`);
    } catch (error) {
      notify(error instanceof Error ? error.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  };
  const replace = async (document: ProviderDocument, replacement?: File) => {
    if (!replacement) return;
    try {
      const stored = await uploadDocument(replacement,provider.id);
      await actions.replaceProviderDocument(provider.id, document.id, {
        ...stored,
        uploadedBy: user?.name ?? "Authenticated administrator",
      });
      notify(`${document.type} replaced; previous version retained`);
    } catch (error) {
      notify(error instanceof Error ? error.message : "Replacement failed");
    }
  };
  const download = (document: ProviderDocument) => {
    actions.recordProviderDocumentAccess(provider.id, document.id, "download");
    const anchor = window.document.createElement("a");
    anchor.href = document.storageUrl;
    anchor.download = document.fileName;
    anchor.click();
    notify(`${document.fileName} downloaded`);
  };
  const stages = [
    "Registration",
    "Documents Uploaded",
    "Pending Review",
    "Documents Approved",
    "Background Check",
    "Contract Signed",
    "Provider Approved",
    "Provider Active",
  ];
  const activeStage = Math.max(0, stages.indexOf(provider.verification.stage));
  return (
    <div className="fixed inset-0 z-[100] overflow-y-auto bg-black/75 p-3 backdrop-blur-sm">
      <div className="mx-auto my-4 max-w-7xl overflow-hidden rounded-3xl border border-white/[.1] bg-[#101013] shadow-2xl">
        <header className="sticky top-0 z-20 flex items-center gap-4 border-b border-white/[.07] bg-[#101013]/95 p-5 backdrop-blur">
          <span className="grid h-11 w-11 place-items-center rounded-2xl bg-indigo-500/10 text-sm font-semibold text-indigo-400">
            {provider.initials}
          </span>
          <div className="min-w-0 flex-1">
            <h2 className="font-semibold">
              Documents & Verification · {provider.name}
            </h2>
            <p className="mt-1 text-[10px] text-zinc-500">
              {provider.providerId} · {provider.trade} · Officer:{" "}
              {provider.verification.officerName ?? "Unassigned"}
            </p>
          </div>
          <VerificationBadge provider={provider} />
          <Button variant="ghost" size="icon" onClick={close}>
            <X />
          </Button>
        </header>
        <div className="grid gap-5 p-5 xl:grid-cols-[1fr_330px]">
          <div className="space-y-5">
            <section className="panel p-4">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h3 className="text-xs font-semibold">
                    Verification workflow
                  </h3>
                  <p className="mt-1 text-[10px] text-zinc-600">
                    {summary?.percentage}% mandatory documents approved
                  </p>
                </div>
                <div className="text-2xl font-semibold">
                  {summary?.percentage}%
                </div>
              </div>
              <div className="grid gap-2 sm:grid-cols-4 lg:grid-cols-8">
                {stages.map((stage, index) => (
                  <div
                    key={stage}
                    className={cn(
                      "rounded-xl border p-2 text-center text-[9px]",
                      index <= activeStage
                        ? "border-emerald-500/20 bg-emerald-500/10 text-emerald-400"
                        : "border-white/[.06] text-zinc-600",
                    )}
                  >
                    <span className="mx-auto mb-2 grid h-5 w-5 place-items-center rounded-full bg-black/20">
                      {index <= activeStage ? (
                        <CheckCircle2 className="h-3 w-3" />
                      ) : (
                        index + 1
                      )}
                    </span>
                    {stage}
                  </div>
                ))}
              </div>
            </section>
            {(summary!.missing.length > 0 ||
              summary!.expired.length > 0 ||
              provider.documents.some((document) =>
                expiryMessage(document),
              )) && (
              <section className="rounded-2xl border border-amber-500/20 bg-amber-500/[.06] p-4">
                <h3 className="flex items-center gap-2 text-xs font-semibold text-amber-300">
                  <AlertTriangle className="h-4 w-4" />
                  Expiration & missing-document alerts
                </h3>
                <div className="mt-3 grid gap-2 sm:grid-cols-2">
                  {summary!.missing.map((item) => (
                    <span
                      key={item}
                      className="rounded-lg bg-black/20 p-2 text-[10px]"
                    >
                      Missing required document: {item}
                    </span>
                  ))}
                  {provider.documents
                    .map((document) => expiryMessage(document))
                    .filter(Boolean)
                    .map((message) => (
                      <span
                        key={message}
                        className="rounded-lg bg-black/20 p-2 text-[10px]"
                      >
                        {message}
                      </span>
                    ))}
                </div>
              </section>
            )}
            <section className="panel overflow-hidden">
              <div className="flex flex-wrap items-center gap-2 border-b border-white/[.06] p-4">
                <div className="mr-auto">
                  <h3 className="text-xs font-semibold">Provider documents</h3>
                  <p className="mt-1 text-[10px] text-zinc-600">
                    Metadata, review state, expiry, and immutable version
                    history
                  </p>
                </div>
                <SearchableSelect
                  value={documentFilter}
                  onChange={setDocumentFilter}
                  allowEmpty={false}
                  options={[
                    "All",
                    "Pending",
                    "Under Review",
                    "Approved",
                    "Rejected",
                    "Expired",
                  ].map((value) => ({ label: value, value }))}
                />
              </div>
              <div className="divide-y divide-white/[.06]">
                {filtered.map((document) => (
                  <DocumentRow
                    key={document.id}
                    document={document}
                    onPreview={() => {
                      actions.recordProviderDocumentAccess(
                        provider.id,
                        document.id,
                        "preview",
                      );
                      setPreview(document);
                    }}
                    onDownload={() => download(document)}
                    onReview={(status) => {
                      setReviewNotes("");
                      setReviewing({ document, status });
                    }}
                    onDelete={() => setDeleting(document)}
                    onReplace={(replacement) => replace(document, replacement)}
                  />
                ))}
                {!filtered.length && (
                  <div className="p-10 text-center text-xs text-zinc-600">
                    No documents match this filter.
                  </div>
                )}
              </div>
            </section>
            <section className="panel p-4">
              <h3 className="text-xs font-semibold">Upload document</h3>
              <div className="mt-4 grid gap-3 md:grid-cols-2">
                <label className="text-[10px] text-zinc-500">
                  Document type
                  <SearchableSelect
                    className="mt-2 w-full"
                    value={type}
                    onChange={setType}
                    allowEmpty={false}
                    placeholder="Search document type…"
                    options={requirements.map((item) => ({
                      label: item.type,
                      value: item.type,
                    }))}
                  />
                </label>
                {type === "Custom document" && (
                  <label className="text-[10px] text-zinc-500">
                    Custom name
                    <Input
                      className="mt-2"
                      value={customLabel}
                      onChange={(e) => setCustomLabel(e.target.value)}
                    />
                  </label>
                )}
                <label className="text-[10px] text-zinc-500">
                  Expiry date (optional)
                  <Input
                    className="mt-2"
                    type="date"
                    value={expiry}
                    onChange={(e) => setExpiry(e.target.value)}
                  />
                </label>
                <label className="text-[10px] text-zinc-500">
                  File
                  <input
                    aria-label="Provider document file"
                    className="mt-2 block w-full text-xs"
                    type="file"
                    accept="image/*,.pdf"
                    onChange={(e) => setFile(e.target.files?.[0] ?? null)}
                  />
                </label>
              </div>
              <Button className="mt-4" disabled={uploading} onClick={upload}>
                <Upload />
                {uploading ? "Uploading…" : "Upload document"}
              </Button>
            </section>
          </div>
          <aside className="space-y-5">
            <section className="panel p-4">
              <h3 className="text-xs font-semibold">Verification controls</h3>
              <label className="mt-4 block text-[10px] text-zinc-500">
                Verification officer
                <SearchableSelect
                  className="mt-2 w-full"
                  value={provider.verification.officerId ?? ""}
                  onChange={(value) =>
                    actions.assignVerificationOfficer(provider.id, value)
                  }
                  emptyLabel="Unassigned"
                  placeholder="Search verification officer…"
                  options={db.admins
                    .filter((admin) => admin.status === "Active")
                    .map((admin) => ({
                      label: admin.name,
                      value: admin.id,
                    }))}
                />
              </label>
              <label className="mt-4 block text-[10px] text-zinc-500">
                Background check
                <SearchableSelect
                  className="mt-2 w-full"
                  value={provider.verification.backgroundCheck}
                  onChange={(value) =>
                    actions.updateProviderBackgroundCheck(
                      provider.id,
                      value as Provider["verification"]["backgroundCheck"],
                    )
                  }
                  allowEmpty={false}
                  options={[
                    "Not Started",
                    "In Progress",
                    "Completed",
                    "Failed",
                  ].map((value) => ({ label: value, value }))}
                />
              </label>
              <textarea
                className="input mt-4 min-h-24 w-full py-3"
                value={note}
                onChange={(e) => setNote(e.target.value)}
                placeholder="Internal verification note"
              />
              <Button
                variant="secondary"
                className="mt-2 w-full"
                disabled={!note.trim()}
                onClick={() => {
                  actions.addProviderVerificationNote(provider.id, note);
                  setNote("");
                  notify("Verification note saved");
                }}
              >
                Add internal note
              </Button>
              <Button
                className="mt-4 w-full"
                disabled={
                  summary?.percentage !== 100 ||
                  provider.verification.backgroundCheck !== "Completed" ||
                  !provider.verification.contractSigned
                }
                onClick={() => {
                  try {
                    actions.setProviderDecision(provider.id, "approve");
                    notify(`${provider.name} verified and activated`);
                  } catch (error) {
                    notify(
                      error instanceof Error
                        ? error.message
                        : "Approval failed",
                    );
                  }
                }}
              >
                <ShieldCheck />
                Approve & activate provider
              </Button>
            </section>
            <section className="panel p-4">
              <h3 className="text-xs font-semibold">
                Required document checklist
              </h3>
              <div className="mt-3 space-y-2">
                {(provider.requiredDocumentTypes??requirements.filter((item)=>item.required).map((item)=>item.type)).map((type) => {
                  const document = provider.documents.find(
                    (item) => item.type === type,
                  );
                  const status = document
                    ? effectiveDocumentStatus(document)
                    : "Missing";
                  return (
                    <div
                      key={type}
                      className="flex items-center justify-between gap-2 text-[10px]"
                    >
                      <span>{type}</span>
                      <span
                        className={
                          status === "Approved"
                            ? "text-emerald-400"
                            : "text-amber-400"
                        }
                      >
                        {status}
                      </span>
                    </div>
                  );
                })}
              </div>
            </section>
            <section className="panel p-4">
              <h3 className="text-xs font-semibold">
                Provider activity timeline
              </h3>
              <div className="mt-4 max-h-[460px] space-y-4 overflow-y-auto">
                {provider.activityTimeline.map((event) => (
                  <div
                    key={event.id}
                    className="border-l border-indigo-500/30 pl-4"
                  >
                    <b className="block text-[10px]">{event.label}</b>
                    <span className="text-[9px] text-zinc-600">
                      {new Date(event.at).toLocaleString()} · {event.actor}
                    </span>
                  </div>
                ))}
                <div className="border-l border-white/[.08] pl-4">
                  <b className="block text-[10px]">Last login</b>
                  <span className="text-[9px] text-zinc-600">
                    {provider.lastLogin
                      ? new Date(provider.lastLogin).toLocaleString()
                      : "Never"}{" "}
                    · Provider app
                  </span>
                </div>
                <div className="border-l border-white/[.08] pl-4">
                  <b className="block text-[10px]">Last completed job</b>
                  <span className="text-[9px] text-zinc-600">
                    {db.jobs.find(
                      (job) =>
                        job.providerId === provider.id &&
                        job.status === "Completed",
                    )?.id ?? "None"}
                  </span>
                </div>
                <div className="border-l border-white/[.08] pl-4">
                  <b className="block text-[10px]">Latest complaints</b>
                  <span className="text-[9px] text-zinc-600">
                    {db.complaints
                      .filter((item) => item.providerId === provider.id)
                      .slice(0, 2)
                      .map((item) => item.id)
                      .join(", ") || "None"}
                  </span>
                </div>
              </div>
            </section>
          </aside>
        </div>
      </div>
      {reviewing && (
        <ReviewDialog
          document={reviewing.document}
          status={reviewing.status}
          notes={reviewNotes}
          setNotes={setReviewNotes}
          close={() => setReviewing(null)}
          submit={() => {
            if (
              ["Rejected", "Pending"].includes(reviewing.status) &&
              !reviewNotes.trim()
            )
              return notify("A rejection or re-upload reason is required");
            actions.reviewProviderDocument(
              provider.id,
              reviewing.document.id,
              reviewing.status,
              reviewNotes,
              user?.name ?? "Authenticated administrator",
            );
            notify(`${reviewing.document.type} marked ${reviewing.status}`);
            setReviewing(null);
          }}
        />
      )}
      {preview && (
        <div
          className="fixed inset-0 z-[120] grid place-items-center bg-black/80 p-6"
          onMouseDown={() => setPreview(null)}
        >
          <div
            className="h-[80vh] w-full max-w-4xl overflow-hidden rounded-2xl bg-white"
            onMouseDown={(e) => e.stopPropagation()}
          >
            <div className="flex h-12 items-center justify-between bg-zinc-950 px-4 text-xs text-white">
              <span>{preview.fileName}</span>
              <button onClick={() => setPreview(null)}>
                <X />
              </button>
            </div>
            {preview.mimeType.startsWith("image/") ? (
              <img
                src={preview.storageUrl}
                alt={preview.type}
                className="h-[calc(100%-48px)] w-full object-contain"
              />
            ) : (
              <iframe
                title={preview.type}
                src={preview.storageUrl}
                className="h-[calc(100%-48px)] w-full"
              />
            )}
          </div>
        </div>
      )}
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete provider document?"
        description="The file is removed from the active verification record. The deletion remains in audit logs."
        onConfirm={() => {
          if (deleting) {
            actions.deleteProviderDocument(provider.id, deleting.id);
            notify(`${deleting.type} deleted`);
            setDeleting(null);
          }
        }}
      />
    </div>
  );
}

async function uploadDocument(file:File,providerId:string):Promise<StoredDocumentFile&{storageKey:string}>{
  const stored=await uploadFirebaseFile(file,`provider-documents/${providerId}`);const digest=await crypto.subtle.digest("SHA-256",await file.arrayBuffer());const checksum=Array.from(new Uint8Array(digest)).map((value)=>value.toString(16).padStart(2,"0")).join("");
  return{fileName:stored.fileName,fileType:file.name.split(".").pop()?.toUpperCase()??"FILE",fileSize:stored.fileSize,mimeType:stored.mimeType,storageUrl:stored.url,checksum,storageKey:stored.path};
}

function VerificationBadge({ provider }: { provider: Provider }) {
  const summary = verificationSummary(provider);
  const label =
    provider.status === "Suspended"
      ? "Suspended"
      : provider.status === "Banned" || provider.status === "Blocked"
        ? "Blocked"
        : provider.status === "Rejected"
          ? "Rejected"
          : summary.eligible
            ? "Verified"
            : summary.missing.length
              ? "Documents Missing"
              : "Pending Verification";
  return (
    <Badge
      variant={
        label === "Verified"
          ? "success"
          : label === "Rejected" || label === "Blocked"
            ? "destructive"
            : "warning"
      }
    >
      {label} · {summary.percentage}%
    </Badge>
  );
}
function DocumentRow({
  document,
  onPreview,
  onDownload,
  onReview,
  onDelete,
  onReplace,
}: {
  document: ProviderDocument;
  onPreview: () => void;
  onDownload: () => void;
  onReview: (status: ProviderDocumentStatus) => void;
  onDelete: () => void;
  onReplace: (file?: File) => void;
}) {
  const status = effectiveDocumentStatus(document);
  return (
    <div className="p-4">
      <div className="flex flex-wrap items-start gap-3">
        <span className="grid h-10 w-10 place-items-center rounded-xl bg-white/[.04]">
          <FileCheck2 className="h-4 w-4" />
        </span>
        <div className="min-w-[220px] flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <b className="text-xs">{document.customLabel || document.type}</b>
            <Badge
              variant={
                status === "Approved"
                  ? "success"
                  : status === "Rejected" || status === "Expired"
                    ? "destructive"
                    : "warning"
              }
            >
              {status}
            </Badge>
            {document.required && (
              <span className="text-[8px] text-amber-400">REQUIRED</span>
            )}
          </div>
          <p className="mt-1 text-[9px] text-zinc-600">
            {document.fileName} · {(document.fileSize / 1024).toFixed(1)} KB ·{" "}
            {document.mimeType}
          </p>
          <p className="mt-1 text-[9px] text-zinc-600">
            Uploaded {new Date(document.uploadedAt).toLocaleString()} by{" "}
            {document.uploadedBy}
            {document.expiryDate
              ? ` · Expires ${new Date(document.expiryDate).toLocaleDateString()}`
              : ""}
          </p>
          {document.reviewerName && (
            <p className="mt-1 text-[9px] text-zinc-500">
              Reviewed by {document.reviewerName}
              {document.reviewNotes ? ` · ${document.reviewNotes}` : ""}
            </p>
          )}
        </div>
        <div className="flex flex-wrap gap-1">
          <Button size="sm" variant="secondary" onClick={onPreview}>
            <Eye />
            Preview
          </Button>
          <Button size="sm" variant="secondary" onClick={onDownload}>
            <Download />
            Download
          </Button>
          <label className="btn-secondary h-8 cursor-pointer rounded-lg px-3 text-xs">
            <RefreshCcw className="h-3.5 w-3.5" />
            Replace
            <input
              hidden
              type="file"
              accept="image/*,.pdf"
              onChange={(e) => onReplace(e.target.files?.[0])}
            />
          </label>
          <Button
            size="sm"
            variant="secondary"
            onClick={() => onReview("Under Review")}
          >
            <FileClock />
            Review
          </Button>
          <Button size="sm" onClick={() => onReview("Approved")}>
            <CheckCircle2 />
            Approve
          </Button>
          <Button
            size="sm"
            variant="destructive"
            onClick={() => onReview("Rejected")}
          >
            Reject
          </Button>
          <Button
            size="sm"
            variant="outline"
            onClick={() => onReview("Pending")}
          >
            Request re-upload
          </Button>
          <Button
            aria-label={`Delete ${document.type}`}
            size="icon"
            variant="ghost"
            onClick={onDelete}
          >
            <Trash2 />
          </Button>
        </div>
      </div>
      {document.versions.length > 0 && (
        <details className="mt-3 rounded-xl bg-black/20 p-3">
          <summary className="cursor-pointer text-[10px] text-zinc-400">
            <History className="mr-2 inline h-3.5 w-3.5" />
            {document.versions.length} previous version
            {document.versions.length > 1 ? "s" : ""}
          </summary>
          <div className="mt-2 space-y-1">
            {document.versions.map((version) => (
              <div
                key={version.id}
                className="flex justify-between text-[9px] text-zinc-600"
              >
                <span>
                  v{version.version} · {version.fileName} · {version.uploadedBy}
                </span>
                <span>{new Date(version.uploadedAt).toLocaleString()}</span>
              </div>
            ))}
          </div>
        </details>
      )}
    </div>
  );
}
function ReviewDialog({
  document,
  status,
  notes,
  setNotes,
  close,
  submit,
}: {
  document: ProviderDocument;
  status: ProviderDocumentStatus;
  notes: string;
  setNotes: (value: string) => void;
  close: () => void;
  submit: () => void;
}) {
  return (
    <div
      className="fixed inset-0 z-[130] grid place-items-center bg-black/75 p-4"
      onMouseDown={close}
    >
      <div
        className="panel w-full max-w-md p-5"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <h3 className="font-semibold">
          {status} · {document.type}
        </h3>
        <p className="mt-2 text-xs text-zinc-500">
          Add review notes, rejection reason, or re-upload instructions.
        </p>
        <textarea
          autoFocus
          className="input mt-4 min-h-28 w-full py-3"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Review notes"
        />
        <div className="mt-4 flex justify-end gap-2">
          <Button variant="secondary" onClick={close}>
            Cancel
          </Button>
          <Button onClick={submit}>Confirm {status}</Button>
        </div>
      </div>
    </div>
  );
}
