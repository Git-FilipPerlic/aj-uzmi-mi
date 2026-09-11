// Kilometri od radnje do mušterije, po ulicama, rutom za bicikl.
// Koristi OpenRouteService (ključ ORS_API_KEY u .env). Za izbor usluge i
// razloge vidi CLAUDE.md, odeljak „Faza 1".

import { poznataRadnja } from "./radnje.js";
import { sredi } from "./zona.js";

const ORS = "https://api.openrouteservice.org";

/** Centar Novog Sada: pretraga adresa daje prednost rezultatima blizu njega. */
const NOVI_SAD = { lon: 19.8335, lat: 45.2671 };

type Tacka = [lon: number, lat: number];

function kljuc(): string {
  const k = process.env.ORS_API_KEY?.trim();
  if (!k) {
    throw new Error("Nema ORS ključa: upiši ORS_API_KEY u backend/.env.");
  }
  return k;
}

/** Dovoljno tačni pogoci: kućni broj, ulica ili radnja. Grad, selo ili kraj nisu. */
const TACNI_SLOJEVI = new Set(["address", "street", "venue"]);

/** Reči koje ne kažu koja je ulica — „Ulica heroja" ne sme da prođe samo zbog reči „ulica". */
const OPSTE_RECI = new Set(["ulica", "bulevar", "trg", "put", "novi", "sad"]);

/** Ono što ORS kaže o jednom pogotku (polje `properties`). */
export type Pogodak = { layer?: string; name?: string; street?: string };

/**
 * Da li je ORS pogodio baš ono što je upisano. ORS uvek nešto vrati — za
 * „Ulica Koje Nema 999" vraća „Ulica heroja", za „Kovilj mesara" selo Kovilj.
 * Zato: pogodak mora biti ulica/kućni broj/radnja, i svaka prava reč
 * njegovog imena mora postojati u upisanoj adresi.
 */
export function tacanPogodak(unos: string, p: Pogodak): boolean {
  if (!p.layer || !TACNI_SLOJEVI.has(p.layer)) return false;
  // Kod kućnog broja ime je „11 Bulevar Oslobođenja", pa se gleda samo ulica.
  const ime = p.layer === "address" ? p.street : p.name;
  const reci = sredi(ime ?? "")
    .split(" ")
    .filter((r) => r.length > 1 && !/^\d+$/.test(r) && !OPSTE_RECI.has(r));
  if (reci.length === 0) return false;
  const upisano = sredi(unos).split(" ");
  return reci.every((r) => upisano.includes(r));
}

/** Adresa → koordinate. Vraća `null` ako tačna adresa nije pronađena. */
async function nadjiAdresu(adresa: string): Promise<Tacka | null> {
  const upit = new URLSearchParams({
    api_key: kljuc(),
    text: adresa,
    "boundary.country": "RS",
    "focus.point.lon": String(NOVI_SAD.lon),
    "focus.point.lat": String(NOVI_SAD.lat),
    size: "5",
  });
  const odgovor = await fetch(`${ORS}/geocode/search?${upit}`);
  if (!odgovor.ok) {
    throw new Error(`ORS pretraga adrese nije uspela (${odgovor.status}).`);
  }
  const podaci = (await odgovor.json()) as {
    features?: { geometry?: { coordinates?: number[] }; properties?: Pogodak }[];
  };
  // Prvi od pet ponuđenih koji je stvarno ono što je upisano.
  const nadjen = (podaci.features ?? []).find((f) => tacanPogodak(adresa, f.properties ?? {}));
  const k = nadjen?.geometry?.coordinates;
  return k && k.length >= 2 ? [k[0]!, k[1]!] : null;
}

/** Rezultat merenja: kilometri, ili razlog zašto nije moglo da se izmeri. */
export type Merenje =
  | { km: number }
  | { greska: string };

/**
 * Kilometri po ulicama od radnje do mušterije (bicikl).
 * Nikad ne baca grešku zbog loše adrese — vraća poruku koju agent može da
 * prenese mušteriji („ne mogu da nađem tu adresu").
 */
export async function kilometri(odRadnje: string, doMusterije: string): Promise<Merenje> {
  const od = odRadnje.trim();
  const do_ = doMusterije.trim();
  if (!od) return { greska: "Nije rečeno iz koje radnje." };
  if (!do_) return { greska: "Nije rečena adresa mušterije." };

  // Poznate radnje imaju tačno mesto u spisku; ostale se traže na mapi.
  const poznata = poznataRadnja(od);
  const [a, b] = await Promise.all([
    poznata ? ([poznata.lon, poznata.lat] as Tacka) : nadjiAdresu(od),
    nadjiAdresu(do_),
  ]);
  if (!a) return { greska: `Ne mogu da nađem adresu radnje: „${od}".` };
  if (!b) return { greska: `Ne mogu da nađem adresu mušterije: „${do_}".` };

  const odgovor = await fetch(`${ORS}/v2/directions/cycling-regular`, {
    method: "POST",
    headers: { Authorization: kljuc(), "Content-Type": "application/json" },
    body: JSON.stringify({ coordinates: [a, b] }),
  });
  if (!odgovor.ok) {
    return { greska: `ORS nije mogao da izračuna rutu (${odgovor.status}).` };
  }
  const podaci = (await odgovor.json()) as {
    routes?: { summary?: { distance?: number } }[];
  };
  const metri = podaci.routes?.[0]?.summary?.distance;
  if (typeof metri !== "number") {
    return { greska: "ORS nije vratio dužinu rute." };
  }
  return { km: Math.round(metri / 100) / 10 };
}
