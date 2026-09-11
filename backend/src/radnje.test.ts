import assert from "node:assert/strict";
import { test } from "node:test";
import { poznataRadnja } from "./radnje.js";

test("radnja se prepoznaje po nazivu, i sa adresom iza njega", () => {
  assert.equal(poznataRadnja("Podrum pića Zarko, Mileve Marić 4")?.naziv, "Podrum pića Zarko");
  assert.equal(poznataRadnja("Svetofor")?.naziv, "Svetofor");
});

test("pisanje bez kvačica i velikim slovima se prepoznaje", () => {
  assert.equal(poznataRadnja("FOTO SARENGRAD, Mileve Maric 4")?.naziv, "Foto Šarengrad");
  assert.equal(poznataRadnja("prodavnica mesovite robe")?.naziv, "Prodavnica mešovite robe");
});

test("slični nazivi se ne mešaju", () => {
  assert.equal(poznataRadnja("Prodavnica jaja, Mileve Marić 4")?.naziv, "Prodavnica jaja");
  assert.equal(poznataRadnja("Apoteka Benu, Bulevar oslobođenja 5"), null);
  assert.equal(poznataRadnja("Svetoforko"), null);
});

test("nepoznata ili prazna radnja nije poznata", () => {
  assert.equal(poznataRadnja("Maxi, Futoška 1"), null);
  assert.equal(poznataRadnja(""), null);
  assert.equal(poznataRadnja("   "), null);
});
