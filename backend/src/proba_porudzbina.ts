// Proba bez AI-ja: backend upiše jednu izmišljenu porudžbinu i pošalje push.
// Ako radi, porudžbina se odmah pojavi u aplikaciji i telefon zazvoni —
// bez Firebase konzole. Pokretanje: npm run proba

import { javiKuriru, sacuvajPorudzbinu, type NovaPorudzbina } from "./porudzbine.js";

const proba: NovaPorudzbina = {
  customerName: "PROBA backend",
  customerContact: "",
  channel: "web",
  items: ["hleb", "jogurt 1l"],
  shop: "Maxi, Futoška 1, Novi Sad",
  address: "Futoška 12, Novi Sad",
  urgency: "normal",
  price: null,
};

const id = await sacuvajPorudzbinu(proba);
console.log(`Upisana porudžbina: ${id}`);

await javiKuriru(proba);
console.log("Push poslat na temu „kurir\".");
