import { test } from "node:test";
import assert from "node:assert/strict";
import { mapJobComplaintToComplaint } from "../lib/firebase/repository";

test("maps real jobs/{jobId}/complaints fields into the Complaint shape", () => {
  const complaint = mapJobComplaintToComplaint("c1", "job42", {
    raised_by: "customer",
    reporter_id: "cust1",
    subject_id: "tech1",
    category: "no_show",
    description: "Technician never arrived.",
    status: "open",
    evidence: ["https://example.com/photo.jpg"],
    created_at: "2026-01-01T00:00:00.000Z",
  });
  assert.equal(complaint.id, "c1");
  assert.equal(complaint.jobId, "job42");
  assert.equal(complaint.title, "no_show");
  assert.equal(complaint.description, "Technician never arrived.");
  assert.equal(complaint.customerId, "cust1");
  assert.equal(complaint.providerId, "tech1");
  assert.equal(complaint.status, "New");
  assert.deepEqual(complaint.evidence, ["https://example.com/photo.jpg"]);
  assert.equal(complaint.environment, "production");
  assert.equal(complaint.isDemoData, false);
});

test("jobId comes from the document path, not a trusted field", () => {
  const complaint = mapJobComplaintToComplaint("c1", "the-real-job-id", {
    raised_by: "customer",
    reporter_id: "cust1",
  });
  assert.equal(complaint.jobId, "the-real-job-id");
});

test("technician-raised complaints swap customerId/providerId correctly", () => {
  const complaint = mapJobComplaintToComplaint("c1", "job1", {
    raised_by: "technician",
    reporter_id: "tech1",
    subject_id: "cust1",
  });
  assert.equal(complaint.providerId, "tech1");
  assert.equal(complaint.customerId, "cust1");
});

test("maps status: investigating/resolved/closed to the dashboard's status vocabulary", () => {
  assert.equal(mapJobComplaintToComplaint("c1", "j1", { status: "investigating" }).status, "Investigating");
  assert.equal(mapJobComplaintToComplaint("c1", "j1", { status: "resolved" }).status, "Closed");
  assert.equal(mapJobComplaintToComplaint("c1", "j1", { status: "closed" }).status, "Closed");
  assert.equal(mapJobComplaintToComplaint("c1", "j1", { status: "open" }).status, "New");
});

test("defaults safely when fields are absent", () => {
  const complaint = mapJobComplaintToComplaint("c1", "j1", {});
  assert.equal(complaint.status, "New");
  assert.deepEqual(complaint.evidence, []);
  assert.deepEqual(complaint.notes, []);
});

test("resolution_note, when present, surfaces as a note", () => {
  const complaint = mapJobComplaintToComplaint("c1", "j1", { resolution_note: "Refunded in full." });
  assert.deepEqual(complaint.notes, ["Refunded in full."]);
});
