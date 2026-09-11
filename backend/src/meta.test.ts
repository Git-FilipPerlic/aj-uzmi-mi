import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import { test } from "node:test";
import { izvuciPoruke, podeli, potpisValja } from "./meta.js";

const telo = Buffer.from('{"object":"page"}');
const potpis = "sha256=" + createHmac("sha256", "tajna").update(telo).digest("hex");

test("ispravan Meta potpis prolazi, lažan i prazan ne", () => {
  assert.ok(potpisValja(telo, potpis, "tajna"));
  assert.equal(potpisValja(telo, potpis, "druga tajna"), false);
  assert.equal(potpisValja(Buffer.from('{"object":"lazno"}'), potpis, "tajna"), false);
  assert.equal(potpisValja(telo, undefined, "tajna"), false);
  assert.equal(potpisValja(telo, "sha256=abc", "tajna"), false);
  assert.equal(potpisValja(telo, potpis, ""), false);
});

test("tekstualna poruka sa Messengera se izvlači", () => {
  const poruke = izvuciPoruke({
    object: "page",
    entry: [{ messaging: [{ sender: { id: "123" }, message: { mid: "m1", text: " 2 hleba " } }] }],
  });
  assert.deepEqual(poruke, [
    { kanal: "messenger", posiljalac: "123", mid: "m1", tekst: "2 hleba", zvuk: [], drugiPrilozi: 0 },
  ]);
});

test("glasovna poruka sa Instagrama daje adresu zvuka, slika se samo broji", () => {
  const [p] = izvuciPoruke({
    object: "instagram",
    entry: [{
      messaging: [{
        sender: { id: "ig9" },
        message: {
          mid: "m2",
          attachments: [
            { type: "audio", payload: { url: "https://primer/glas.mp4" } },
            { type: "image", payload: { url: "https://primer/slika.jpg" } },
          ],
        },
      }],
    }],
  });
  assert.equal(p?.kanal, "instagram");
  assert.deepEqual(p?.zvuk, ["https://primer/glas.mp4"]);
  assert.equal(p?.drugiPrilozi, 1);
  assert.equal(p?.tekst, "");
});

test("naši odgovori (echo), potvrde čitanja i smeće se preskaču", () => {
  assert.deepEqual(izvuciPoruke({
    object: "page",
    entry: [{ messaging: [
      { sender: { id: "1" }, message: { mid: "e", text: "odgovor", is_echo: true } },
      { sender: { id: "1" }, read: { watermark: 1 } },
      { message: { text: "bez pošiljaoca" } },
    ] }],
  }), []);
  assert.deepEqual(izvuciPoruke(null), []);
  assert.deepEqual(izvuciPoruke({ object: "whatsapp_business_account", entry: [] }), []);
  assert.deepEqual(izvuciPoruke({ object: "page", entry: "nije lista" }), []);
});

test("dug odgovor se deli po razmacima, kratak ostaje ceo", () => {
  assert.deepEqual(podeli("kratko"), ["kratko"]);
  assert.deepEqual(podeli("aaa bbb ccc", 7), ["aaa bbb", "ccc"]);
  assert.deepEqual(podeli("   "), []);
});
