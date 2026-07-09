import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mapRealChatMessage,
  mapRealChatThread,
  mapRealNotification,
} from "../lib/firebase/real-schema-types";

test("mapRealChatThread reads the exact real Customer App field names", () => {
  const thread = mapRealChatThread("job1", "tech1", {
    customer_id: "cust1",
    technician_name: "Sam",
    last_message: "On my way",
    last_message_at: "2026-01-01T00:00:00.000Z",
  });
  assert.equal(thread.jobId, "job1");
  assert.equal(thread.technicianId, "tech1");
  assert.equal(thread.customerId, "cust1");
  assert.equal(thread.technicianName, "Sam");
  assert.equal(thread.lastMessage, "On my way");
  assert.equal(thread.lastMessageAt, "2026-01-01T00:00:00.000Z");
});

test("mapRealChatThread defaults safely when fields are absent", () => {
  const thread = mapRealChatThread("job1", "tech1", {});
  assert.equal(thread.customerId, "");
  assert.equal(thread.lastMessage, "");
  assert.equal(thread.lastMessageAt, null);
});

test("mapRealChatMessage reads sender_id/sender_role/text/created_at", () => {
  const message = mapRealChatMessage("m1", {
    sender_id: "cust1",
    sender_role: "customer",
    text: "Hello",
    created_at: "2026-01-01T00:00:00.000Z",
  });
  assert.equal(message.id, "m1");
  assert.equal(message.senderId, "cust1");
  assert.equal(message.senderRole, "customer");
  assert.equal(message.text, "Hello");
});

test("mapRealChatMessage falls back to customer for an unrecognized sender_role rather than throwing", () => {
  const message = mapRealChatMessage("m1", { sender_role: "something-unexpected" });
  assert.equal(message.senderRole, "customer");
});

test("mapRealNotification reads the exact real Customer App field names", () => {
  const notification = mapRealNotification("n1", {
    type: "message",
    title: "New message",
    body: "Sam: on my way",
    actor_id: "tech1",
    job_id: "job1",
    thread_id: "tech1",
    read: false,
    created_at: "2026-01-01T00:00:00.000Z",
  });
  assert.equal(notification.type, "message");
  assert.equal(notification.title, "New message");
  assert.equal(notification.actorId, "tech1");
  assert.equal(notification.jobId, "job1");
  assert.equal(notification.threadId, "tech1");
  assert.equal(notification.read, false);
});

test("mapRealNotification falls back to job_status for an unrecognized type rather than throwing", () => {
  const notification = mapRealNotification("n1", { type: "something-unexpected" });
  assert.equal(notification.type, "job_status");
});

test("mapRealNotification treats absent optional fields as null, not undefined or missing", () => {
  const notification = mapRealNotification("n1", { type: "offer", title: "x", body: "y" });
  assert.equal(notification.actorId, null);
  assert.equal(notification.jobId, null);
  assert.equal(notification.threadId, null);
});
