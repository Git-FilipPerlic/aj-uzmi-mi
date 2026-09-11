import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cert, initializeApp, type ServiceAccount } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Backend se Firebase-u predstavlja „service account" ključem. Taj ključ daje
// pun pristup bazi i zaobilazi pravila iz firestore.rules — zato je u
// .gitignore i nikad ne ide na GitHub.
const putDoKljuca = fileURLToPath(
  new URL("../service-account.json", import.meta.url),
);

/** Render „Secret Files" (tajni fajl na hostingu) stavlja fajl ovde. */
const RENDER_TAJNI_FAJL = "/etc/secrets/service-account.json";

/**
 * Na računaru ključ je u fajlu. Na hostingu fajla nema (ne ide na GitHub),
 * pa tamo ključ stiže ili kao podešavanje FIREBASE_SERVICE_ACCOUNT (ceo
 * sadržaj service-account.json), ili kao Render tajni fajl.
 */
function kljuc(): string | ServiceAccount {
  const izPodesavanja = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
  if (izPodesavanja) {
    try {
      return JSON.parse(izPodesavanja) as ServiceAccount;
    } catch {
      throw new Error("FIREBASE_SERVICE_ACCOUNT nije ispravan JSON — nalepi ceo sadržaj service-account.json.");
    }
  }
  for (const put of [putDoKljuca, RENDER_TAJNI_FAJL]) {
    if (existsSync(put)) return put;
  }
  throw new Error(
    `Nema Firebase ključa: ni ${putDoKljuca}, ni ${RENDER_TAJNI_FAJL}, ni FIREBASE_SERVICE_ACCOUNT.\n` +
      "Preuzmi ga u Firebase konzoli (Project settings → Service accounts → " +
      "Generate new private key) i sačuvaj pod imenom service-account.json.",
  );
}

const app = initializeApp({ credential: cert(kljuc()) });

/** Firestore baza (kolekcija `orders` je ista koju čita kurirska aplikacija). */
export const baza = getFirestore(app);

/** Slanje push obaveštenja (Firebase Cloud Messaging). */
export const push = getMessaging(app);
