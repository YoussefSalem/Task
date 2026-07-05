import { firebaseAdminDb } from "@/lib/firebase/admin";

const demoCollections = [
  "categories",
  "services",
  "banners",
  "customers",
  "providers",
  "providerLocations",
  "wallets",
  "orders",
  "transactions",
  "payouts",
  "complaints",
  "reviews",
  "conversations",
  "promos",
  "notifications",
  "instapayReviews",
  "aiReports",
  "aiExecutions",
  "aiMemories",
  "apiIntegrations",
  "auditLogs",
] as const;

const now = () => new Date().toISOString();
const daysAgo = (days: number) => new Date(Date.now() - days * 86_400_000).toISOString();
const daysAhead = (days: number) => new Date(Date.now() + days * 86_400_000).toISOString();

async function commitChunks(
  writes: Array<(batch: FirebaseFirestore.WriteBatch) => void>,
) {
  for (let i = 0; i < writes.length; i += 450) {
    const batch = firebaseAdminDb.batch();
    writes.slice(i, i + 450).forEach((write) => write(batch));
    await batch.commit();
  }
}

export async function resetDemoData(actor?: { id?: string; name?: string }) {
  const deletes: Array<(batch: FirebaseFirestore.WriteBatch) => void> = [];
  const deletePaths = new Set<string>();
  const queueDelete = (item: FirebaseFirestore.QueryDocumentSnapshot) => {
    if (deletePaths.has(item.ref.path)) return;
    deletePaths.add(item.ref.path);
    deletes.push((batch) => batch.delete(item.ref));
  };
  for (const name of demoCollections) {
    const byEnvironment = await firebaseAdminDb
      .collection(name)
      .where("environment", "==", "demo")
      .get();
    byEnvironment.docs.forEach(queueDelete);
    const byLegacyFlag = await firebaseAdminDb
      .collection(name)
      .where("isDemoData", "==", true)
      .get();
    byLegacyFlag.docs.forEach(queueDelete);
  }
  await commitChunks(deletes);

  const writes: Array<(batch: FirebaseFirestore.WriteBatch) => void> = [];
  const set = (collectionName: string, id: string, data: Record<string, unknown>) => {
    writes.push((batch) =>
      batch.set(
        firebaseAdminDb.collection(collectionName).doc(id),
        { id, ...data, environment: "demo", isDemoData: true },
        { merge: false },
      ),
    );
  };

  const categories = [
    ["demo-cat-electrical", "Electrical", "Emergency repairs, wiring, lighting, breakers"],
    ["demo-cat-plumbing", "Plumbing", "Leaks, mixers, heaters, pumps, drainage"],
    ["demo-cat-hvac", "HVAC", "AC installation, maintenance, and diagnostics"],
    ["demo-cat-cleaning", "Cleaning", "Home deep cleaning and move-in cleaning"],
    ["demo-cat-smart-home", "Smart Home & Cameras", "CCTV, intercom, smart locks, Wi‑Fi"],
  ] as const;
  categories.forEach(([id, name, description]) =>
    set("categories", id, { name, description, enabled: true, serviceCount: 2 }),
  );

  const services = [
    ["demo-svc-electrician", "demo-cat-electrical", "Electrician Visit", 350, 120, 75],
    ["demo-svc-lighting", "demo-cat-electrical", "Lighting Installation", 500, 150, 100],
    ["demo-svc-plumbing", "demo-cat-plumbing", "Plumbing Repair", 300, 100, 75],
    ["demo-svc-water-heater", "demo-cat-plumbing", "Water Heater Service", 450, 150, 100],
    ["demo-svc-ac", "demo-cat-hvac", "AC Maintenance", 550, 180, 100],
    ["demo-svc-cleaning", "demo-cat-cleaning", "Deep Cleaning", 900, 250, 0],
    ["demo-svc-cameras", "demo-cat-smart-home", "Camera Installation", 1200, 300, 150],
  ] as const;
  services.forEach(([id, categoryId, name, basePrice, emergencyFee, inspectionFee]) =>
    set("services", id, {
      name,
      categoryId,
      description: `${name} for Alexandria, Borg El Arab, and North Coast homes.`,
      imageUrl: null,
      basePrice,
      emergencyFee,
      inspectionFee,
      commission: 18,
      enabled: true,
      cities: ["Alexandria", "Borg El Arab", "North Coast"],
      areas: ["Smouha", "Gleem", "Miami", "Borg El Arab", "Marassi", "Sidi Abdelrahman"],
      updatedAt: now(),
    }),
  );

  set("banners", "demo-banner-summer", {
    title: "North Coast summer maintenance",
    subtitle: "AC, plumbing, pool, and smart home technicians ready today.",
    imageUrl: "/task-logo.svg",
    actionUrl: "/dashboard/jobs",
    enabled: true,
    sortOrder: 1,
    createdAt: now(),
    updatedAt: now(),
  });

  const customers = [
    ["demo-customer-mariam", "TASK-C-DEMO-001", "Mariam El-Sayed", "mariam.demo@example.com", "+201090001001", "Smouha, Alexandria", 1850],
    ["demo-customer-omar", "TASK-C-DEMO-002", "Omar Hassan", "omar.demo@example.com", "+201090001002", "Borg El Arab, Alexandria", 620],
    ["demo-customer-nadine", "TASK-C-DEMO-003", "Nadine Fouad", "nadine.demo@example.com", "+201090001003", "Marassi, North Coast", 2400],
    ["demo-customer-youssef", "TASK-C-DEMO-004", "Youssef Mansour", "youssef.demo@example.com", "+201090001004", "Gleem, Alexandria", 320],
  ] as const;
  customers.forEach(([id, customerId, name, email, phone, address, walletBalance]) => {
    set("customers", id, {
      customerId,
      name,
      email,
      phone,
      initials: name.split(" ").map((part) => part[0]).join("").slice(0, 2),
      status: "Active",
      walletBalance,
      bookings: 3,
      totalSpend: walletBalance * 2,
      rating: 4.7,
      risk: id === "demo-customer-youssef" ? "Watch" : "Healthy",
      addresses: [address],
      createdAt: daysAgo(28),
    });
    set("wallets", `demo-wallet-${id}`, {
      ownerType: "customer",
      ownerId: id,
      balance: walletBalance,
      currency: "EGP",
      frozen: false,
      promoCredit: id === "demo-customer-nadine" ? 250 : 0,
      updatedAt: now(),
    });
  });

  const providers = [
    ["demo-provider-ahmed", "TASK-P-DEMO-001", "Ahmed Nabil", "Electrician", "Alexandria", "Available", 4.9, 1280],
    ["demo-provider-mahmoud", "TASK-P-DEMO-002", "Mahmoud Saad", "Plumber", "Borg El Arab", "Busy", 4.6, 890],
    ["demo-provider-karim", "TASK-P-DEMO-003", "Karim Adel", "HVAC", "North Coast", "Offline", 4.8, 2150],
    ["demo-provider-hany", "TASK-P-DEMO-004", "Hany Samir", "Smart Home", "Alexandria", "Available", 4.4, 640],
    ["demo-provider-sherif", "TASK-P-DEMO-005", "Sherif Mostafa", "Plumber", "Alexandria", "Offline", 2.1, 120],
    ["demo-provider-essam", "TASK-P-DEMO-006", "Essam Farouk", "Electrician", "Borg El Arab", "Available", 4.9, 1780],
    ["demo-provider-tarek", "TASK-P-DEMO-007", "Tarek Amin", "HVAC", "North Coast", "Offline", 3.2, 0],
  ] as const;
  providers.forEach(([id, providerId, name, trade, city, availability, rating, balance], index) => {
    const warningHeavy = id === "demo-provider-sherif" || id === "demo-provider-tarek";
    const suspended = id === "demo-provider-sherif";
    const inactive = id === "demo-provider-tarek";
    const highRatingRisk = id === "demo-provider-essam";
    set("providers", id, {
      providerId,
      name,
      email: `${name.toLowerCase().replaceAll(" ", ".")}@demo.task.com`,
      phone: `+20109000200${index + 1}`,
      nationalIdNumber: `29801010${index}12345`,
      trade,
      initials: name.split(" ").map((part) => part[0]).join("").slice(0, 2),
      rating,
      acceptanceRate: suspended ? 18 : inactive ? 35 : highRatingRisk ? 28 : 82 + index * 3,
      jobs: suspended ? 42 : inactive ? 8 : highRatingRisk ? 55 : 24 + index * 7,
      earnings: balance * 5,
      status: suspended ? "Suspended" : inactive ? "Under Review" : highRatingRisk ? "Warning" : "Active",
      verified: !suspended,
      response: suspended ? "46 min" : inactive ? "3 days" : highRatingRisk ? "28 min" : `${8 + index} min`,
      serviceIds: services.filter((svc) => svc[2].toLowerCase().includes(String(trade).toLowerCase().split(" ")[0].toLowerCase())).map((svc) => svc[0]),
      areas: city === "North Coast" ? ["Marassi", "Sidi Abdelrahman"] : ["Smouha", "Gleem", "Borg El Arab"],
      cities: [city],
      commission: 18,
      available: availability !== "Offline",
      requiredDocumentTypes: ["national-id-front", "national-id-back", "criminal-record", "provider-contract"],
      documents: [],
      verification: { stage: "Provider Active", backgroundCheck: "Passed", contractSigned: true, internalNotes: [], updatedAt: now() },
      performanceWarnings: warningHeavy || highRatingRisk ? [
        { id: `demo-warning-${id}-1`, reason: highRatingRisk ? "High ignored offers despite excellent reviews" : "Repeated lateness and cancellations", notes: highRatingRisk ? "Technician quality is strong but operational reliability needs review." : "Support observed repeated customer escalation patterns.", status: "Open", createdAt: daysAgo(3), createdBy: "Demo Operations", createdById: actor?.id ?? "demo-admin" },
        ...(suspended ? [{ id: `demo-warning-${id}-2`, reason: "Suspended after missed appointment", notes: "Auto flag: more than 3 missed appointments.", status: "Open", createdAt: daysAgo(1), createdBy: "Demo Operations", createdById: actor?.id ?? "demo-admin" }] : []),
      ] : [],
      activityTimeline: [
        { id: `demo-event-${id}-activated`, type: "account.activated", label: "Demo provider activated", at: daysAgo(40 - index), actor: "Demo seed" },
        ...(warningHeavy || highRatingRisk ? [{ id: `demo-event-${id}-warning`, type: "performance.warning", label: "Performance warning issued", at: daysAgo(3), actor: "Demo Operations" }] : []),
        ...(suspended ? [{ id: `demo-event-${id}-suspended`, type: "account.suspended", label: "Account suspended after repeated missed appointments", at: daysAgo(1), actor: "Demo Operations" }] : []),
        ...(inactive ? [{ id: `demo-event-${id}-inactive`, type: "performance.inactive", label: "No provider-app activity for more than 30 days", at: daysAgo(30), actor: "System" }] : []),
      ],
      lastActive: inactive ? daysAgo(38) : availability === "Offline" ? daysAgo(2) : now(),
      lastLogin: inactive ? daysAgo(40) : daysAgo(index),
      availabilitySchedule: {},
      bankInfo: { bankName: "CIB", iban: `EG38001900050000000026${index}`, instapay: `${name.split(" ")[0].toLowerCase()}@instapay` },
      notes: warningHeavy ? [`${new Date(daysAgo(2)).toLocaleString()} · Demo Operations: Keep under monitoring before reactivation.`] : [],
      createdAt: daysAgo(45 + index * 4),
    });
    set("wallets", `demo-wallet-${id}`, {
      ownerType: "provider",
      ownerId: id,
      balance,
      currency: "EGP",
      frozen: false,
      promoCredit: 0,
      updatedAt: now(),
    });
    set("providerLocations", id, {
      providerId: id,
      lat: 31.2001 + index * 0.05,
      lng: 29.9187 + index * 0.08,
      heading: 45 + index * 20,
      accuracy: 18,
      updatedAt: now(),
      status: availability,
      source: "demo-seed",
    });
  });

  const jobs = [
    ["demo-job-active", "demo-customer-mariam", "demo-provider-ahmed", "demo-svc-electrician", "Electrical breaker keeps tripping", "Smouha", "In progress", 650, "Paid"],
    ["demo-job-pending", "demo-customer-omar", "", "demo-svc-plumbing", "Kitchen sink leaking under cabinet", "Borg El Arab", "Scheduled", 420, "Pending"],
    ["demo-job-completed", "demo-customer-nadine", "demo-provider-karim", "demo-svc-ac", "AC cooling weak in master bedroom", "Marassi", "Completed", 750, "Paid"],
    ["demo-job-cancelled", "demo-customer-youssef", "demo-provider-mahmoud", "demo-svc-plumbing", "Bathroom mixer replacement", "Gleem", "Cancelled", 360, "Refunded"],
    ["demo-job-sherif-complaint-1", "demo-customer-mariam", "demo-provider-sherif", "demo-svc-plumbing", "Pipe repair left unfinished", "Smouha", "Cancelled", 520, "Refunded"],
    ["demo-job-sherif-complaint-2", "demo-customer-omar", "demo-provider-sherif", "demo-svc-water-heater", "Water heater appointment missed", "Borg El Arab", "Cancelled", 680, "Refunded"],
    ["demo-job-essam-risk", "demo-customer-nadine", "demo-provider-essam", "demo-svc-lighting", "Premium villa lighting fix", "Marassi", "Completed", 1450, "Paid"],
    ["demo-job-tarek-inactive", "demo-customer-youssef", "demo-provider-tarek", "demo-svc-ac", "AC request expired without response", "Sidi Abdelrahman", "Cancelled", 850, "Pending"],
    ["demo-job-low-acceptance", "demo-customer-omar", "", "demo-svc-electrician", "Breaker panel inspection", "Borg El Arab", "Scheduled", 480, "Pending"],
  ] as const;
  jobs.forEach(([id, customerId, providerId, serviceId, problem, area, status, amount, paymentStatus], index) => {
    const customer = customers.find((item) => item[0] === customerId)!;
    const provider = providers.find((item) => item[0] === providerId);
    const service = services.find((item) => item[0] === serviceId)!;
    const type = index === 0 || id.includes("sherif") ? "Emergency" : id.includes("low-acceptance") || id.includes("tarek") ? "Quotation" : "Scheduled";
    const emergencyFee = type === "Emergency" ? Number(service[4]) : 0;
    const quotedPrice = type === "Quotation" ? amount + 120 : undefined;
    set("orders", id, {
      customerId,
      providerId: providerId || null,
      serviceId,
      customer: customer[2],
      customerInitials: customer[2].split(" ").map((part) => part[0]).join("").slice(0, 2),
      service: service[2],
      provider: provider?.[2] ?? "Unassigned",
      area,
      address: customer[5],
      scheduled: index === 1 ? daysAhead(1) : daysAgo(index),
      amount,
      status,
      paymentStatus,
      paymentMethod: index === 1 ? "Instapay" : "Customer wallet",
      notes: status === "Cancelled" ? ["Customer said provider arrival was too late"] : [],
      timeline: [
        { id: `demo-timeline-${id}-1`, label: "Request created", at: daysAgo(index + 1), actor: customer[2], actorType: "customer" },
        { id: `demo-timeline-${id}-type`, label: `${type} flow started`, at: daysAgo(index + 1), actor: "System", actorType: "system" },
        { id: `demo-timeline-${id}-2`, label: `Status changed to ${status}`, at: daysAgo(index), actor: "Demo Operations", actorType: "admin" },
      ],
      createdAt: daysAgo(index + 1),
      bookingType: type,
      emergencyFee,
      emergencyResponseSlaMinutes: type === "Emergency" ? 10 : null,
      responseSlaMinutes: type === "Emergency" ? 10 : type === "Quotation" ? 120 : 30,
      arrivalSlaMinutes: type === "Emergency" ? 30 : type === "Quotation" ? 240 : 60,
      completionSlaMinutes: type === "Quotation" ? null : 180,
      slaBreached: String(status) === "Delayed" || id.includes("sherif") || id.includes("low-acceptance"),
      scheduledAt: type === "Scheduled" ? daysAhead(index % 3) : null,
      appointmentReminderAt: type === "Scheduled" ? daysAhead(Math.max(0, index % 3 - 1)) : null,
      quotationStatus: type === "Quotation" ? (status === "Cancelled" ? "Customer rejected" : id.includes("low-acceptance") ? "Requested" : "Quotation submitted") : null,
      quotedPrice: quotedPrice ?? null,
      quotationNotes: type === "Quotation" ? "Demo quotation visit required before paid booking conversion." : "",
      quotationPhotos: [],
      priority: type === "Emergency" ? "Emergency" : type === "Quotation" ? "High" : "Normal",
      problemDescription: problem,
      customerBudget: amount,
      gps: { lat: 31.2 + index * 0.02, lng: 29.9 + index * 0.03 },
      city: area === "Marassi" ? "North Coast" : "Alexandria",
      media: [],
      offers: provider ? [
        { id: `demo-offer-${id}`, providerId, providerName: provider[2], price: amount, status: status === "Cancelled" && providerId === "demo-provider-tarek" ? "Expired" : "Accepted", createdAt: daysAgo(index + 1), openedAt: providerId === "demo-provider-tarek" ? null : daysAgo(index + 1), arrivalMinutes: 25 + index, completionMinutes: 90 + index * 5 },
        ...(providerId === "demo-provider-essam" ? [{ id: `demo-offer-${id}-ignored`, providerId, providerName: provider[2], price: amount + 80, status: "Pending", createdAt: daysAgo(index + 1), arrivalMinutes: 40, completionMinutes: 120 }] : []),
      ] : [
        { id: `demo-offer-${id}-ignored-essam`, providerId: "demo-provider-essam", providerName: "Essam Farouk", price: amount + 50, status: "Pending", createdAt: daysAgo(index + 1), arrivalMinutes: 30, completionMinutes: 90 },
        { id: `demo-offer-${id}-expired-tarek`, providerId: "demo-provider-tarek", providerName: "Tarek Amin", price: amount, status: "Expired", createdAt: daysAgo(index + 1), arrivalMinutes: 55, completionMinutes: 120 },
        { id: `demo-offer-${id}-rejected-sherif`, providerId: "demo-provider-sherif", providerName: "Sherif Mostafa", price: amount - 40, status: "Rejected", createdAt: daysAgo(index + 1), openedAt: daysAgo(index + 1), arrivalMinutes: 50, completionMinutes: 150 },
      ],
      providersReceived: 4,
      providersOpened: 3,
      messages: [],
      calls: [],
      payment: {
        method: index === 1 ? "Instapay" : "Customer wallet",
        status: paymentStatus,
        amount,
        servicePrice: Number(service[3]) + emergencyFee,
        customerOfferPrice: amount,
        acceptedProviderOfferPrice: amount,
        platformCommission: amount * 0.18,
        providerEarnings: amount * 0.82,
        discount: index === 2 ? 100 : 0,
        promoCode: index === 2 ? "DEMO100" : "",
        walletAmount: paymentStatus === "Paid" ? amount : 0,
        cardAmount: 0,
        instapayAmount: index === 1 ? amount : 0,
        refundAmount: paymentStatus === "Refunded" ? amount : 0,
        outstandingAmount: paymentStatus === "Pending" ? amount : 0,
        transactionId: `demo-txn-${id}`,
      },
      cancellation: status === "Cancelled" ? {
        cancelledAt: daysAgo(1),
        cancelledBy: providerId === "demo-provider-sherif" || providerId === "demo-provider-tarek" ? "Provider" : "Customer",
        reason: providerId === "demo-provider-tarek" ? "Provider ignored offer until expiry" : providerId === "demo-provider-sherif" ? "Provider missed appointment" : "Provider delayed",
        stage: providerId === "demo-provider-tarek" ? "before offers" : "provider on the way",
        refundStatus: "Refunded",
        followUpStatus: "Contacted",
        followUpNotes: ["Support offered apology promo."],
      } : null,
    });
  });

  const transactions: Array<[string, string, string, string, number, string, string]> = [
    ["demo-txn-wallet-credit", "Wallet credit", "Mariam El-Sayed", "demo-customer-mariam", 1000, "Card", "Completed"],
    ["demo-txn-job-paid", "Job payment", "Nadine Fouad", "demo-job-completed", 750, "Wallet", "Completed"],
    ["demo-txn-refund", "Customer refund", "Youssef Mansour", "demo-job-cancelled", 360, "Wallet", "Completed"],
    ["demo-txn-payout", "Provider payout", "Ahmed Nabil", "demo-provider-ahmed", 800, "Instapay", "Pending"],
  ];
  transactions.forEach(([id, type, party, ownerId, amount, method, status]) =>
    set("transactions", id, { type, party, ownerId, amount, method, status, reference: id, createdAt: daysAgo(1) }),
  );

  set("payouts", "demo-payout-ahmed", { providerId: "demo-provider-ahmed", providerName: "Ahmed Nabil", amount: 800, method: "Instapay", status: "Pending", createdAt: now() });
  set("instapayReviews", "demo-instapay-review", { customerId: "demo-customer-omar", customerName: "Omar Hassan", customerPhone: "+201090001002", jobId: "demo-job-pending", amount: 420, proofUrl: "/task-logo.svg", senderAccount: "+201090001002", transferReference: "INST-DEMO-4821", submittedAt: now(), status: "Needs review" });
  set("complaints", "demo-complaint-delay", { title: "Provider arrival delay", description: "Customer cancelled after provider missed ETA.", customerId: "demo-customer-youssef", providerId: "demo-provider-mahmoud", jobId: "demo-job-cancelled", customer: "Youssef Mansour", severity: "Medium", status: "Investigating", owner: "Demo Support", age: "1 day", notes: ["Customer contacted by WhatsApp."], evidence: [], createdAt: daysAgo(1) });
  set("complaints", "demo-complaint-sherif-1", { title: "Repeated missed appointment", description: "Technician missed appointment and did not answer customer messages.", customerId: "demo-customer-omar", providerId: "demo-provider-sherif", jobId: "demo-job-sherif-complaint-2", customer: "Omar Hassan", severity: "High", status: "Investigating", owner: "Demo Safety", age: "2 days", notes: ["Counted toward suspension threshold."], evidence: [], createdAt: daysAgo(2) });
  set("complaints", "demo-complaint-sherif-2", { title: "Poor repair quality", description: "Customer reported unfinished pipe repair and requested refund.", customerId: "demo-customer-mariam", providerId: "demo-provider-sherif", jobId: "demo-job-sherif-complaint-1", customer: "Mariam El-Sayed", severity: "Critical", status: "New", owner: "Demo Safety", age: "1 day", notes: ["Refund review required."], evidence: [], createdAt: daysAgo(1) });
  set("complaints", "demo-complaint-essam-risk", { title: "Provider ignored repeated offers", description: "Excellent customer rating, but provider ignored multiple high-value requests in 48 hours.", customerId: "demo-customer-nadine", providerId: "demo-provider-essam", jobId: "demo-job-low-acceptance", customer: "Nadine Fouad", severity: "Medium", status: "Monitoring", owner: "Demo Operations", age: "3 days", notes: ["High rating but low acceptance risk pattern."], evidence: [], createdAt: daysAgo(3) });
  set("reviews", "demo-review-ahmed-5", { providerId: "demo-provider-ahmed", customerId: "demo-customer-mariam", customerName: "Mariam El-Sayed", jobId: "demo-job-active", rating: 5, comment: "Fast, polite, and fixed the breaker issue cleanly.", pictures: [], adminNotes: [], status: "Approved", createdAt: daysAgo(1) });
  set("reviews", "demo-review-karim-5", { providerId: "demo-provider-karim", customerId: "demo-customer-nadine", customerName: "Nadine Fouad", jobId: "demo-job-completed", rating: 5, comment: "Excellent AC diagnosis and very professional.", pictures: [], adminNotes: ["Top quality signal."], status: "Approved", createdAt: daysAgo(2) });
  set("reviews", "demo-review-essam-5-risk", { providerId: "demo-provider-essam", customerId: "demo-customer-nadine", customerName: "Nadine Fouad", jobId: "demo-job-essam-risk", rating: 5, comment: "Very skilled technician, but hard to book recently.", pictures: [], adminNotes: ["Great reviews but high ignored-offer risk."], status: "Approved", createdAt: daysAgo(3) });
  set("reviews", "demo-review-sherif-1", { providerId: "demo-provider-sherif", customerId: "demo-customer-mariam", customerName: "Mariam El-Sayed", jobId: "demo-job-sherif-complaint-1", rating: 1, comment: "Repair was unfinished and I needed a refund.", pictures: [], adminNotes: ["Linked to critical complaint."], status: "Pending", createdAt: daysAgo(1) });
  set("reviews", "demo-review-sherif-2", { providerId: "demo-provider-sherif", customerId: "demo-customer-omar", customerName: "Omar Hassan", jobId: "demo-job-sherif-complaint-2", rating: 2, comment: "Technician missed the appointment and did not call.", pictures: [], adminNotes: [], status: "Visible", createdAt: daysAgo(2) });
  set("conversations", "demo-support-ticket", { subject: "Follow up on cancelled plumbing request", customerId: "demo-customer-youssef", providerId: "demo-provider-mahmoud", jobId: "demo-job-cancelled", status: "Open", priority: "High", assignedAdminId: actor?.id ?? "demo-admin", messages: [{ id: "demo-msg-1", senderType: "customer", senderId: "demo-customer-youssef", senderName: "Youssef Mansour", text: "Can someone help me rebook for tomorrow?", attachments: [], sentAt: now(), delivered: true, read: false, edited: false, deleted: false, flagged: false }], createdAt: daysAgo(1), updatedAt: now() });
  set("promos", "demo-promo-apology", { code: "DEMO100", description: "Apology credit for delayed provider arrival", discountType: "fixed", discount: 100, maxUses: 100, used: 12, startsAt: daysAgo(3), endsAt: daysAhead(14), enabled: true });
  set("notifications", "demo-notification-weather", { title: "North Coast high demand", body: "AC and plumbing requests are currently trending in Marassi.", audience: "All providers", status: "Sent", createdAt: now() });
  const demoIntegrations: Array<[string, string, string, string, boolean, string]> = [
    ["demo-gemini", "AI Providers", "gemini", "Gemini", true, "success"],
    ["demo-openai", "AI Providers", "openai", "OpenAI", false, "untested"],
    ["demo-resend", "Email", "resend", "Resend", true, "success"],
    ["demo-google-maps", "Maps / Location", "google-maps", "Google Maps", true, "success"],
    ["demo-paymob", "Payments", "paymob", "Paymob", false, "untested"],
  ];
  demoIntegrations.forEach(([id, category, provider, providerName, enabled, status]) =>
    set("apiIntegrations", id, {
      category,
      provider,
      providerName,
      defaultModel: provider === "gemini" ? "gemini-3.5-flash" : provider === "openai" ? "gpt-4.1-mini" : "",
      baseUrl: "",
      mode: "sandbox",
      enabled,
      status,
      maskedCredentials: enabled ? { apiKey: "DEMO-****1234" } : {},
      lastSuccessfulTest: enabled ? now() : "",
      lastError: "",
      updatedAt: now(),
      updatedBy: actor?.id ?? "demo-admin",
    }),
  );
  set("aiReports", "demo-ai-report", { type: "executive-brief", title: "Demo operations brief", summary: "Demo workspace shows healthy demand, one cancellation recovery opportunity, and pending Instapay review.", metrics: { activeJobs: 1, pendingJobs: 1, cancellationRate: 0.25 }, recommendations: ["Contact cancelled customer", "Assign plumber to pending Borg El Arab request"], generatedAt: now(), generatedBy: actor?.name ?? "Demo seed" });

  writes.push((batch) =>
    batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
      actorId: actor?.id ?? "system",
      actorName: actor?.name ?? "Demo seed",
      action: "demo.seed_reset",
      entityType: "demo_workspace",
      entityId: "default",
      detail: "Reset and seeded isolated demo workspace data.",
      environment: "demo",
      isDemoData: true,
      ipAddress: "Server",
      device: "Task Admin API",
      createdAt: now(),
    }),
  );

  await commitChunks(writes);
  return { ok: true, deleted: deletes.length, seeded: writes.length };
}
