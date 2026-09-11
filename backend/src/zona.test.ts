import assert from "node:assert/strict";
import { test } from "node:test";
import { uZoni } from "./zona.js";

test("sve tri ulice Šarengrada su u zoni", () => {
  assert.ok(uZoni("Mileve Marić 14, sprat 2"));
  assert.ok(uZoni("Momčila Tapavice 5"));
  assert.ok(uZoni("Stanoja Stanojevića 20, Novi Sad"));
});

test("pisanje bez kvačica, velikim slovima ili sa zarezom se prepoznaje", () => {
  assert.ok(uZoni("mileve maric 14"));
  assert.ok(uZoni("MOMCILA TAPAVICE, 5"));
  assert.ok(uZoni("Stanoja Stanojevica 20"));
});

test("adrese van Šarengrada nisu u zoni", () => {
  assert.equal(uZoni("Bulevar oslobođenja 10, Novi Sad"), false);
  assert.equal(uZoni("Futoška 12"), false);
});

test("prazna adresa nije u zoni", () => {
  assert.equal(uZoni(""), false);
  assert.equal(uZoni("   "), false);
});
