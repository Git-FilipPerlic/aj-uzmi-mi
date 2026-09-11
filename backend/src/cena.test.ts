import assert from "node:assert/strict";
import { test } from "node:test";
import { izracunajCenu, type UpitZaCenu } from "./cena.js";

const bez: Omit<UpitZaCenu, "usluga"> = { brojArtikala: 1, tesko: false, osetljivo: false };

test("sitnica: prvi artikal besplatno, svaki sledeći +50", () => {
  assert.equal(izracunajCenu({ ...bez, usluga: "sitnica", brojArtikala: 1 }).ukupno, 0);
  assert.equal(izracunajCenu({ ...bez, usluga: "sitnica", brojArtikala: 3 }).ukupno, 100);
});

test("sitnica bez artikala ili sa pogrešnim brojem ne ide u minus", () => {
  assert.equal(izracunajCenu({ ...bez, usluga: "sitnica", brojArtikala: 0 }).ukupno, 0);
  assert.equal(izracunajCenu({ ...bez, usluga: "sitnica", brojArtikala: -4 }).ukupno, 0);
});

test("osnovne cene iz cenovnika", () => {
  assert.equal(izracunajCenu({ ...bez, usluga: "namirnice" }).ukupno, 150);
  assert.equal(izracunajCenu({ ...bez, usluga: "odmah" }).ukupno, 200);
  assert.equal(izracunajCenu({ ...bez, usluga: "cigare" }).ukupno, 150);
  assert.equal(izracunajCenu({ ...bez, usluga: "specijalno" }).ukupno, 200);
  assert.equal(izracunajCenu({ ...bez, usluga: "specijalno_hitno" }).ukupno, 350);
});

test("teško +150 i osetljivo +100 se sabiraju sa osnovom", () => {
  const obracun = izracunajCenu({ ...bez, usluga: "namirnice", tesko: true, osetljivo: true });
  assert.equal(obracun.ukupno, 150 + 150 + 100);
  assert.equal(obracun.stavke.length, 3);
});

test("obračun uvek kaže da dodatak za vreme još nije uračunat", () => {
  assert.match(izracunajCenu({ ...bez, usluga: "cigare" }).napomena ?? "", /nije uračunat/);
});
