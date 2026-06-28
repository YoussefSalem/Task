/**
 * Seeds the `promotions` collection read by the customer home hero carousel.
 *
 * Promotions are admin-managed marketing content. The customer app hides the
 * carousel entirely when this collection is empty, so seeding is optional — run
 * it when you want banners to appear.
 *
 * Usage:
 *   1. Download a service account key from
 *      Firebase Console → Project settings → Service accounts → Generate key.
 *   2. GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json \
 *        node backend/scripts/seed_promotions.mjs
 *
 * Re-running is safe: documents are upserted by their fixed ids.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp({credential: applicationDefault()});
const db = getFirestore();

// accent_hex drives the card gradient; icon_name maps to a glyph in the app
// (ac, cleaning, gift, bolt, plumbing, offer).
const promotions = [
  {
    id: "referral",
    headline: "Refer & earn",
    subtitle: "Share your code — you both get Task credit on the first booking.",
    badge: "New",
    accent_hex: "#8B5CF6",
    icon_name: "gift",
    order: 1,
    active: true,
  },
  {
    id: "ac-season",
    headline: "Beat the heat",
    subtitle: "Book a full AC service and clean before summer peaks.",
    badge: "Seasonal",
    accent_hex: "#0EA5E9",
    icon_name: "ac",
    order: 2,
    active: true,
  },
  {
    id: "deep-clean",
    headline: "Whole-home deep clean",
    subtitle: "Vetted cleaning pros for a spotless home, top to bottom.",
    accent_hex: "#10B981",
    icon_name: "cleaning",
    order: 3,
    active: true,
  },
];

const run = async () => {
  const batch = db.batch();
  for (const {id, ...data} of promotions) {
    batch.set(
      db.collection("promotions").doc(id),
      {...data, updated_at: FieldValue.serverTimestamp()},
      {merge: true}
    );
  }
  await batch.commit();
  console.log(`Seeded ${promotions.length} promotions.`);
};

run().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
