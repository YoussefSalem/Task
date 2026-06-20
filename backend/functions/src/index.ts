/**
 * Task — Cloud Functions entrypoint.
 *
 * Function modules are added per implementation phase (PRD §3):
 *   - dispatch/   ASAP sequential cascade via Google Cloud Tasks
 *   - bidding/    sealed-bid cap + expiry
 *   - scope/      scope-creep threshold routing + OTP
 *   - penalties/  no-show matrix + customer debt
 *   - payments/   Paymob webhooks, InstaPay admin approval, COD reconciliation
 *   - maintenance/ chat TTL cleanup
 *
 * App Check enforcement is mandatory on all callables (PRD §1.1).
 */
import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall} from "firebase-functions/v2/https";

initializeApp();

// Region close to the Egypt/MENA target market; configurable per environment.
setGlobalOptions({region: "europe-west1"});

/** Health check used by CI and the emulator smoke test. */
export const ping = onCall({enforceAppCheck: false}, () => {
  return {status: "ok", ts: Date.now()};
});
