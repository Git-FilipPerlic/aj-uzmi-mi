// Cenovnik „Aj uzmi mi" — tačno onako kako ga je potvrdio korisnik
// (CLAUDE.md, odeljak „Cenovnik"). Brojeve ovde menjati samo uz njegovu odluku.

import type { Hitnost } from "./porudzbine.js";

/** Vrste posla iz cenovnika. */
export type Usluga =
  | "sitnica" //        donesi kad god — prvi artikal besplatno, svaki sledeći +50
  | "namirnice" //      iz radnje, u roku od 60 min — 150
  | "odmah" //          piljara/radnja odmah, pa odmah nazad — 200
  | "cigare" //         odmah — 150
  | "specijalno" //     cvećara, kafa i kolač (pipavo), kad stigneš — 200
  | "specijalno_hitno"; // isto, ali hitno — 200 + 150

export const USLUGE: Record<Usluga, { opis: string; hitnost: Hitnost }> = {
  sitnica: { opis: "sitnica, donesi kad stigneš", hitnost: "kad_stignes" },
  namirnice: { opis: "namirnice iz radnje, u roku od 60 minuta", hitnost: "normal" },
  odmah: { opis: "piljara ili radnja odmah, pa odmah nazad", hitnost: "hitno" },
  cigare: { opis: "cigare, odmah", hitnost: "hitno" },
  specijalno: { opis: "nešto specijalno ili pipavo (cvećara, kafa i kolač), kad stigneš", hitnost: "kad_stignes" },
  specijalno_hitno: { opis: "nešto specijalno ili pipavo, hitno", hitnost: "hitno" },
};

export const DODATAK_TESKO = 150;
export const DODATAK_OSETLJIVO = 100;

export interface UpitZaCenu {
  usluga: Usluga;
  /** Broj artikala (važi za sitnice). */
  brojArtikala: number;
  /** Više od 2 L tečnosti, 5 L, kilo krompira i više. */
  tesko: boolean;
  /** Lomljivo ili ne sme da se ošteti. */
  osetljivo: boolean;
}

export interface Obracun {
  ukupno: number;
  /** Stavke obračuna, da agent može mušteriji da objasni cenu. */
  stavke: string[];
  /** Šta u cenu još nije uračunato, jer iznos nije određen. */
  napomena: string | null;
}

function osnovna(usluga: Usluga, brojArtikala: number): number {
  switch (usluga) {
    case "sitnica":
      return Math.max(0, Math.floor(brojArtikala) - 1) * 50;
    case "namirnice":
      return 150;
    case "odmah":
      return 200;
    case "cigare":
      return 150;
    case "specijalno":
      return 200;
    case "specijalno_hitno":
      return 200 + 150;
  }
}

export function izracunajCenu(upit: UpitZaCenu): Obracun {
  const stavke: string[] = [];
  const osnova = osnovna(upit.usluga, upit.brojArtikala);
  stavke.push(`${USLUGE[upit.usluga].opis}: ${osnova} din`);

  let ukupno = osnova;
  if (upit.tesko) {
    ukupno += DODATAK_TESKO;
    stavke.push(`teško: +${DODATAK_TESKO} din`);
  }
  if (upit.osetljivo) {
    ukupno += DODATAK_OSETLJIVO;
    stavke.push(`osetljivo: +${DODATAK_OSETLJIVO} din`);
  }

  return {
    ukupno,
    stavke,
    // Dodatak za dugo trajanje postoji u cenovniku, ali iznos još nije
    // određen — ne računa se dok ga korisnik ne da.
    napomena: "Dodatak za dugo trajanje (više radnji, daleko) još nije određen i nije uračunat.",
  };
}
