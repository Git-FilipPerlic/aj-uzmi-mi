// Zona dostave: za sad samo Šarengrad (odluka korisnika, 11.09.2026).
// Proverava se u backend-u, ne samo u uputstvu agentu — da ni zabuna ni
// nagovaranje u razgovoru ne mogu da propuste porudžbinu van zone.

export const ULICE_U_ZONI = ["Mileve Marić", "Momčila Tapavice", "Stanoja Stanojevića"];

/** Mala slova, bez kvačica i interpunkcije — da „Mileve Maric 14" i „MILEVE MARIĆ, 14" budu isto. */
export function sredi(tekst: string): string {
  return tekst
    .toLowerCase()
    .replaceAll("đ", "dj")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[.,;]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

const ULICE = ULICE_U_ZONI.map(sredi);

/** Da li je adresa dostave u zoni. Prazna adresa nije. */
export function uZoni(adresa: string): boolean {
  const a = sredi(adresa);
  return a.length > 0 && ULICE.some((ulica) => a.includes(ulica));
}
