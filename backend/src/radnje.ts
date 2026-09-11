// Radnje u komšiluku koje kurir zna (spisak dao korisnik, 11.09.2026).
// Mesto je prepisano sa Google Maps linkova koje je korisnik poslao, pa je
// tačnije od pretrage po adresi — za radnju bez imena (jaja, mešovita roba)
// pretraga ne bi našla ništa. Adresu kopira korisnik iz Google Maps.

import { sredi } from "./zona.js";

export type Radnja = {
  /** Naziv pod kojim agent upisuje radnju. */
  naziv: string;
  /** Šta se tu kupuje — po tome agent bira radnju. */
  vrsta: string;
  adresa: string;
  lat: number;
  lon: number;
  /** Šta još treba znati (reči korisnika). */
  napomena?: string;
};

export const RADNJE: Radnja[] = [
  { naziv: "Prodavnica mešovite robe", vrsta: "mešovita roba", adresa: "Mileve Marić 5", lat: 45.251901, lon: 19.789323 },
  { naziv: "Prodavnica jaja", vrsta: "kokošija jaja", adresa: "Mileve Marić 4", lat: 45.252037, lon: 19.789306 },
  { naziv: "Mali Kvantaš", vrsta: "higijenska roba", adresa: "Mileve Marić 1", lat: 45.2519135, lon: 19.7896369 },
  { naziv: "Apoteka Novo Naselje", vrsta: "apoteka, lekovi", adresa: "Mileve Marić 3", lat: 45.2518846, lon: 19.7895608 },
  { naziv: "Podrum pića Zarko", vrsta: "piće", adresa: "Mileve Marić 4", lat: 45.2521144, lon: 19.7894614 },
  { naziv: "Plastikarnica", vrsta: "plastika, posuđe, sitnice za kuću", adresa: "Mileve Marić 4", lat: 45.252152, lon: 19.7894646 },
  { naziv: "Foto Šarengrad", vrsta: "foto radnja", adresa: "Mileve Marić 4", lat: 45.252152, lon: 19.7894646 },
  {
    naziv: "Ana Maria 021",
    vrsta: "cveće, buketi",
    adresa: "Mileve Marić 4",
    lat: 45.2521261,
    lon: 19.7892471,
    napomena: "cveće je pipavo — vrsta posla „specijalno\"",
  },
  {
    naziv: "Svetofor",
    vrsta: "mešovita roba, jeftino",
    adresa: "Olje Ivanjicki 13",
    lat: 45.2551826,
    lon: 19.7861223,
    napomena: "poznat po popustima, ali roba slabijeg kvaliteta — meso se tu ne kupuje",
  },
  {
    naziv: "Magic Walls NS",
    vrsta: "boje (možda i tapete)",
    adresa: "Bulevar Kneza Miloša 37",
    lat: 45.2528054,
    lon: 19.7894419,
  },
];

/**
 * Poznata radnja iz teksta koji je agent upisao, npr. „Podrum pića Zarko,
 * Mileve Marić 4". Tekst mora da počinje tačnim nazivom (bez obzira na
 * kvačice i velika slova) — da „Apoteka Benu" ne postane naša apoteka.
 */
export function poznataRadnja(tekst: string): Radnja | null {
  const t = sredi(tekst);
  if (!t) return null;
  return RADNJE.find((r) => {
    const n = sredi(r.naziv);
    return t === n || t.startsWith(n + " ");
  }) ?? null;
}
