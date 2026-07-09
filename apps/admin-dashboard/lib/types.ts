export type ISODate = string;
export type DataEnvironment = "production" | "demo";
export type EntityStatus =
  | "Active"
  | "Suspended"
  | "Banned"
  | "Pending"
  | "Disabled";
export type JobStatus =
  | "Scheduled"
  | "Assigned"
  | "En route"
  | "In progress"
  | "Delayed"
  | "Completed"
  | "Cancelled"
  | "Refunded"
  | "Disputed"
  | "Paused for approval";
export type Severity = "Critical" | "High" | "Medium" | "Low";

export interface Customer {
  id: string;
  name: string;
  initials: string;
  email: string;
  phone: string;
  status: EntityStatus;
  disabled?: boolean;
  walletBalance: number;
  bookings: number;
  totalSpend: number;
  rating: number;
  risk: "Healthy" | "Watch" | "Review";
  addresses: string[];
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export interface Provider {
  id: string;
  providerId: string;
  name: string;
  initials: string;
  email: string;
  phone: string;
  nationalIdNumber: string;
  photo?: string;
  trade: string;
  rating: number;
  acceptanceRate: number;
  jobs: number;
  earnings: number;
  status:
    | "Active"
    | "Warning"
    | "Under Review"
    | "Review"
    | "Suspended"
    | "Banned"
    | "Blacklisted"
    | "Rejected"
    | "Blocked"
    | "Disabled";
  disabled?: boolean;
  statusBeforeDisable?: Provider["status"];
  verified: boolean;
  response: string;
  serviceIds: string[];
  areas: string[];
  cities: string[];
  commission: number;
  available: boolean;
  requiredDocumentTypes: string[];
  documents: ProviderDocument[];
  verification: ProviderVerification;
  activityTimeline: ProviderActivityEvent[];
  lastLogin?: ISODate;
  lastActive: string;
  availabilitySchedule: Record<string, string>;
  bankInfo: { bankName: string; iban: string; instapay: string };
  notes: string[];
  performanceWarnings?: ProviderWarning[];
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export interface ProviderWarning {
  id: string;
  reason: string;
  notes: string;
  status: "Open" | "Acknowledged" | "Resolved" | "Dismissed";
  createdAt: ISODate;
  createdBy: string;
  createdById?: string;
  resolvedAt?: ISODate;
  resolvedBy?: string;
}
export type ProviderDocumentStatus =
  | "Pending"
  | "Under Review"
  | "Approved"
  | "Rejected"
  | "Expired";
export interface ProviderDocumentVersion {
  id: string;
  version: number;
  fileName: string;
  storageUrl: string;
  fileSize: number;
  mimeType: string;
  checksum: string;
  uploadedAt: ISODate;
  uploadedBy: string;
}
export interface ProviderDocument {
  id: string;
  type: string;
  customLabel?: string;
  name: string;
  fileName: string;
  fileType: string;
  fileSize: number;
  mimeType: string;
  storageUrl: string;
  thumbnail?: string;
  checksum: string;
  status: ProviderDocumentStatus;
  uploadedAt: ISODate;
  uploadedBy: string;
  expiryDate?: ISODate;
  reviewerName?: string;
  reviewedAt?: ISODate;
  reviewNotes?: string;
  required: boolean;
  versions: ProviderDocumentVersion[];
}
export interface ProviderVerification {
  stage:
    | "Registration"
    | "Documents Uploaded"
    | "Pending Review"
    | "Documents Approved"
    | "Background Check"
    | "Contract Signed"
    | "Provider Approved"
    | "Provider Active";
  officerId?: string;
  officerName?: string;
  backgroundCheck: "Not Started" | "In Progress" | "Completed" | "Failed";
  contractSigned: boolean;
  internalNotes: string[];
  updatedAt: ISODate;
}
export interface ProviderActivityEvent {
  id: string;
  type: string;
  label: string;
  at: ISODate;
  actor: string;
}
export interface ProviderLocation {
  id: string;
  providerId: string;
  lat: number;
  lng: number;
  heading: number;
  accuracy: number;
  updatedAt: ISODate;
  status: "Available" | "Busy" | "Offline";
  source?: "provider-app" | "admin" | "system";
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export type AiRiskLevel = "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
export type AiToolStatus = "planned" | "executed" | "blocked" | "needs_confirmation";
export interface AiEvidence {
  id: string;
  label: string;
  entityType: "customer" | "provider" | "job" | "payment" | "complaint" | "wallet" | "service" | "system";
  entityId?: string;
  value: string;
}
export interface AiActionRequest {
  type:
    | "navigate"
    | "openJob"
    | "openProvider"
    | "refundJob"
    | "adjustWallet"
    | "createComplaint"
    | "assignProvider"
    | "changeJobStatus"
    | "setProviderDecision"
    | "createPromo"
    | "createNotification";
  label: string;
  risk: AiRiskLevel;
  requiresConfirmation: boolean;
  payload: Record<string, string | number | boolean | null | undefined>;
}
export interface AiPlanStep {
  id: string;
  label: string;
  status: AiToolStatus;
  risk: AiRiskLevel;
  toolName?: string;
}
export interface AiToolCall {
  id: string;
  name: string;
  permission?: Permission;
  status: AiToolStatus;
  risk: AiRiskLevel;
  summary: string;
  entityType?: string;
  entityId?: string;
}
export interface AiRecommendation {
  id: string;
  title: string;
  body: string;
  risk: AiRiskLevel;
  action?: AiActionRequest;
  acceptedAt?: ISODate;
  dismissedAt?: ISODate;
}
export interface AiExecution {
  id: string;
  prompt: string;
  normalizedPrompt: string;
  actorId: string;
  actorName: string;
  actorRole: AdminRole;
  page: string;
  status: "Completed" | "Needs confirmation" | "Blocked";
  risk: AiRiskLevel;
  answer: string;
  plan: AiPlanStep[];
  toolCalls: AiToolCall[];
  evidence: AiEvidence[];
  recommendations: AiRecommendation[];
  context: {
    currentEntityType?: string;
    currentEntityId?: string;
    resolvedEntityType?: string;
    resolvedEntityId?: string;
  };
  createdAt: ISODate;
  updatedAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface AiMemory {
  id: string;
  actorId: string;
  scope: "admin" | "record" | "platform";
  key: string;
  value: string;
  recordType?: string;
  recordId?: string;
  createdAt: ISODate;
  updatedAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface AiReport {
  id: string;
  type: "executive-brief" | "operations" | "finance" | "trust-safety" | "provider-performance";
  title: string;
  summary: string;
  metrics: Record<string, string | number>;
  recommendations: AiRecommendation[];
  generatedAt: ISODate;
  generatedBy: string;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export interface JobTimelineEvent {
  id: string;
  label: string;
  at: ISODate;
  actor: string;
  actorType?: "customer" | "provider" | "admin" | "system";
  actorId?: string;
  metadata?: Record<string, string | number | boolean>;
}
export type RequestMediaType = "photo" | "video" | "voice" | "file";
export interface RequestMedia {
  id: string; jobId: string; type: RequestMediaType; fileName: string;
  mimeType: string; size: number; url: string; thumbnail?: string;
  uploadedAt: ISODate; uploadedByType: "customer" | "provider" | "admin";
  uploadedById: string; uploadedByName: string;
}
export interface ProviderOffer {
  id: string; jobId: string; providerId: string; price: number; message: string;
  distanceKm?: number; arrivalMinutes: number; completionMinutes: number;
  status: "Pending" | "Accepted" | "Rejected" | "Expired" | "Withdrawn";
  createdAt: ISODate; decidedAt?: ISODate; openedAt?: ISODate;
}
export interface ChatMessage {
  id: string; jobId: string; senderType: "customer" | "provider" | "admin" | "system";
  senderId: string; senderName: string; text: string; attachments: RequestMedia[];
  sentAt: ISODate; delivered: boolean; read: boolean; edited: boolean;
  deleted: boolean; flagged: boolean; reviewNote?: string;
}
export interface VoipCall {
  id: string; jobId: string; customerId: string; providerId?: string;
  caller: string; receiver: string; direction: "Customer to provider" | "Provider to customer";
  status: "Missed" | "Answered" | "Rejected" | "Failed" | "Cancelled";
  startTime: ISODate; endTime?: ISODate; durationSeconds: number;
  recordingStatus: "Unavailable" | "Processing" | "Available";
  recordingUrl?: string; integration: "Twilio" | "Agora" | "Vonage" | "WebRTC" | "Daily.co";
  reviewed: boolean; reviewNote?: string; flagged: boolean; complaintId?: string;
}
export interface JobCancellation {
  cancelledAt: ISODate; cancelledBy: "Customer" | "Provider" | "Admin" | "System";
  reason: string; stage: "before offers" | "after offers" | "after provider accepted" | "provider on the way" | "after arrival" | "during job";
  refundStatus: "Not required" | "Pending" | "Partially refunded" | "Refunded" | "Failed";
  followUpStatus: "Not contacted" | "Contacted" | "Recovered" | "Closed";
  followUpNotes: string[]; supportOwnerId?: string;
}
export type JobPaymentStatus = "Pending" | "Authorized" | "Paid" | "Partially Paid" | "Failed" | "Refunded" | "Partially Refunded" | "Cash Pending Collection" | "Instapay Pending Review" | "Wallet Deducted" | "Cancelled";
export type BookingType = "Emergency" | "Scheduled" | "Quotation";
export type QuotationStatus =
  | "Requested"
  | "Assigned"
  | "Technician visited"
  | "Quotation submitted"
  | "Customer accepted"
  | "Customer rejected"
  | "Converted to booking";
export interface JobPayment {
  method: "Card" | "Cash" | "Instapay" | "Customer wallet" | "Provider wallet" | "Promo credit" | "Manual adjustment";
  status: JobPaymentStatus; amount: number; servicePrice: number; customerOfferPrice: number;
  acceptedOfferPrice?: number; platformCommission: number; providerEarnings: number;
  discount: number; promoCode?: string; walletAmount: number; cardAmount: number;
  instapayAmount: number; refundAmount: number; outstandingAmount: number;
  transactionId?: string; providerReference?: string; paidAt?: ISODate;
}
export interface Job {
  id: string;
  customerId: string;
  providerId?: string;
  serviceId: string;
  customer: string;
  customerInitials: string;
  service: string;
  provider: string;
  area: string;
  address?: string;
  scheduled: string;
  amount: number;
  status: JobStatus;
  elapsed?: string;
  paymentStatus: JobPaymentStatus;
  paymentMethod: string;
  notes: string[];
  timeline: JobTimelineEvent[];
  createdAt: ISODate;
  bookingType?: BookingType;
  emergencyFee?: number;
  emergencyResponseSlaMinutes?: number;
  scheduledAt?: ISODate;
  appointmentReminderAt?: ISODate;
  responseSlaMinutes?: number;
  arrivalSlaMinutes?: number;
  completionSlaMinutes?: number;
  slaBreached?: boolean;
  quotationStatus?: QuotationStatus;
  quotedPrice?: number;
  quotationNotes?: string;
  quotationPhotos?: RequestMedia[];
  convertedJobId?: string;
  priority?: "Emergency" | "High" | "Normal" | "Low";
  priceOverrideReason?: string;
  category?: string;
  problemDescription?: string;
  customerBudget?: number;
  gps?: { lat: number; lng: number };
  city?: string;
  media?: RequestMedia[];
  offers?: ProviderOffer[];
  providersReceived?: number;
  providersOpened?: number;
  acceptedOfferId?: string;
  messages?: ChatMessage[];
  calls?: VoipCall[];
  cancellation?: JobCancellation;
  payment?: JobPayment;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export interface Category {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  serviceCount: number;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface Service {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  imageUrl?: string;
  basePrice: number;
  emergencyFee: number;
  inspectionFee: number;
  commission: number;
  enabled: boolean;
  cities: string[];
  areas: string[];
  updatedAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface Banner { id:string; title:string; subtitle:string; imageUrl:string; actionUrl?:string; enabled:boolean; sortOrder:number; createdAt:ISODate; updatedAt:ISODate; environment?:DataEnvironment; isDemoData?:boolean }
export interface VerificationRequirement { id:string; type:string; required:boolean; enabled:boolean; sortOrder:number }
export interface SupportConversation { id:string; customerId?:string;providerId?:string;jobId?:string;subject:string;status:"Open"|"Pending"|"Closed";priority:"Low"|"Normal"|"High"|"Urgent";assignedAdminId?:string;messages:ChatMessage[];createdAt:ISODate;updatedAt:ISODate; environment?:DataEnvironment; isDemoData?:boolean }

export interface Wallet {
  id: string;
  ownerType: "customer" | "provider";
  ownerId: string;
  balance: number;
  currency: "EGP";
  updatedAt: ISODate;
  frozen?: boolean;
  promoCredit?: number;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export type TransactionType =
  | "Customer payment"
  | "Provider payout"
  | "Customer refund"
  | "Cash collection"
  | "Commission"
  | "Wallet credit"
  | "Wallet debit"
  | "Instapay verification";
export interface Transaction {
  id: string;
  type: TransactionType;
  party: string;
  ownerId?: string;
  amount: number;
  method: string;
  status: "Completed" | "Processing" | "Pending" | "Failed";
  createdAt: ISODate;
  reference?: string;
  jobId?: string;
  providerReference?: string;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface InstapayReview {
  id: string; jobId: string; customerId: string; amount: number; proofUrl: string;
  senderAccount: string; transferReference?: string; submittedAt: ISODate;
  status: "Pending" | "Approved" | "Rejected" | "Better proof requested" | "Suspicious";
  financeNote?: string; transactionId?: string;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface Payout {
  id: string;
  providerId: string;
  providerName: string;
  amount: number;
  method: "Bank transfer" | "Instapay" | "Cash";
  status: "Pending" | "Verified" | "Paid" | "Rejected";
  reference?: string;
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export interface ProviderReview {
  id: string;
  providerId: string;
  customerId?: string;
  customerName: string;
  jobId?: string;
  rating: 1 | 2 | 3 | 4 | 5;
  comment: string;
  pictures?: string[];
  adminNotes?: string[];
  status: "Visible" | "Pending" | "Hidden" | "Approved" | "Deleted";
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}

export interface Complaint {
  id: string;
  title: string;
  description: string;
  customerId?: string;
  providerId?: string;
  jobId?: string;
  customer: string;
  severity: Severity;
  ownerId?: string;
  owner: string;
  status:
    | "New"
    | "Pending"
    | "Under Review"
    | "Investigating"
    | "Evidence review"
    | "Assigned"
    | "Monitoring"
    | "Resolved"
    | "Reopened"
    | "Rejected"
    | "Closed";
  age: string;
  notes: string[];
  evidence: string[];
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
  // Audit trail of admin actions taken on this case (assignment, status
  // changes, notes). Native/demo complaints only - bridged real complaints
  // have no history subcollection today, so this is always absent for them.
  history?: ComplaintHistoryEntry[];
}
export interface ComplaintHistoryEntry {
  at: ISODate;
  action: string;
  detail: string;
}
export type Incident = Complaint;

export type Permission = string;
export interface Role {
  id: string;
  name: string;
  description: string;
  permissions: Permission[];
  system: boolean;
  version?: number;
  createdAt?: ISODate;
  updatedAt?: ISODate;
}
export type AdminRole =
  | "Super admin"
  | "Operations"
  | "Finance"
  | "Trust & Safety"
  | "Support"
  | "Operations Manager"
  | "Support Agent"
  | "Finance Manager"
  | "Verification Officer"
  | "Marketing Manager"
  | "Safety Officer";
export interface AdminUser {
  id: string;
  uid?: string;
  name: string;
  email: string;
  role: AdminRole;
  roleId: string;
  permissions?: Permission[];
  phone?: string;
  department?: string;
  jobTitle?: string;
  avatar?: string;
  twoFactorEnabled?: boolean;
  status: "Active" | "Invited" | "Disabled";
  enabled?: boolean;
  authDisabled?: boolean;
  lastSeen: string;
  createdAt: ISODate;
  updatedAt?: ISODate;
  isDemoUser?: boolean;
  demoExpiresAt?: ISODate;
  demoCompanyName?: string;
  demoContactName?: string;
  demoNotes?: string;
}
export interface AdminInvitation {
  id: string;
  adminId: string;
  email: string;
  roleId: string;
  roleName: string;
  invitedBy: string;
  token?: string;
  tokenHash?: string;
  tokenCreatedAt?: ISODate;
  tokenUsedAt?: ISODate;
  inviteUrl?: string;
  status: "Pending" | "Accepted" | "Revoked" | "Expired";
  emailDeliveryStatus?: "Pending" | "Sent" | "Failed";
  emailProvider?: "resend";
  emailMessageId?: string;
  emailSentAt?: ISODate;
  dashboardUrl?: string;
  lastEmailError?: string | null;
  lastEmailAttemptAt?: ISODate;
  createdAt: ISODate;
  expiresAt: ISODate;
  resentAt?: ISODate;
  lastResentAt?: ISODate;
  lastResentBy?: string;
  resendCount?: number;
  acceptedAt?: ISODate;
  revokedAt?: ISODate;
  assignedPermissions?: Permission[];
}

export interface PromoCode {
  id: string;
  code: string;
  description: string;
  discountType: "percent" | "fixed";
  discount: number;
  maxUses: number;
  used: number;
  startsAt: ISODate;
  endsAt: ISODate;
  enabled: boolean;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface Notification {
  id: string;
  title: string;
  body: string;
  audience: "All customers" | "All providers" | "Segment" | "Individual";
  status: "Draft" | "Scheduled" | "Sent";
  scheduledAt?: ISODate;
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
}
export interface AuditLog {
  id: string;
  actorId: string;
  actorName: string;
  action: string;
  entityType: string;
  entityId: string;
  detail: string;
  createdAt: ISODate;
  environment?: DataEnvironment;
  isDemoData?: boolean;
  before?: string;
  after?: string;
  ipAddress: string;
  device: string;
}

export interface DatabaseState {
  aiExecutions: AiExecution[];
  aiMemories: AiMemory[];
  aiReports: AiReport[];
  customers: Customer[];
  providers: Provider[];
  jobs: Job[];
  categories: Category[];
  services: Service[];
  banners: Banner[];
  conversations: SupportConversation[];
  verificationRequirements: VerificationRequirement[];
  wallets: Wallet[];
  transactions: Transaction[];
  complaints: Complaint[];
  reviews: ProviderReview[];
  admins: AdminUser[];
  invitations: AdminInvitation[];
  roles: Role[];
  promos: PromoCode[];
  notifications: Notification[];
  payouts: Payout[];
  auditLogs: AuditLog[];
  locations: ProviderLocation[];
  instapayReviews: InstapayReview[];
  sequences: { provider: number };
  issuedProviderIds: string[];
}
