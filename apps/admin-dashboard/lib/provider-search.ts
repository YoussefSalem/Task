import type { Complaint, Provider, Service } from "@/lib/types";
import { verificationSummary } from "@/lib/provider-verification";

export type ProviderFilters = {
  presence: string;
  account: string;
  verification: string;
  minRating: string;
  city: string;
  area: string;
  service: string;
  hasComplaints: boolean;
  expiredDocuments: boolean;
  missingDocuments: boolean;
};

export const emptyProviderFilters: ProviderFilters = {
  presence: "All",
  account: "All",
  verification: "All",
  minRating: "0",
  city: "All",
  area: "All",
  service: "All",
  hasComplaints: false,
  expiredDocuments: false,
  missingDocuments: false,
};

const searchable = (value: unknown) => String(value ?? "").toLowerCase().trim();
const digits = (value: unknown) => String(value ?? "").replace(/\D/g, "");

export function providerMatchesQuery(provider: Provider, query: string, services: Service[]) {
  const q = searchable(query);
  if (!q) return true;
  const qDigits = digits(q);
  const phone = digits(provider.phone);
  const localPhone = phone.startsWith("20") ? `0${phone.slice(2)}` : phone;
  const serviceNames = services
    .filter((service) => provider.serviceIds.includes(service.id))
    .map((service) => service.name);
  const values = [
    provider.providerId,
    provider.name,
    provider.email,
    provider.phone,
    provider.nationalIdNumber,
    provider.trade,
    provider.rating,
    provider.status,
    provider.available ? "online available" : "offline unavailable",
    ...provider.areas,
    ...provider.cities,
    ...serviceNames,
  ];
  return values.some((value) => searchable(value).includes(q)) ||
    (!!qDigits && (phone.includes(qDigits) || localPhone.includes(qDigits)));
}

export function filterProviders(
  providers: Provider[],
  query: string,
  filters: ProviderFilters,
  services: Service[],
  complaints: Complaint[],
) {
  return providers.filter((provider) => {
    const summary = verificationSummary(provider);
    const providerComplaints = complaints.some((item) => item.providerId === provider.id);
    const presence = provider.available ? "Online" : "Offline";
    const verification = summary.eligible
      ? "Approved"
      : summary.rejected.length
        ? "Rejected"
        : "Pending Verification";
    return providerMatchesQuery(provider, query, services) &&
      (filters.presence === "All" || filters.presence === presence ||
        (filters.presence === "Available" && provider.available && provider.status === "Active") ||
        (filters.presence === "Busy" && !provider.available && provider.status === "Active")) &&
      (filters.account === "All" || provider.status === filters.account) &&
      (filters.verification === "All" || verification === filters.verification) &&
      provider.rating >= Number(filters.minRating || 0) &&
      (filters.city === "All" || provider.cities.includes(filters.city)) &&
      (filters.area === "All" || provider.areas.includes(filters.area)) &&
      (filters.service === "All" || provider.serviceIds.includes(filters.service)) &&
      (!filters.hasComplaints || providerComplaints) &&
      (!filters.expiredDocuments || summary.expired.length > 0) &&
      (!filters.missingDocuments || summary.missing.length > 0);
  });
}
