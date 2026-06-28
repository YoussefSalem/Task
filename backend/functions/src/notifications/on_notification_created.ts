import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging, MulticastMessage} from "firebase-admin/messaging";
import {logger} from "firebase-functions/v2";

/**
 * Server-side push fan-out.
 *
 * The acting client writes a notification document straight into the
 * recipient's in-app feed (`users/{uid}/notifications/{id}`) — that drives the
 * live feed and the unread badge. This trigger piggybacks on that write: it
 * reads the recipient's registered FCM tokens
 * (`users/{uid}/fcm_tokens/{token}`) and delivers the same payload as a push so
 * the user is reachable when the app is backgrounded or closed.
 *
 * Tokens that the FCM service reports as permanently invalid are pruned so the
 * collection does not accumulate dead devices.
 */
export const onNotificationCreated = onDocumentCreated(
  "users/{uid}/notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const uid = event.params.uid;
    const n = snap.data() as {
      title?: string;
      body?: string;
      type?: string;
      job_id?: string | null;
      thread_id?: string | null;
      actor_id?: string | null;
    };

    const db = getFirestore();
    const tokensSnap = await db
      .collection("users")
      .doc(uid)
      .collection("fcm_tokens")
      .get();

    if (tokensSnap.empty) {
      logger.debug(`No FCM tokens for ${uid}; skipping push.`);
      return;
    }

    const tokens = tokensSnap.docs.map((d) => d.id);

    // Data payload mirrors the feed fields so the client can route a tap. All
    // FCM data values must be strings.
    const data: Record<string, string> = {type: n.type ?? "job_status"};
    if (n.job_id) data.job_id = n.job_id;
    if (n.thread_id) data.thread_id = n.thread_id;
    if (n.actor_id) data.actor_id = n.actor_id;

    const message: MulticastMessage = {
      tokens,
      notification: {
        title: n.title ?? "",
        body: n.body ?? "",
      },
      data,
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    };

    const response = await getMessaging().sendEachForMulticast(message);

    // Prune tokens FCM reports as permanently unregistered/invalid.
    const stale: string[] = [];
    response.responses.forEach((r, i) => {
      if (r.success) return;
      const code = r.error?.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        stale.push(tokens[i]);
      }
    });

    if (stale.length > 0) {
      const batch = db.batch();
      const col = db.collection("users").doc(uid).collection("fcm_tokens");
      stale.forEach((t) => batch.delete(col.doc(t)));
      await batch.commit();
      logger.info(`Pruned ${stale.length} stale token(s) for ${uid}.`);
    }

    logger.info(
      `Push to ${uid}: ${response.successCount} sent, ` +
        `${response.failureCount} failed.`
    );
  }
);
