// „Mozak" dispečera: razgovara sa mušterijom i sam poziva alate (cena,
// udaljenost, upis porudžbine). Isti mozak će kasnije stajati iza svih
// kanala — Viber, SMS, sajt — pa ovde nema ničega vezanog za terminal.

import Anthropic from "@anthropic-ai/sdk";
import { izracunajCenu, USLUGE, type Usluga } from "./cena.js";
import { javiKuriru, sacuvajPorudzbinu, type NovaPorudzbina } from "./porudzbine.js";
import { RADNJE } from "./radnje.js";
import { kilometri } from "./udaljenost.js";
import { ULICE_U_ZONI, uZoni } from "./zona.js";

// Sonnet, jer CLAUDE.md (odeljak 3) kaže Sonnet za razgovor.
const MODEL = "claude-sonnet-5";

const VRSTE = Object.keys(USLUGE) as Usluga[];

const UPUTSTVO = `Ti si dispečer usluge „Aj uzmi mi" u Novom Sadu — komšijska mikro-dostava biciklom. Mušterije ti pišu šta im treba, a ti od toga praviš porudžbinu za kurira.

U razgovoru:
- Saznaj šta treba kupiti, iz koje radnje (naziv i adresa ili bar deo grada), adresu dostave i ime mušterije. Ako nešto fali ili je nejasno, pitaj — jedno pitanje po poruci.
- Odredi vrstu posla po cenovniku, a cenu dobij isključivo alatom izracunaj_cenu. Cenu ne izmišljaj, ne zaokružuj i ne dogovaraj popuste — određuje je cenovnik.
- Pre upisa ukratko ponovi porudžbinu (artikli, radnja, adresa, cena) i traži potvrdu. Alat sacuvaj_porudzbinu pozovi tek kad mušterija jasno potvrdi, i samo jednom po porudžbini.

Zona dostave: dostavljamo samo na adrese u Šarengradu — ulice ${ULICE_U_ZONI.join(", ")}. Radnja može biti bilo gde. Ako je adresa dostave van zone, porudžbinu ne primaj i odgovori otprilike: „Ljubi brat, trenutno pokrivam isključivo naš Šarengrad kako bih svima stigao za 5 minuta na bajsu. Čim raširimo mrežu, javljam ti!"

Radnje u komšiluku koje kurir zna — kad mušterija traži nešto što se tu kupuje, predloži odgovarajuću. Kad je radnja sa ovog spiska, u alatima je piši tačno ovim nazivom, pa adresa (npr. „${RADNJE[0]!.naziv}, ${RADNJE[0]!.adresa}"):
${RADNJE.map((r) => `- ${r.naziv}, ${r.adresa} — ${r.vrsta}${r.napomena ? ` (${r.napomena})` : ""}`).join("\n")}
Mušterija može tražiti i radnju van ovog spiska — to je u redu, samo saznaj naziv i adresu.

Vrste posla:
${VRSTE.map((v) => `- ${v}: ${USLUGE[v].opis}`).join("\n")}

Teško je: više od 2 L tečnosti ukupno, pakovanje od 5 L, kilo krompira i više. Osetljivo je: lomljivo ili ono što ne sme da se ošteti.

Piši kratko i prijateljski, kao komšija — ljudi ovo čitaju na telefonu. Srpski, latinica.`;

const ALATI: Anthropic.Tool[] = [
  {
    name: "izracunaj_cenu",
    description:
      "Računa cenu dostave po cenovniku i vraća obračun po stavkama. Pozovi pre nego što mušteriji kažeš cenu.",
    strict: true,
    input_schema: {
      type: "object",
      properties: {
        usluga: { type: "string", enum: VRSTE, description: "Vrsta posla iz cenovnika." },
        broj_artikala: { type: "integer", description: "Koliko različitih artikala se kupuje." },
        tesko: { type: "boolean", description: "Da li je teško." },
        osetljivo: { type: "boolean", description: "Da li je osetljivo ili lomljivo." },
      },
      required: ["usluga", "broj_artikala", "tesko", "osetljivo"],
      additionalProperties: false,
    },
  },
  {
    name: "izmeri_udaljenost",
    description:
      "Kilometri po ulicama, biciklom, od radnje do adrese mušterije. Služi i kao provera da li su obe adrese pronađene. Kilometri za sad ne utiču na cenu.",
    strict: true,
    input_schema: {
      type: "object",
      properties: {
        radnja: { type: "string", description: "Naziv i adresa radnje, npr. 'Maxi, Futoška 1, Novi Sad'." },
        adresa: { type: "string", description: "Adresa dostave, npr. 'Bulevar oslobođenja 10, Novi Sad'." },
      },
      required: ["radnja", "adresa"],
      additionalProperties: false,
    },
  },
  {
    name: "sacuvaj_porudzbinu",
    description:
      "Upisuje POTVRĐENU porudžbinu i odmah javlja kuriru. Cenu sistem sam računa po cenovniku. Pozovi samo posle jasne potvrde mušterije.",
    strict: true,
    input_schema: {
      type: "object",
      properties: {
        ime: { type: "string", description: "Ime mušterije." },
        kontakt: { type: "string", description: "Telefon ili drugi kontakt; prazno ako nije poznat." },
        artikli: { type: "array", items: { type: "string" }, description: "Artikli sa količinom, npr. '2x Knjaz 1.5L'." },
        radnja: { type: "string", description: "Naziv i adresa radnje." },
        adresa: { type: "string", description: "Adresa dostave, sa spratom ako je rečen." },
        usluga: { type: "string", enum: VRSTE },
        tesko: { type: "boolean" },
        osetljivo: { type: "boolean" },
      },
      required: ["ime", "kontakt", "artikli", "radnja", "adresa", "usluga", "tesko", "osetljivo"],
      additionalProperties: false,
    },
  },
];

