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

## 2026-09-10 — Faza 2, drugi korak: prava baza (Firestore) i git

- Urađeno:
  - Usluga dobila ime **„Aj uzmi mi"**; Firebase projekat `aj-uzmi-mi`,
    Android package `rs.ajuzmimi.kurir`.
  - Dodata dva paketa: `firebase_core` i `cloud_firestore`. FlutterFire je
    registrovao Android i Windows aplikaciju i napravio `firebase_options.dart`.
  - `FirestoreOrderStore` sluša kolekciju `orders` neprekidno; dugmad
    „Preuzeto"/„Dostavljeno" upisuju status u bazu. Memorijski `OrderStore`
    ostaje kao osnova i koristi se u testovima.
  - Ekrani dobili stanja „Učitavanje" i „Nema veze sa bazom", da se nikad ne
    vidi prazan beli ekran.
  - Napravljena Firestore baza u regionu `europe-west3` (Frankfurt) i
    postavljena pravila iz `firestore.rules`.
  - `tools/seed_firestore.py` ubacuje pet probnih porudžbina u bazu bez ijednog
    dodatnog paketa (Firestore REST API + ključ iz `firebase_options.dart`).
  - Napravljen **privatan** GitHub repozitorijum
    `https://github.com/Git-FilipPerlic/aj-uzmi-mi` i poslat ceo projekat.
- Provereno: `flutter analyze` bez primedbi; `flutter test` — 9 testova
  prolazi; pet porudžbina vidljivo u bazi preko REST API-ja.
- Otvoreni problemi:
  - **Pravila baze su privremeno otvorena do 10.10.2026.** Repozitorijum je
    zato privatan; u javni ide tek kad se doda prijava i pravila se stegnu na
    „samo prijavljen kurir".
  - Prvi upis u bazu je pao sa greškom 403 zato što se nova pravila nisu još
    raširila; drugi pokušaj minut kasnije je prošao. Normalno ponašanje.
- Sledeće: prijava (Firebase Authentication, mejl i lozinka), pa stezanje
  pravila, pa push notifikacije za nove porudžbine.

## 2026-09-11 — Faza 2, treći korak: prijava kurira

- Urađeno:
  - Dodat paket `firebase_auth`.
  - `lib/data/auth.dart` — osnovna klasa `Auth` (prijava u memoriji, za
    testove); `lib/data/firebase_auth_service.dart` — prava prijava preko
    Firebase-a, sa greškama prevedenim na običan srpski.
  - `lib/screens/login_screen.dart` — ekran „Prijava kurira" (mejl, lozinka,
    dugme za prikaz lozinke). Nema registracije u aplikaciji: nalog se pravi
    ručno u Firebase konzoli, da niko ne može sam sebi da napravi nalog.
  - Porudžbine se otvaraju tek posle prijave i zatvaraju pri odjavi. Dugme za
    odjavu u gornjem desnom uglu traži potvrdu (da se ne pritisne slučajno u
    vožnji).
  - Firebase pamti prijavu na telefonu — kurir kuca lozinku samo jednom.
- Provereno: `flutter analyze` bez primedbi; `flutter test` — 14 testova
  prolazi (5 novih: prazna polja pri prijavi, prijava/odjava, prelaz sa ekrana
  za prijavu na porudžbine i nazad). Prijava mejlom i lozinkom je uključena u
  Firebase projektu (proveren odgovor servera).
- Otvoreni problemi:
  - Pravila baze su i dalje otvorena — stežu se kad nalog kurira postoji i
    prijava proradi na pravom telefonu.
  - Firebase po defaultu dozvoljava da **bilo ko napravi nalog** preko
    javnog API ključa, i bez aplikacije. Pre stezanja pravila isključiti to u
    konzoli (Authentication → Settings → User actions → „Enable create"),
    inače „samo prijavljen" ne znači „samo kurir".
  - `tools/seed_firestore.py` se ne prijavljuje, pa će posle stezanja pravila
    dobijati grešku 403. Treba ga naučiti da se prijavi (ili ubacivati podatke
    iz konzole).
- Sledeće: napraviti nalog kurira u konzoli, isključiti samostalno pravljenje
  naloga, probati prijavu na telefonu, pa stegnuti pravila.

## 2026-09-11 — Faza 2, četvrti korak: stegnuta pravila baze

- Urađeno:
  - U konzoli napravljen nalog kurira i isključeno samostalno pravljenje
    naloga (Authentication → Settings → User actions).
  - `firestore.rules`: čita i piše samo prijavljen korisnik; privremeni rok
    10.10.2026. uklonjen. Pravila postavljena (`firebase deploy`).
  - `tools/seed_firestore.py` se sad prijavljuje (pita mejl i lozinku, lozinka
    se ne prikazuje i ne čuva) i šalje token uz svaki upis.
  - `CLAUDE.md` ažuriran: prijava, pravila i zašto je pravljenje naloga
    isključeno.
- Provereno: prijava na pravoj aplikaciji (Windows) radi i porudžbine se vide;
  čitanje baze bez prijave vraća grešku 403; nova pravila prošla proveru
  sintakse; skripta prošla proveru sintakse (nije pokretana, jer traži
  lozinku).
- Otvoreni problemi: repozitorijum je i dalje privatan — razlog za to više ne
  važi, odluka o javnom je na korisniku.
- Sledeće: push notifikacija za novu porudžbinu (Firebase Cloud Messaging).
