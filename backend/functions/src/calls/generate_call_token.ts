import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

const livekitApiKey = defineSecret("LIVEKIT_API_KEY");
const livekitApiSecret = defineSecret("LIVEKIT_API_SECRET");
const livekitWsUrl = defineSecret("LIVEKIT_WS_URL");

export const generateCallToken = onCall(
  {
    enforceAppCheck: true,
    secrets: [livekitApiKey, livekitApiSecret, livekitWsUrl],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const data = request.data as {offerId?: unknown};
    const offerId = data.offerId;
    if (typeof offerId !== "string" || offerId.trim() === "") {
      throw new HttpsError("invalid-argument", "offerId is required.");
    }

    const identity = request.auth.uid;

    // Dynamic import required: livekit-server-sdk v2 is ESM-only; functions use CommonJS.
    const {AccessToken} = await import("livekit-server-sdk");

    const token = new AccessToken(
      livekitApiKey.value(),
      livekitApiSecret.value(),
      {
        identity,
        ttl: 60 * 60 * 2, // 2 hours
      }
    );

    token.addGrant({
      roomJoin: true,
      room: offerId.trim(),
      canPublish: true,
      canSubscribe: true,
    });

    return {
      token: await token.toJwt(),
      wsUrl: livekitWsUrl.value(),
    };
  }
);
