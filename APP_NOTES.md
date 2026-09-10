# Dnevnik rada

Jedna beleška po završenom koraku: šta je urađeno, šta je provereno, šta je
sledeće. Vodi se od prvog dana, da se odluke ne izgube.

## Šablon

```
## <datum> — <šta je rađeno>

- Urađeno:
- Provereno:
- Otvoreni problemi:
- Sledeće:
```

## 2026-09-10 — Faza 2, prvi korak: ekrani kurirske aplikacije

- Urađeno:
  - Odlučeno da se kreće od Faze 2 (Flutter aplikacija), i to prvo ekrani sa
    test podacima, pa tek onda Firebase — da se odmah vidi da li raspored
    ekrana odgovara, pre nego što se veže za bazu.
  - Napravljen Flutter projekat u `app/` (paket `dispecer`, org `rs.dispecer`,
    platforme Android i Windows). Nijedan dodatni paket nije dodat.
  - `lib/models/order.dart` — model porudžbine sa istim poljima kao Firestore
    kolekcija `orders`; `Order.fromMap` podnosi praznu mapu i pogrešne tipove.
  - `lib/data/order_store.dart` — držač porudžbina u memoriji (aktivne, ruta,
    promena statusa); kad dođe Firebase, menja se samo ova klasa.
  - `lib/data/test_orders.dart` — pet izmišljenih porudžbina, uključujući i
    jednu praznu (bez adrese, cene i artikala) za proveru praznih stanja.
  - Ekrani: lista porudžbina (`Aktivne` / `Sve`), detalji sa dugmadima
    „Preuzeto" i „Dostavljeno", i predložena ruta poređana po `routeOrder`.
- Provereno: `flutter analyze` bez ijedne primedbe; `flutter test` — 9 testova
  prolazi (prazna polja, redosled rute, promena statusa, otvaranje detalja).
- Otvoreni problemi: nema prijave, nema baze ni push notifikacija — sve to
  dolazi sa Firebase korakom. Redosled rute se ne može menjati u aplikaciji
  (namerno: rutu računa backend).
- Sledeće: Firebase — kreirati projekat, dodati Firestore i prijavu, pa
  zameniti test podatke pravom bazom.
