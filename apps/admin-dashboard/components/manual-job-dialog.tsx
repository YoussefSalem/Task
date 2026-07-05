"use client";

import { useMemo, useState } from "react";
import { AlertTriangle, Check, Search, Sparkles, X } from "lucide-react";
import { useAdminData } from "@/components/admin-data-provider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import { isProviderEligible } from "@/lib/provider-verification";
import { providerMatchesQuery } from "@/lib/provider-search";

export function ManualJobDialog({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: (id: string) => void;
}) {
  const { db, actions } = useAdminData();
  const [customerQuery, setCustomerQuery] = useState("");
  const [customerId, setCustomerId] = useState("");
  const [serviceQuery, setServiceQuery] = useState("");
  const [serviceId, setServiceId] = useState("");
  const [providerQuery, setProviderQuery] = useState("");
  const [providerId, setProviderId] = useState("");
  const [address, setAddress] = useState("");
  const [area, setArea] = useState("");
  const [city, setCity] = useState("");
  const [problemDescription, setProblemDescription] = useState("");
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");
  const [scheduled, setScheduled] = useState("");
  const [bookingType, setBookingType] = useState<"Emergency" | "Scheduled" | "Quotation">("Scheduled");
  const emergency = bookingType === "Emergency";
  const quotation = bookingType === "Quotation";
  const [override, setOverride] = useState("");
  const [overrideReason, setOverrideReason] = useState("");
  const [error, setError] = useState("");

  const customer = db.customers.find((x) => x.id === customerId);
  const service = db.services.find((x) => x.id === serviceId);
  const customerResults = useMemo(() => {
    const q = customerQuery.toLowerCase().trim();
    if (!q) return db.customers.slice(0, 5);
    return db.customers
      .filter((x) => {
        const previous = db.jobs
          .filter((j) => j.customerId === x.id)
          .map((j) => j.id)
          .join(" ");
        return `${x.id} ${x.name} ${x.phone} ${x.email} ${previous}`
          .toLowerCase()
          .includes(q);
      })
      .slice(0, 6);
  }, [customerQuery, db.customers, db.jobs]);
  const serviceResults = useMemo(() => {
    const q = serviceQuery.toLowerCase().trim();
    return db.services
      .filter(
        (x) =>
          x.enabled &&
          `${x.id} ${x.name} ${db.categories.find((c) => c.id === x.categoryId)?.name}`
            .toLowerCase()
            .includes(q),
      )
      .slice(0, 6);
  }, [db.categories, db.services, serviceQuery]);
  const providerResults = useMemo(() => {
    return db.providers
      .filter(
        (x) =>
          isProviderEligible(x) &&
          providerMatchesQuery(x, providerQuery, db.services),
      )
      .sort(
        (a, b) =>
          Number(b.available) - Number(a.available) ||
          Number(b.areas.includes(area)) - Number(a.areas.includes(area)) ||
          b.rating - a.rating ||
          a.jobs - b.jobs,
      )
      .slice(0, 8);
  }, [area, db.providers, db.services, providerQuery]);
  const calculated = service
    ? service.basePrice +
      service.inspectionFee +
      (emergency ? service.emergencyFee : 0)
    : 0;
  const amount = override ? Number(override) : calculated;

  if (!open) return null;
  const create = async () => {
    setError("");
    if (
      !customer ||
      !service ||
      !address.trim() ||
      !area.trim() ||
      !scheduled.trim() ||
      !problemDescription.trim()
    )
      return setError(
        "Customer, service, address, area, schedule, and problem description are required.",
      );
    if (override && Number(override) !== calculated && !overrideReason.trim())
      return setError(
        "A reason is required when overriding the calculated price.",
      );
    const hasLat = lat.trim().length > 0;
    const hasLng = lng.trim().length > 0;
    if (hasLat !== hasLng)
      return setError("Both latitude and longitude are required for GPS.");
    const gps = hasLat
      ? { lat: Number(lat), lng: Number(lng) }
      : undefined;
    if (
      gps &&
      (!Number.isFinite(gps.lat) ||
        !Number.isFinite(gps.lng) ||
        Math.abs(gps.lat) > 90 ||
        Math.abs(gps.lng) > 180)
    )
      return setError("GPS coordinates are outside valid latitude/longitude bounds.");
    const job = await actions.createJob({
      customerId: customer.id,
      serviceId: service.id,
      providerId: providerId || undefined,
      address,
      area,
      city: city || undefined,
      scheduled,
      amount,
      priceOverrideReason: overrideReason || undefined,
      priority: emergency ? "Emergency" : "Normal",
      bookingType,
      emergencyFee: emergency ? service.emergencyFee : 0,
      emergencyResponseSlaMinutes: emergency ? 10 : undefined,
      responseSlaMinutes: emergency ? 10 : quotation ? 120 : 30,
      arrivalSlaMinutes: emergency ? 30 : quotation ? 240 : 60,
      completionSlaMinutes: quotation ? undefined : 180,
      scheduledAt: bookingType === "Scheduled" ? scheduled : undefined,
      appointmentReminderAt: bookingType === "Scheduled" ? scheduled : undefined,
      quotationStatus: quotation ? "Requested" : undefined,
      quotedPrice: quotation ? amount : undefined,
      quotationNotes: quotation ? problemDescription.trim() : undefined,
      problemDescription: problemDescription.trim(),
      customerBudget: amount,
      gps,
    });
    onCreated(job.id);
    onClose();
  };
  return (
    <div
      className="fixed inset-0 z-[100] overflow-y-auto bg-black/75 p-4 backdrop-blur-sm"
      onMouseDown={onClose}
    >
      <div
        className="mx-auto my-6 w-full max-w-5xl overflow-hidden rounded-2xl border border-white/[.1] bg-[#121215] shadow-2xl"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between border-b border-white/[.07] p-5">
          <div>
            <h2 className="text-lg font-semibold">Create manual job</h2>
            <p className="mt-1 text-xs text-zinc-500">
              Search-first booking with live pricing and provider suggestions.
            </p>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X />
          </Button>
        </div>
        <div className="grid gap-5 p-5 lg:grid-cols-2">
          <SearchPicker
            title="1. Find customer"
            query={customerQuery}
            setQuery={setCustomerQuery}
            placeholder="Name, phone, email, customer ID, previous order ID"
          >
            {customerResults.map((x) => (
              <button
                key={x.id}
                onClick={() => {
                  setCustomerId(x.id);
                  setCustomerQuery(x.name);
                  setAddress(x.addresses[0] ?? "");
                }}
                className={cn(
                  "flex w-full items-center justify-between rounded-xl border p-3 text-left",
                  customerId === x.id
                    ? "border-indigo-500/40 bg-indigo-500/10"
                    : "border-white/[.06] bg-white/[.02]",
                )}
              >
                <span>
                  <b className="block text-xs">{x.name}</b>
                  <small className="text-[10px] text-zinc-500">
                    {x.id} · {x.phone} · {x.email}
                  </small>
                </span>
                {customerId === x.id && (
                  <Check className="h-4 w-4 text-indigo-400" />
                )}
              </button>
            ))}
            {!customerResults.length && (
              <p className="rounded-xl border border-dashed border-white/[.08] p-4 text-center text-xs text-zinc-500">
                No customers found in Firestore.
              </p>
            )}
          </SearchPicker>
          <div className="rounded-xl border border-white/[.07] bg-white/[.02] p-4">
            <h3 className="text-xs font-semibold">Customer context</h3>
            {customer ? (
              <div className="mt-3 space-y-2 text-[11px] text-zinc-400">
                <div className="flex justify-between">
                  <span>Wallet</span>
                  <b className="text-emerald-400">
                    EGP {customer.walletBalance.toLocaleString()}
                  </b>
                </div>
                <div className="flex justify-between">
                  <span>Risk</span>
                  <b
                    className={
                      customer.risk === "Healthy"
                        ? "text-emerald-400"
                        : "text-amber-400"
                    }
                  >
                    {customer.risk}
                  </b>
                </div>
                <div>
                  <span className="text-zinc-600">Saved addresses</span>
                  {customer.addresses.length ? (
                    customer.addresses.map((x) => (
                      <button
                        key={x}
                        onClick={() => setAddress(x)}
                        className="mt-1 block w-full rounded-lg border border-white/[.06] p-2 text-left hover:bg-white/[.04]"
                      >
                        {x}
                      </button>
                    ))
                  ) : (
                    <p className="mt-1 text-zinc-600">No saved addresses</p>
                  )}
                </div>
                <div>
                  <span className="text-zinc-600">Recent jobs</span>
                  <p>
                    {db.jobs
                      .filter((x) => x.customerId === customer.id)
                      .slice(0, 3)
                      .map((x) => x.id)
                      .join(", ") || "None"}
                  </p>
                </div>
              </div>
            ) : (
              <p className="mt-4 text-xs text-zinc-600">
                Select a customer to see wallet, addresses, jobs, and risk
                flags.
              </p>
            )}
          </div>
          <SearchPicker
            title="2. Select service"
            query={serviceQuery}
            setQuery={setServiceQuery}
            placeholder="Category or service name"
          >
            {serviceResults.map((x) => (
              <button
                key={x.id}
                onClick={() => {
                  setServiceId(x.id);
                  setServiceQuery(x.name);
                }}
                className={cn(
                  "flex w-full justify-between rounded-xl border p-3 text-left",
                  serviceId === x.id
                    ? "border-indigo-500/40 bg-indigo-500/10"
                    : "border-white/[.06]",
                )}
              >
                <span className="text-xs">{x.name}</span>
                <span className="text-xs text-zinc-500">EGP {x.basePrice}</span>
              </button>
            ))}
            {!serviceResults.length && (
              <p className="rounded-xl border border-dashed border-white/[.08] p-4 text-center text-xs text-zinc-500">
                No enabled services found in Firestore.
              </p>
            )}
          </SearchPicker>
          <div className="space-y-3 rounded-xl border border-white/[.07] bg-white/[.02] p-4">
            <h3 className="text-xs font-semibold">3. Address & schedule</h3>
            <div className="grid gap-2 sm:grid-cols-3">
              {(["Emergency", "Scheduled", "Quotation"] as const).map((type) => (
                <button
                  key={type}
                  onClick={() => setBookingType(type)}
                  className={cn(
                    "rounded-xl border px-3 py-2 text-left text-[11px]",
                    bookingType === type
                      ? "border-indigo-400/40 bg-indigo-500/15 text-indigo-100"
                      : "border-white/[.07] bg-white/[.025] text-zinc-500",
                  )}
                >
                  <b className="block">{type}</b>
                  <span className="text-[9px]">
                    {type === "Emergency"
                      ? "Strict SLA + fee"
                      : type === "Quotation"
                        ? "Visit and quote"
                        : "Customer date/time"}
                  </span>
                </button>
              ))}
            </div>
            <Input
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Saved or new street address"
            />
            <Input
              value={area}
              onChange={(e) => setArea(e.target.value)}
              placeholder="Service area"
            />
            <Input
              value={city}
              onChange={(e) => setCity(e.target.value)}
              placeholder="City"
            />
            <Input
              value={scheduled}
              onChange={(e) => setScheduled(e.target.value)}
              placeholder={bookingType === "Emergency" ? "ASAP / Today, 4:30 PM" : bookingType === "Quotation" ? "Requested visit time" : "Scheduled appointment time"}
            />
            <textarea
              value={problemDescription}
              onChange={(e) => setProblemDescription(e.target.value)}
              placeholder="Problem description from customer/support"
              className="input min-h-20 w-full resize-none py-3"
            />
            <div className="grid gap-2 sm:grid-cols-2">
              <Input
                type="number"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
                placeholder="GPS latitude"
              />
              <Input
                type="number"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
                placeholder="GPS longitude"
              />
            </div>
          </div>
          <SearchPicker
            title="4. Suggested provider (optional)"
            query={providerQuery}
            setQuery={setProviderQuery}
            placeholder="Name, phone, ID, skill, area, rating, availability"
          >
            {providerResults.map((x) => (
              <button
                key={x.id}
                onClick={() => setProviderId(providerId === x.id ? "" : x.id)}
                className={cn(
                  "flex w-full items-center justify-between rounded-xl border p-3 text-left",
                  providerId === x.id
                    ? "border-indigo-500/40 bg-indigo-500/10"
                    : "border-white/[.06]",
                )}
              >
                <span>
                  <b className="block text-xs">{x.name}</b>
                  <small className="text-[10px] text-zinc-500">
                    {x.providerId} · {x.trade} · {x.rating}★ · {x.jobs} jobs ·{" "}
                    {x.areas.join(", ")}
                  </small>
                </span>
                <span
                  className={cn(
                    "rounded-full px-2 py-1 text-[9px]",
                    x.available
                      ? "bg-emerald-500/10 text-emerald-400"
                      : "bg-white/[.05] text-zinc-600",
                  )}
                >
                  {x.available ? "Online" : "Offline"}
                </span>
              </button>
            ))}
            {!providerResults.length && (
              <p className="rounded-xl border border-dashed border-white/[.08] p-4 text-center text-xs text-zinc-500">
                No verified available providers match this search.
              </p>
            )}
          </SearchPicker>
          <div className="space-y-3 rounded-xl border border-white/[.07] bg-white/[.02] p-4">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-semibold">5. Pricing</h3>
              <span className={cn("rounded-lg px-2.5 py-1.5 text-[10px]", emergency ? "bg-red-500/15 text-red-400" : quotation ? "bg-amber-500/15 text-amber-300" : "bg-white/[.05] text-zinc-500")}>{bookingType}</span>
            </div>
            <div className="rounded-xl bg-black/20 p-3 text-[11px] text-zinc-500">
              <div className="flex justify-between">
                <span>Base + inspection {emergency && "+ emergency"}</span>
                <b className="text-zinc-200">EGP {calculated}</b>
              </div>
            </div>
            <Input
              type="number"
              min={0}
              value={override}
              onChange={(e) => setOverride(e.target.value)}
              placeholder={`Admin override (calculated EGP ${calculated})`}
            />
            {override && Number(override) !== calculated && (
              <Input
                value={overrideReason}
                onChange={(e) => setOverrideReason(e.target.value)}
                placeholder="Mandatory override reason"
              />
            )}
            <div className="flex justify-between text-sm">
              <span>Total</span>
              <b>EGP {amount.toLocaleString()}</b>
            </div>
          </div>
        </div>
        {error && (
          <div
            role="alert"
            className="mx-5 mb-3 flex items-center gap-2 rounded-xl border border-red-500/20 bg-red-500/10 p-3 text-xs text-red-300"
          >
            <AlertTriangle className="h-4 w-4" />
            {error}
          </div>
        )}
        <div className="flex items-center justify-between border-t border-white/[.07] p-4">
          <span className="flex items-center gap-2 text-[10px] text-zinc-500">
            <Sparkles className="h-3.5 w-3.5 text-indigo-400" />
            Unassigned jobs enter the Live Operations queue.
          </span>
          <div className="flex gap-2">
            <Button variant="secondary" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={create}>Create job</Button>
          </div>
        </div>
      </div>
    </div>
  );
}

function SearchPicker({
  title,
  query,
  setQuery,
  placeholder,
  children,
}: {
  title: string;
  query: string;
  setQuery: (value: string) => void;
  placeholder: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-2 rounded-xl border border-white/[.07] bg-white/[.02] p-4">
      <h3 className="text-xs font-semibold">{title}</h3>
      <div className="relative">
        <Search className="absolute left-3 top-3 h-3.5 w-3.5 text-zinc-600" />
        <Input
          className="pl-9"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={placeholder}
        />
      </div>
      <div className="max-h-48 space-y-1.5 overflow-y-auto">{children}</div>
    </div>
  );
}
