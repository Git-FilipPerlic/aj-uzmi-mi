import assert from "node:assert/strict";
import { test } from "node:test";
import { nastavak, prepisi, uLatinicu } from "./glas.js";

test("bez Groq ključa prepis kaže zašto ne radi, ne puca", async () => {
  const sacuvan = process.env.GROQ_API_KEY;
  delete process.env.GROQ_API_KEY;
  try {
    const r = await prepisi("https://primer/glas.mp4");
    assert.ok("greska" in r && r.greska.includes("GROQ_API_KEY"));
  } finally {
    if (sacuvan !== undefined) process.env.GROQ_API_KEY = sacuvan;
  }
});

test("prazna adresa glasovne poruke ne ide na Groq", async () => {
  const sacuvan = process.env.GROQ_API_KEY;
  process.env.GROQ_API_KEY = "probni";
  try {
    const r = await prepisi("  ");
    assert.deepEqual(r, { greska: "Glasovna poruka nema adresu." });
  } finally {
    if (sacuvan === undefined) delete process.env.GROQ_API_KEY;
    else process.env.GROQ_API_KEY = sacuvan;
  }
});

test("ćirilica iz prepisa postaje latinica, ostalo ostaje isto", () => {
  assert.equal(uLatinicu("Здраво, треба ми хлеб, Милеве Марић 14"), "Zdravo, treba mi hleb, Mileve Marić 14");
  assert.equal(uLatinicu("Љубица, Њива, Џеп, ђак"), "Ljubica, Njiva, Džep, đak");
  assert.equal(uLatinicu("već latinica 2l"), "već latinica 2l");
  assert.equal(uLatinicu(""), "");
});

test("nastavak fajla po vrsti zvuka", () => {
  assert.equal(nastavak("audio/mpeg"), "mp3");
  assert.equal(nastavak("audio/ogg; codecs=opus"), "ogg");
  assert.equal(nastavak("audio/aac"), "m4a");
  assert.equal(nastavak("video/mp4"), "mp4");
  assert.equal(nastavak(null), "mp4");
});
