import { test } from "node:test";
import assert from "node:assert/strict";
import { mapPromotionToBanner } from "../lib/firebase/repository";

test("maps real promotions fields into the Banner shape", () => {
  const banner = mapPromotionToBanner("promo1", {
    headline: "Summer Sale",
    subtitle: "20% off all bookings",
    active: true,
    order: 3,
    created_at: "2026-01-01T00:00:00.000Z",
  });
  assert.equal(banner.id, "promo1");
  assert.equal(banner.title, "Summer Sale");
  assert.equal(banner.subtitle, "20% off all bookings");
  assert.equal(banner.sortOrder, 3);
  assert.equal(banner.enabled, true);
  assert.equal(banner.environment, "production");
  assert.equal(banner.isDemoData, false);
});

test("leaves imageUrl empty rather than guessing - the real schema has no image field", () => {
  const banner = mapPromotionToBanner("promo2", { headline: "x", subtitle: "y" });
  assert.equal(banner.imageUrl, "");
  assert.equal(banner.actionUrl, undefined);
});

test("defaults active/order/dates safely when absent", () => {
  const banner = mapPromotionToBanner("promo3", {});
  assert.equal(banner.enabled, true);
  assert.equal(banner.sortOrder, 0);
  assert.equal(banner.title, "");
  assert.equal(banner.subtitle, "");
});

test("active:false disables the banner", () => {
  const banner = mapPromotionToBanner("promo4", { headline: "z", active: false });
  assert.equal(banner.enabled, false);
});
