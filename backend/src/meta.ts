// Messenger i Instagram (Meta). Obe mreže šalju poruke na isti „webhook" u
// istom obliku, a odgovor ide preko istog Send API-ja — zato su u jednom
// fajlu. Za izbor kanala i razloge vidi CLAUDE.md, odeljak 7.
//
// Ključevi (u backend/.env, ne na GitHub):
//   META_VERIFY_TOKEN — reč koju izmisliš i upišeš i u Meta podešavanja
//   META_APP_SECRET   — „App secret" Meta aplikacije (za proveru potpisa)
//   META_PAGE_TOKEN   — ključ Facebook stranice (za slanje odgovora)

import { createHmac, timingSafeEqual } from "node:crypto";

/** Verzija Meta Graph API-ja; proveriti da je još podržana kad se poveže. */
const GRAPH = "https://graph.facebook.com/v23.0";

/** Messenger ne prima duže poruke od ovoga. */
const NAJDUZA_PORUKA = 2000;

export type MetaKanal = "messenger" | "instagram";

/** Jedna pristigla poruka mušterije, izvučena iz Meta obaveštenja. */
export type MetaPoruka = {
  kanal: MetaKanal;
  /** Meta-in broj mušterije — na njega ide odgovor. */
  posiljalac: string;
  /** Oznaka poruke; Meta ponekad pošalje istu poruku dvaput. */
  mid: string;
  tekst: string;
  /** Adrese glasovnih poruka (zvučni fajlovi). */
  zvuk: string[];
  /** Koliko je stiglo drugih priloga (slike, video...) — za sad se ne čitaju. */
  drugiPrilozi: number;
};

/**
 * Da li je poruku stvarno poslala Meta. Meta potpisuje svaku poruku tajnim
 * ključem aplikacije; bez ove provere bilo ko bi mogao da šalje lažne
 * porudžbine na našu adresu.
 */
export function potpisValja(teloPoruke: Buffer, zaglavlje: string | undefined, tajna: string): boolean {
  if (!tajna || !zaglavlje?.startsWith("sha256=")) return false;
  const ocekivano = createHmac("sha256", tajna).update(teloPoruke).digest();
  const dobijeno = Buffer.from(zaglavlje.slice("sha256=".length), "hex");
  return dobijeno.length === ocekivano.length && timingSafeEqual(dobijeno, ocekivano);
}

function tekstIli(v: unknown): string {
  return typeof v === "string" ? v : "";
}

/**
 * Izvlači poruke mušterija iz onoga što Meta pošalje. Sve što nije poruka
 * mušterije (potvrde čitanja, naši sopstveni odgovori — „echo") se preskače.
 * Na neispravnom ili praznom telu vraća praznu listu, nikad ne puca.
 */
export function izvuciPoruke(telo: unknown): MetaPoruka[] {
  const t = (telo ?? {}) as { object?: unknown; entry?: unknown };
  const kanal: MetaKanal | null =
    t.object === "page" ? "messenger" : t.object === "instagram" ? "instagram" : null;
  if (!kanal || !Array.isArray(t.entry)) return [];

  const poruke: MetaPoruka[] = [];
  for (const unos of t.entry) {
    const dogadjaji = (unos as { messaging?: unknown })?.messaging;
    if (!Array.isArray(dogadjaji)) continue;

    for (const d of dogadjaji) {
      const posiljalac = tekstIli(d?.sender?.id);
      const poruka = d?.message;
      if (!posiljalac || !poruka || poruka.is_echo) continue;

      const prilozi: unknown[] = Array.isArray(poruka.attachments) ? poruka.attachments : [];
      const zvuk = prilozi
        .filter((p) => (p as { type?: unknown })?.type === "audio")
        .map((p) => tekstIli((p as { payload?: { url?: unknown } })?.payload?.url))
        .filter((url) => url.length > 0);

      poruke.push({
        kanal,
        posiljalac,
        mid: tekstIli(poruka.mid),
        tekst: tekstIli(poruka.text).trim(),
        zvuk,
        drugiPrilozi: prilozi.length - zvuk.length,
      });
    }
  }
  return poruke;
}

/** Deli dug odgovor na delove koje Messenger prima, po razmacima. */
export function podeli(tekst: string, najvise = NAJDUZA_PORUKA): string[] {
  const delovi: string[] = [];
  let ostatak = tekst.trim();
  while (ostatak.length > najvise) {
    let rez = ostatak.lastIndexOf(" ", najvise);
    if (rez <= 0) rez = najvise;
    delovi.push(ostatak.slice(0, rez).trim());
    ostatak = ostatak.slice(rez).trim();
  }
  if (ostatak) delovi.push(ostatak);
  return delovi;
}

/**
 * Šalje odgovor mušteriji. Bez META_PAGE_TOKEN radi „na suvo": odgovor samo
 * ispiše u terminal — tako se prijemnica proba na računaru pre nego što
 * postoji Facebook stranica.
 */
export async function posaljiOdgovor(primalac: string, tekst: string): Promise<void> {
  const token = process.env.META_PAGE_TOKEN?.trim();
  if (!token) {
    console.log(`[na suvo — nema META_PAGE_TOKEN] → ${primalac}:\n${tekst}\n`);
    return;
  }
  for (const deo of podeli(tekst)) {
    const odgovor = await fetch(`${GRAPH}/me/messages`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        recipient: { id: primalac },
        messaging_type: "RESPONSE",
        message: { text: deo },
      }),
    });
    if (!odgovor.ok) {
      throw new Error(`Meta nije primila odgovor (${odgovor.status}): ${await odgovor.text()}`);
    }
  }
}
