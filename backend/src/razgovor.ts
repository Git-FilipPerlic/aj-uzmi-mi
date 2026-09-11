// Proba razgovora u terminalu: ti pišeš kao mušterija, dispečer odgovara.
// Potvrđena porudžbina ide u pravu bazu i na telefon kurira.
// Pokretanje: npm run razgovor   (izlaz: kraj)

import Anthropic from "@anthropic-ai/sdk";
import { createInterface } from "node:readline/promises";
import { stdin, stdout } from "node:process";
import { Razgovor } from "./agent.js";

// Ključevi (Claude, ORS) stoje u backend/.env.
process.loadEnvFile(new URL("../.env", import.meta.url));

if (!process.env.ANTHROPIC_API_KEY?.trim()) {
  console.error("Nema Claude ključa: upiši ANTHROPIC_API_KEY u backend/.env.");
  process.exit(1);
}

const razgovor = new Razgovor(new Anthropic(), "terminal");
const citac = createInterface({ input: stdin, output: stdout });

// Ulaz se zatvori kad stigne kraj ubačenih probnih poruka; posle toga se
// „Ti:" više ne prikazuje (inače program pukne), a poruke koje već čekaju
// se i dalje obrađuju.
let ulazZatvoren = false;
citac.on("close", () => {
  ulazZatvoren = true;
});

console.log("Aj uzmi mi — proba razgovora. Piši kao mušterija; „kraj\" za izlaz.\n");
citac.setPrompt("Ti: ");
const pitaj = () => {
  if (!ulazZatvoren) citac.prompt();
};
pitaj();

// Redovi se čitaju redom i čekaju u redu dok dispečer razmišlja — nijedna
// poruka ne propada, ni kad ih stigne više odjednom (npr. probne poruke).
for await (const red of citac) {
  const poruka = red.trim();
  if (!poruka) {
    pitaj();
    continue;
  }
  if (poruka.toLowerCase() === "kraj") break;
  // Da se u probi sa ubačenim porukama vidi i šta je „mušterija" napisala.
  if (!stdin.isTTY) console.log(poruka);

  try {
    console.log(`\nDispečer: ${await razgovor.odgovori(poruka)}\n`);
  } catch (greska) {
    if (greska instanceof Anthropic.AuthenticationError) {
      console.log("\nClaude ključ nije ispravan — proveri ANTHROPIC_API_KEY u backend/.env.\n");
    } else if (greska instanceof Anthropic.RateLimitError) {
      console.log("\nPreviše upita odjednom — sačekaj malo pa probaj ponovo.\n");
    } else if (greska instanceof Anthropic.APIConnectionError) {
      console.log("\nNema veze sa Claude-om — proveri internet.\n");
    } else if (greska instanceof Anthropic.APIError) {
      console.log(`\nGreška Claude API-ja (${greska.status}): ${greska.message}\n`);
    } else {
      console.log(`\nGreška: ${greska instanceof Error ? greska.message : String(greska)}\n`);
    }
  }
  pitaj();
}

citac.close();
