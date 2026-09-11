import assert from "node:assert/strict";
import { test } from "node:test";
import { tacanPogodak } from "./udaljenost.js";

// Pogoci su prepisani iz pravih ORS odgovora (11.09.2026).

test("nepostojeća ulica ne prolazi, iako ORS vrati neku drugu", () => {
  assert.equal(tacanPogodak("Ulica Koje Nema 999", { layer: "street", name: "Ulica heroja" }), false);
});

test("grad ili selo nisu adresa", () => {
  assert.equal(tacanPogodak("Ulica Koje Nema 999, Novi Sad", { layer: "locality", name: "Novi Sad" }), false);
  assert.equal(tacanPogodak("Kovilj mesara", { layer: "locality", name: "Kovilj" }), false);
});

test("prave ulice i kućni brojevi prolaze, i bez kvačica", () => {
  assert.ok(tacanPogodak("Mileve Marić 14, Novi Sad", { layer: "street", name: "Mileve Marić" }));
  assert.ok(tacanPogodak("Mileve Maric 14", { layer: "street", name: "Mileve Marić" }));
  assert.ok(tacanPogodak("Stanoja Stanojevića 5", { layer: "street", name: "Stanoja Stanojevica" }));
  assert.ok(
    tacanPogodak("Bulevar oslobođenja 10", {
      layer: "address",
      name: "11 Bulevar Oslobođenja",
      street: "Bulevar Oslobođenja",
    }),
  );
});

test("radnja prolazi kad joj je ime u upisanom", () => {
  assert.ok(tacanPogodak("Maxi, Futoška 1, Novi Sad", { layer: "venue", name: "Maxi" }));
  assert.equal(tacanPogodak("Idea, Futoška 1", { layer: "venue", name: "Maxi" }), false);
});

test("prazni podaci ne ruše proveru", () => {
  assert.equal(tacanPogodak("", {}), false);
  assert.equal(tacanPogodak("Futoška 1", { layer: "street" }), false);
  assert.equal(tacanPogodak("", { layer: "street", name: "Futoska" }), false);
});
