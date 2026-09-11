// Prijemnica: javna adresa na koju Meta šalje poruke sa Messengera i
// Instagrama. Svaka mušterija ima svoj razgovor sa istim „mozgom" (agent.ts).
// Pokretanje: npm run server   (na računaru radi „na suvo", vidi meta.ts)

import Anthropic from "@anthropic-ai/sdk";
import { existsSync } from "node:fs";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { Razgovor } from "./agent.js";
import { prepisi } from "./glas.js";
import { izvuciPoruke, posaljiOdgovor, potpisValja, type MetaPoruka } from "./meta.js";

// Na računaru ključevi stoje u backend/.env; na hostingu ih daje sam hosting.
const envFajl = new URL("../.env", import.meta.url);
if (existsSync(envFajl)) process.loadEnvFile(envFajl);

const PORT = Number(process.env.PORT) || 3000;
const NAJVECE_TELO = 1_000_000;

const claude = new Anthropic();

/**
 * Razgovori po mušteriji. Za sad samo u memoriji — posle restarta servera
 * razgovor počinje ispočetka (porudžbine su svakako u bazi).
 */
const razgovori = new Map<string, Razgovor>();

/** Poruke iste mušterije se obrađuju redom, jedna po jedna. */
const redovi = new Map<string, Promise<void>>();

/** Meta ponekad pošalje istu poruku dvaput — pamte se poslednje oznake. */
const vidjene = new Set<string>();

function vecViđena(mid: string): boolean {
  if (!mid) return false;
  if (vidjene.has(mid)) return true;
  vidjene.add(mid);
  if (vidjene.size > 1000) vidjene.delete(vidjene.values().next().value!);
  return false;
}

async function odgovori(p: MetaPoruka): Promise<void> {
  const kljuc = `${p.kanal}:${p.posiljalac}`;
  let razgovor = razgovori.get(kljuc);
  if (!razgovor) {
    razgovor = new Razgovor(claude, p.kanal);
    razgovori.set(kljuc, razgovor);
  }

  // Glasovne poruke se prvo prepišu u tekst (Groq), pa idu agentu uz oznaku
  // da je to prepis — agent tada zna da u imenima može biti grešaka.
  const delovi = p.tekst ? [p.tekst] : [];
  let glasNijeProsao = false;
  for (const adresa of p.zvuk) {
    const prepis = await prepisi(adresa);
    if ("tekst" in prepis) {
      delovi.push(`[glasovna poruka] ${prepis.tekst}`);
    } else {
      console.error(`Prepis nije uspeo (${kljuc}): ${prepis.greska}`);
      glasNijeProsao = true;
    }
  }

  if (delovi.length === 0) {
    await posaljiOdgovor(
      p.posiljalac,
      glasNijeProsao
        ? "Izvini, nisam uspeo da preslušam glasovnu poruku — pošalji je ponovo ili mi napiši šta ti treba 🙂"
        : "Za sad čitam tekst i glasovne poruke — napiši mi ili izgovori šta ti treba 🙂",
    );
    return;
  }

  let tekst: string;
  try {
    tekst = await razgovor.odgovori(delovi.join("\n"));
  } catch (greska) {
    console.error(`Agent nije odgovorio (${kljuc}):`, greska);
    tekst = "Izvini, nešto mi je zapelo — pošalji mi poruku ponovo za minut.";
  }
  await posaljiOdgovor(p.posiljalac, tekst);
}

function uRed(p: MetaPoruka): void {
  if (vecViđena(p.mid)) return;
  const kljuc = `${p.kanal}:${p.posiljalac}`;
  const sledeci = (redovi.get(kljuc) ?? Promise.resolve())
    .then(() => odgovori(p))
    .catch((greska) => console.error(`Odgovor nije poslat (${kljuc}):`, greska));
  redovi.set(kljuc, sledeci);
}

function citajTelo(zahtev: IncomingMessage): Promise<Buffer | null> {
  return new Promise((resolve, reject) => {
    const delovi: Buffer[] = [];
    let ukupno = 0;
    zahtev.on("data", (deo: Buffer) => {
      ukupno += deo.length;
      if (ukupno > NAJVECE_TELO) {
        resolve(null);
        zahtev.destroy();
      } else {
        delovi.push(deo);
      }
    });
    zahtev.on("end", () => resolve(Buffer.concat(delovi)));
    zahtev.on("error", reject);
  });
}

function kraj(odgovor: ServerResponse, status: number, tekst = ""): void {
  odgovor.writeHead(status, { "Content-Type": "text/plain; charset=utf-8" });
  odgovor.end(tekst);
}

const server = createServer(async (zahtev, odgovor) => {
  const url = new URL(zahtev.url ?? "/", "http://localhost");

  try {
    // Provera živosti (hosting povremeno pita da li server radi).
    if (zahtev.method === "GET" && url.pathname === "/") {
      return kraj(odgovor, 200, "Aj uzmi mi — prijemnica radi.");
    }

    // Meta jednom proverava da je adresa naša: vraćamo broj koji je poslala,
    // ali samo ako zna našu tajnu reč (META_VERIFY_TOKEN).
    if (zahtev.method === "GET" && url.pathname === "/webhook") {
      const rec = process.env.META_VERIFY_TOKEN?.trim();
      const ok =
        !!rec &&
        url.searchParams.get("hub.mode") === "subscribe" &&
        url.searchParams.get("hub.verify_token") === rec;
      return ok ? kraj(odgovor, 200, url.searchParams.get("hub.challenge") ?? "") : kraj(odgovor, 403);
    }

    if (zahtev.method === "POST" && url.pathname === "/webhook") {
      const telo = await citajTelo(zahtev);
      if (!telo) return kraj(odgovor, 413);

      const tajna = process.env.META_APP_SECRET?.trim() ?? "";
      if (!potpisValja(telo, zahtev.headers["x-hub-signature-256"] as string | undefined, tajna)) {
        return kraj(odgovor, 403);
      }

      let podaci: unknown;
      try {
        podaci = JSON.parse(telo.toString("utf8"));
      } catch {
        return kraj(odgovor, 400);
      }

      // Meta traži brz odgovor; agent radi posle, u pozadini.
      kraj(odgovor, 200, "EVENT_RECEIVED");
      for (const p of izvuciPoruke(podaci)) uRed(p);
      return;
    }

    kraj(odgovor, 404);
  } catch (greska) {
    console.error("Greška u prijemnici:", greska);
    if (!odgovor.headersSent) kraj(odgovor, 500);
  }
});

server.listen(PORT, () => {
  console.log(`Prijemnica sluša na portu ${PORT}.`);
  for (const k of ["META_VERIFY_TOKEN", "META_APP_SECRET", "META_PAGE_TOKEN"]) {
    if (!process.env[k]?.trim()) console.log(`  (nema ${k} — vidi komentar u src/meta.ts)`);
  }
  if (!process.env.GROQ_API_KEY?.trim()) console.log("  (nema GROQ_API_KEY — glasovne poruke se ne prepisuju)");
});
