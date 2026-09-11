import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cert, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Backend se Firebase-u predstavlja „service account" ključem. Taj ključ daje
// pun pristup bazi i zaobilazi pravila iz firestore.rules — zato je u
// .gitignore i nikad ne ide na GitHub.
const putDoKljuca = fileURLToPath(
  new URL("../service-account.json", import.meta.url),
);

if (!existsSync(putDoKljuca)) {
  throw new Error(
    `Nema Firebase ključa: ${putDoKljuca}\n` +
      "Preuzmi ga u Firebase konzoli (Project settings → Service accounts → " +
      "Generate new private key) i sačuvaj pod imenom service-account.json.",
  );
}

const app = initializeApp({ credential: cert(putDoKljuca) });

/** Firestore baza (kolekcija `orders` je ista koju čita kurirska aplikacija). */
export const baza = getFirestore(app);

/** Slanje push obaveštenja (Firebase Cloud Messaging). */
export const push = getMessaging(app);
