// Glasovna poruka → tekst, preko Groq-a (Whisper Large v3). Claude zvuk ne
// prima, pa ovaj korak ide pre agenta. Besplatno, bez kartice (CLAUDE.md,
// odeljak 3). Ključ: GROQ_API_KEY u backend/.env.

const GROQ = "https://api.groq.com/openai/v1/audio/transcriptions";

/** Groq ne prima veće fajlove od ovoga. */
const NAJVECI_ZVUK = 25 * 1024 * 1024;

/**
 * Nagoveštaj za prepis: latinica i imena ulica i radnji iz komšiluka, da ih
 * Whisper napiše kako treba (inače srpski često piše ćirilicom).
 */
const NAGOVESTAJ =
  "Aj uzmi mi — dostava u Šarengradu. Mileve Marić, Momčila Tapavice, Stanoja Stanojevića. Svetofor, Mali Kvantaš, hleb, mleko, jaja.";

export type Prepis = { tekst: string } | { greska: string };

const LATINICA: Record<string, string> = {
  а: "a", б: "b", в: "v", г: "g", д: "d", ђ: "đ", е: "e", ж: "ž", з: "z", и: "i",
  ј: "j", к: "k", л: "l", љ: "lj", м: "m", н: "n", њ: "nj", о: "o", п: "p", р: "r",
  с: "s", т: "t", ћ: "ć", у: "u", ф: "f", х: "h", ц: "c", ч: "č", џ: "dž", ш: "š",
};

/**
 * Ćirilica → latinica. Whisper srpski često piše ćirilicom i uprkos
 * nagoveštaju, a agent, provera zone i kurir rade na latinici. Srpska
 * ćirilica se prevodi slovo po slovo, pa ne treba nikakav paket.
 */
export function uLatinicu(tekst: string): string {
  return [...tekst]
    .map((slovo) => {
      const malo = slovo.toLowerCase();
      const lat = LATINICA[malo];
      if (lat === undefined) return slovo;
      if (slovo === malo) return lat;
      return lat.charAt(0).toUpperCase() + lat.slice(1); // „Љ" → „Lj"
    })
    .join("");
}

/** Nastavak imena fajla po vrsti zvuka — Groq po njemu prepoznaje format. */
export function nastavak(vrsta: string | null): string {
  const v = (vrsta ?? "").toLowerCase();
  if (v.includes("mpeg") || v.includes("mp3")) return "mp3";
  if (v.includes("ogg")) return "ogg";
  if (v.includes("wav")) return "wav";
  if (v.includes("webm")) return "webm";
  if (v.includes("aac")) return "m4a";
  return "mp4"; // Messenger i Instagram šalju glas kao mp4
}

/**
 * Preuzima glasovnu poruku sa adrese i vraća prepis. Nikad ne baca grešku
 * zbog loše poruke — vraća razlog, pa prijemnica mušteriji kaže da napiše.
 */
export async function prepisi(adresa: string): Promise<Prepis> {
  const kljuc = process.env.GROQ_API_KEY?.trim();
  if (!kljuc) return { greska: "Nema GROQ_API_KEY — glasovne poruke se još ne prepisuju." };
  if (!adresa.trim()) return { greska: "Glasovna poruka nema adresu." };

  const zvuk = await fetch(adresa);
  if (!zvuk.ok) return { greska: `Glasovna poruka nije preuzeta (${zvuk.status}).` };
  const podaci = await zvuk.arrayBuffer();
  if (podaci.byteLength === 0) return { greska: "Glasovna poruka je prazna." };
  if (podaci.byteLength > NAJVECI_ZVUK) return { greska: "Glasovna poruka je preduga." };

  const vrsta = zvuk.headers.get("content-type");
  const forma = new FormData();
  forma.append("file", new Blob([podaci], { type: vrsta ?? "audio/mp4" }), `glas.${nastavak(vrsta)}`);
  forma.append("model", "whisper-large-v3");
  forma.append("language", "sr");
  forma.append("prompt", NAGOVESTAJ);
  forma.append("response_format", "json");

  const odgovor = await fetch(GROQ, {
    method: "POST",
    headers: { Authorization: `Bearer ${kljuc}` },
    body: forma,
  });
  if (!odgovor.ok) {
    return { greska: `Groq nije prepisao poruku (${odgovor.status}): ${await odgovor.text()}` };
  }
  const rezultat = (await odgovor.json()) as { text?: unknown };
  const tekst = typeof rezultat.text === "string" ? uLatinicu(rezultat.text.trim()) : "";
  return tekst ? { tekst } : { greska: "U glasovnoj poruci se ništa ne čuje." };
}
