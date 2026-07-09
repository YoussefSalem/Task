import { test, expect } from "@playwright/test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

/**
 * Full end-to-end smoke test for the production-deployed complaints flow,
 * run against the local Firebase emulator suite (not production - see
 * e2e/README.md for exactly why, and what this substitutes for).
 */
const manifest = JSON.parse(readFileSync(join(__dirname, ".manifest.json"), "utf8")) as {
  adminEmail: string;
  password: string;
  jobId: string;
  complaintId: string;
};

test("login succeeds and the dashboard loads", async ({ page }) => {
  await page.goto("/login");
  await page.locator('input[type="email"]').fill(manifest.adminEmail);
  await page.locator('input[type="password"]').fill(manifest.password);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/dashboard/, { timeout: 15_000 });
});

test("Production Read-Only badge appears", async ({ page }) => {
  await page.goto("/login");
  await page.locator('input[type="email"]').fill(manifest.adminEmail);
  await page.locator('input[type="password"]').fill(manifest.password);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/dashboard/, { timeout: 15_000 });
  await expect(page.getByText("Production Read-only")).toBeVisible();
  await expect(page.getByText("Production Write Disabled")).toBeVisible();
});

test("complaint list loads and the seeded complaint appears", async ({ page }) => {
  await page.goto("/login");
  await page.locator('input[type="email"]').fill(manifest.adminEmail);
  await page.locator('input[type="password"]').fill(manifest.password);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/dashboard/, { timeout: 15_000 });

  await page.goto("/dashboard/trust-safety");
  await expect(page.getByText("Incident cases")).toBeVisible({ timeout: 15_000 });
  // The seeded complaint's title is its category ("no_show") per
  // mapJobComplaintToComplaint in lib/firebase/repository.ts.
  // The list row shows the complaint id (not the job id) alongside the
  // category/customer/status - see the "Incident cases" row markup in
  // components/admin-dashboard.tsx's TrustPage.
  await expect(page.getByText(manifest.complaintId, { exact: false })).toBeVisible();
});

test("complaint detail opens correctly", async ({ page }) => {
  await page.goto("/login");
  await page.locator('input[type="email"]').fill(manifest.adminEmail);
  await page.locator('input[type="password"]').fill(manifest.password);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/dashboard/, { timeout: 15_000 });

  await page.goto("/dashboard/trust-safety");
  await expect(page.getByText("no_show")).toBeVisible({ timeout: 15_000 });
  await page.getByRole("button", { name: new RegExp(`Actions for ${manifest.complaintId}`) }).click();
  await page.getByRole("menuitem", { name: "View details" }).click();
  await expect(page.getByText("Timeline / audit log")).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText("Attachments / evidence")).toBeVisible();
  // The detail drawer is where the job id actually renders (dt/dd pair).
  await expect(page.getByText(manifest.jobId)).toBeVisible();
});

test("an unauthorized/blocked production write shows the disabled message", async ({ page }) => {
  await page.goto("/login");
  await page.locator('input[type="email"]').fill(manifest.adminEmail);
  await page.locator('input[type="password"]').fill(manifest.password);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/dashboard/, { timeout: 15_000 });

  await page.goto("/dashboard/trust-safety");
  await expect(page.getByText("no_show")).toBeVisible({ timeout: 15_000 });
  await page.getByRole("button", { name: new RegExp(`Actions for ${manifest.complaintId}`) }).click();
  await page.getByRole("menuitem", { name: "Close case" }).click();
  await expect(
    page.getByText("This production action is disabled until migration is approved."),
  ).toBeVisible({ timeout: 10_000 });
});

test("signed-out / unauthenticated visitor cannot reach the dashboard", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page).toHaveURL(/\/login/, { timeout: 10_000 });
});
