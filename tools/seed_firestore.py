# Ubacuje probne porudžbine u Firestore kolekciju `orders`.
#
# Služi samo za razvoj — da u bazi ima nešto na čemu se aplikacija vidi dok
# backend agent još ne postoji. Pokretanje:
#
#     python tools/seed_firestore.py
#
# Skripta ne traži nijedan dodatni paket; koristi Firestore REST API i ključ
# koji već stoji u app/lib/firebase_options.dart. Radi samo dok su pravila
# baze otvorena (vidi firestore.rules) — čim se doda prijava, prestaje da radi
# i porudžbine se unose kroz aplikaciju ili backend.

import io
import json
import os
import re
import urllib.request
from datetime import datetime, timedelta, timezone

PROJEKAT = "aj-uzmi-mi"
KOLEKCIJA = "orders"
KOREN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def procitaj_kljuc():
    """Uzima prvi apiKey iz firebase_options.dart, da se ne prepisuje ručno."""
    put = os.path.join(KOREN, "app", "lib", "firebase_options.dart")
    tekst = io.open(put, encoding="utf-8").read()
    nadjeno = re.search(r"apiKey:\s*'([^']+)'", tekst)
    if not nadjeno:
        raise SystemExit("Nije pronađen apiKey u firebase_options.dart")
    return nadjeno.group(1)


def tekst(v):
    return {"stringValue": v}


def broj(v):
    return {"nullValue": None} if v is None else {"integerValue": str(v)}


def spisak(v):
    return {"arrayValue": {"values": [tekst(x) for x in v]}}


def vreme(v):
    return {"timestampValue": v.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")}


def porudzbina(ime, kontakt, kanal, artikli, adresa, hitnost, cena, status, mesto, kada):
    return {
        "fields": {
            "customerName": tekst(ime),
            "customerContact": tekst(kontakt),
            "channel": tekst(kanal),
            "items": spisak(artikli),
            "address": tekst(adresa),
            "urgency": tekst(hitnost),
            "price": broj(cena),
            "status": tekst(status),
            "routeOrder": broj(mesto),
            "createdAt": vreme(kada),
        }
    }


def main():
    kljuc = procitaj_kljuc()
    sada = datetime.now(timezone.utc)

    porudzbine = {
        "proba-1": porudzbina(
            "Milica Jovanović", "+381 63 111 222", "viber",
            ["1kg mlevenog mesa", "500g kajmaka"],
            "Bulevar Kneza Miloša 45, Novi Sad",
            "hitno", 450, "nova", 1, sada - timedelta(minutes=8)),
        "proba-2": porudzbina(
            "Dragan Perić", "+381 64 333 444", "whatsapp",
            ["hleb", "mleko 2l", "jaja 10kom"],
            "Futoška 12, Novi Sad",
            "normal", 300, "potvrdjena", 2, sada - timedelta(minutes=25)),
        "proba-3": porudzbina(
            "Apoteka Sunce", "021 555 666", "sms",
            ["paket lekova za g. Simića"],
            "Narodnog fronta 8, Novi Sad",
            "zakazano", 380, "preuzeta", 3, sada - timedelta(hours=1)),
        # Namerno prazna porudžbina: agent još nije izvukao podatke.
        "proba-4": porudzbina(
            "Nepoznat broj", "+381 60 777 888", "sms",
            [], "", "", None, "nova", None, sada - timedelta(minutes=2)),
        "proba-5": porudzbina(
            "Jovan Marić", "+381 62 999 000", "web",
            ["2x burek sa sirom", "jogurt"],
            "Šafarikova 3, Novi Sad",
            "normal", 280, "dostavljena", 0, sada - timedelta(hours=2)),
    }

    osnova = (
        "https://firestore.googleapis.com/v1/projects/"
        f"{PROJEKAT}/databases/%28default%29/documents/{KOLEKCIJA}"
    )

    for ime_dokumenta, telo in porudzbine.items():
        adresa = f"{osnova}?documentId={ime_dokumenta}&key={kljuc}"
        zahtev = urllib.request.Request(
            adresa,
            data=json.dumps(telo).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(zahtev) as odgovor:
                odgovor.read()
            print(f"upisano: {ime_dokumenta}")
        except urllib.error.HTTPError as greska:
            poruka = greska.read().decode("utf-8", "replace")
            # 409 znači da dokument već postoji — to nije problem.
            if greska.code == 409:
                print(f"već postoji: {ime_dokumenta}")
            else:
                print(f"GREŠKA {greska.code} za {ime_dokumenta}: {poruka}")


if __name__ == "__main__":
    main()
