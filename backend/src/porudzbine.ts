import { FieldValue } from "firebase-admin/firestore";
import { baza, push } from "./firebase.js";

/**
 * Hitnost (CLAUDE.md §5). „kad_stignes" aplikacija prikazuje kao
 * „Kad stigneš".
 */
export type Hitnost = "normal" | "hitno" | "zakazano" | "kad_stignes";

/** Podaci nove porudžbine. Svako tekstualno polje sme biti prazno. */
export interface NovaPorudzbina {
  customerName: string;
  customerContact: string;
  channel: string;
  items: string[];
  /** Radnja: naziv i adresa, npr. "Maxi, Futoška 1". */
  shop: string;
  address: string;
  urgency: Hitnost;
  /** Cena u dinarima; `null` dok se ne izračuna. */
  price: number | null;
}

/**
 * Upisuje porudžbinu u kolekciju `orders` sa statusom „nova" i vraća njen id.
 * Rutu (`routeOrder`) računa backend posebno, pa je ovde prazna.
 */
export async function sacuvajPorudzbinu(p: NovaPorudzbina): Promise<string> {
  const dokument = await baza.collection("orders").add({
    customerName: p.customerName.trim(),
    customerContact: p.customerContact.trim(),
    channel: p.channel.trim(),
    items: p.items.map((a) => a.trim()).filter((a) => a.length > 0),
    shop: p.shop.trim(),
    address: p.address.trim(),
    urgency: p.urgency,
    price: p.price,
    status: "nova",
    routeOrder: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  return dokument.id;
}

/**
 * Javlja kuriru da je stigla nova porudžbina: push na temu `kurir`, sa imenom
 * mušterije i adresom (CLAUDE.md §6, tačka 4).
 */
export async function javiKuriru(p: NovaPorudzbina): Promise<void> {
  const ime = p.customerName.trim() || "Nepoznata mušterija";
  const adresa = p.address.trim() || "adresa nije uneta";
  const naslov = p.urgency === "hitno" ? "HITNO — nova porudžbina" : "Nova porudžbina";

  await push.send({
    topic: "kurir",
    notification: { title: naslov, body: `${ime} — ${adresa}` },
    // Visok prioritet: da Android ne odlaže obaveštenje radi štednje baterije.
    android: { priority: "high" },
  });
}