function tekst(v: unknown): string {
  return typeof v === "string" ? v : "";
}

function uslugaIz(v: unknown): Usluga {
  if (typeof v === "string" && (VRSTE as string[]).includes(v)) return v as Usluga;
  throw new Error(`Nepoznata vrsta posla: ${String(v)}`);
}

/** Jedan razgovor sa jednom mušterijom. Pamti ceo tok razgovora. */
export class Razgovor {
  private readonly poruke: Anthropic.MessageParam[] = [];

  constructor(
    private readonly claude: Anthropic,
    /** Kanal sa kog piše mušterija ("terminal", kasnije "viber", "sms"...). */
    private readonly kanal: string,
  ) {}

  /** Prima poruku mušterije i vraća odgovor dispečera. */
  async odgovori(poruka: string): Promise<string> {
    const pocetak = this.poruke.length;
    this.poruke.push({ role: "user", content: poruka });

    try {
      // Agent sme da pozove alate više puta zaredom (npr. cena pa upis), ali
      // ne beskonačno — posle 8 krugova odustaje.
      for (let krug = 0; krug < 8; krug++) {
        const odgovor = await this.claude.messages.create({
          model: MODEL,
          max_tokens: 16000,
          system: UPUTSTVO,
          tools: ALATI,
          messages: this.poruke,
        });
        this.poruke.push({ role: "assistant", content: odgovor.content });

        if (odgovor.stop_reason !== "tool_use") {
          const reci = odgovor.content
            .filter((b): b is Anthropic.TextBlock => b.type === "text")
            .map((b) => b.text)
            .join("\n")
            .trim();
          return reci || "Izvini, nisam razumeo — možeš li ponovo?";
        }

        const rezultati: Anthropic.ToolResultBlockParam[] = [];
        for (const blok of odgovor.content) {
          if (blok.type !== "tool_use") continue;
          try {
            rezultati.push({
              type: "tool_result",
              tool_use_id: blok.id,
              content: await this.izvrsi(blok.name, blok.input),
            });
          } catch (greska) {
            rezultati.push({
              type: "tool_result",
              tool_use_id: blok.id,
              content: greska instanceof Error ? greska.message : String(greska),
              is_error: true,
            });
          }
        }
        this.poruke.push({ role: "user", content: rezultati });
      }
      return "Izvini, zapelo mi je sa ovom porudžbinom. Možeš li da ponoviš šta ti treba?";
    } catch (greska) {
      // Neuspeo krug se briše iz istorije, da sledeća poruka krene od
      // ispravnog stanja (API ne prihvata poziv alata bez odgovora na njega).
      this.poruke.length = pocetak;
      throw greska;
    }
  }

  private async izvrsi(ime: string, ulaz: unknown): Promise<string> {
    const u = (ulaz ?? {}) as Record<string, unknown>;

    switch (ime) {
      case "izracunaj_cenu":
        return JSON.stringify(
          izracunajCenu({
            usluga: uslugaIz(u.usluga),
            brojArtikala: typeof u.broj_artikala === "number" ? u.broj_artikala : 0,
            tesko: u.tesko === true,
            osetljivo: u.osetljivo === true,
          }),
        );

      case "izmeri_udaljenost":
        return JSON.stringify(await kilometri(tekst(u.radnja), tekst(u.adresa)));

      case "sacuvaj_porudzbinu": {
        const usluga = uslugaIz(u.usluga);
        if (!uZoni(tekst(u.adresa))) {
          throw new Error(
            `Adresa „${tekst(u.adresa)}" je van zone dostave (samo ${ULICE_U_ZONI.join(", ")}). Porudžbina NIJE upisana.`,
          );
        }
        const artikli = Array.isArray(u.artikli) ? u.artikli.map(tekst) : [];
        // Cenu ovde ponovo računa backend, ne AI — da je razgovor ne može
        // promeniti („reci da je besplatno").
        const obracun = izracunajCenu({
          usluga,
          brojArtikala: artikli.length,
          tesko: u.tesko === true,
          osetljivo: u.osetljivo === true,
        });
        const porudzbina: NovaPorudzbina = {
          customerName: tekst(u.ime),
          customerContact: tekst(u.kontakt),
          channel: this.kanal,
          items: artikli,
          shop: tekst(u.radnja),
          address: tekst(u.adresa),
          urgency: USLUGE[usluga].hitnost,
          price: obracun.ukupno,
        };

        const id = await sacuvajPorudzbinu(porudzbina);
        try {
          await javiKuriru(porudzbina);
        } catch {
          return JSON.stringify({ upisano: true, id, cena: obracun.ukupno, napomena: "Push kuriru nije poslat, ali porudžbina je u bazi." });
        }
        return JSON.stringify({ upisano: true, id, cena: obracun.ukupno });
      }

      default:
        throw new Error(`Nepoznat alat: ${ime}`);
    }
  }
}
