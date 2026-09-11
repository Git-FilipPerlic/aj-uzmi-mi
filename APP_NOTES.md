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

## 2026-09-11 — Faza 2, peti korak: push obaveštenja (Faza 2 gotova)

- Urađeno:
  - Dodat paket `firebase_messaging` (odobrio korisnik).
  - `lib/data/push.dart` (prazna verzija za testove i Windows) i
    `lib/data/firebase_push_service.dart` (prava, samo Android). Telefon se po
    prijavi upisuje na temu `kurir`, a po odjavi se ispisuje — da odjavljen
    telefon ne dobija porudžbine.
  - Obaveštenje dok je aplikacija otvorena prikazuje se kao traka na dnu koja
    **ostaje dok kurir ne pritisne „U redu"**. Prvo je trajala 6 sekundi i
    korisnik ju je propustio — u vožnji bi se propuštala stalno.
  - `AndroidManifest.xml`: dozvola `POST_NOTIFICATIONS` (Android 13+).
  - `android/gradle.properties`: `kotlin.incremental=false`. Projekat je na
    disku D:, Flutter paketi na C:, i Kotlin-ov keš je zbog toga rušio build
    („different roots"). Ne vraćati bez premeštanja projekta na C:.
- Provereno: `flutter analyze` bez primedbi; `flutter test` — 17 testova
  prolazi (push se uključuje prijavom i isključuje odjavom; traka ostaje i
  sklanja se dugmetom; prazno obaveštenje kaže „Nova porudžbina"). Na telefonu
  (Samsung A34, Android 16) poruka iz Firebase konzole na temu `kurir` stiže i
  kad je aplikacija otvorena (traka) i kad je u pozadini (obaveštenje gore).
  Da traka ostaje proveren je samo testom, ne na telefonu.
- Otvoreni problemi:
  - Obaveštenje za sad šalje samo čovek, iz konzole (Messaging → New campaign
    → Topic `kurir`). Automatski će ga slati backend agent kad upiše novu
    porudžbinu (Faza 1).
  - Pri prvom pokretanju telefon je javio „FCM Registration failed" i nije se
    upisao na temu; posle ponovnog pokretanja je prošlo. Ako push prestane da
    stiže, prvo zatvoriti i ponovo otvoriti aplikaciju.
  - Obaveštenja idu u opštu Android grupu (bez posebnog zvuka i iskačućeg
    balončića). Posebna grupa bi tražila još jedan paket.
  - Samsung aplikaciji u pozadini gasi internet radi štednje baterije; lista
    se osveži čim se aplikacija otvori.
  - Flutter upozorava da `firebase_auth` i `firebase_core` koriste stari način
    uključivanja Kotlina — buduće verzije Fluttera to neće prihvatati. Za sad
    radi; rešava se nadogradnjom paketa kad izađu nove verzije.
- Sledeće: Faza 2 je gotova. Sledeći veliki korak je Faza 1 — backend agent;
  polazna tačka je nacrt u `docs/agent_prompt.md` i njegova otvorena pitanja.

## 2026-09-11 — Faza 1, prvi korak: temelj backend-a i cenovnik

- Urađeno:
  - Folder `backend/` (Node.js + TypeScript). Paketi odobreni:
    `@anthropic-ai/sdk`, `firebase-admin`, `typescript`, `tsx`, `@types/node`.
    Komande: `npm run provera` (provera koda), `npm test`, `npm run proba`.
  - Tajne (`backend/.env`, `backend/service-account.json`) dodate u
    `.gitignore` pre nego što su uopšte napravljene.
  - `src/firebase.ts` — veza sa bazom i push-om; jasna poruka ako fali ključ.
  - `src/porudzbine.ts` — upis porudžbine (status „nova") i push kuriru sa
    imenom i adresom; `src/proba_porudzbina.ts` — proba bez AI-ja.
  - `src/udaljenost.ts` — kilometri od radnje do mušterije po ruti za bicikl
    (OpenRouteService); loša adresa vraća poruku, ne ruši program.
  - `src/cena.ts` — cenovnik koji je korisnik potvrdio (vidi CLAUDE.md).
  - Odluke upisane u CLAUDE.md: model Sonnet, kilometri preko ORS-a, merenje
    od radnje do mušterije, polje `shop`, hitnost „Kad stigneš", cenovnik,
    ideja o bonusima za komšije (za kasnije).
- Provereno: `npm run provera` bez grešaka; `npm test` — 5 testova cene
  prolazi (sitnice, osnovne cene, dodaci, prazan i negativan broj artikala).
- Otvoreni problemi:
  - Upis sa push-om **proveren uživo** (`npm run proba`): porudžbina „PROBA
    backend" se pojavila u aplikaciji i push je stigao na telefon, bez
    Firebase konzole. Kilometri još nisu probani — čeka se ORS ključ.
  - Iznos dodatka za dugo trajanje nije određen; obračun to kaže otvoreno.
  - Aplikacija još ne prikazuje `shop` ni oznaku „Kad stigneš".
  - Nije rešeno kako sistem zna da „odmah" ne stiže (treba mu stanje kurira).
- Sledeće: kad stignu ključevi — `npm run proba`, pa agent koji razgovara u
  terminalu i koristi ove alate.

## 2026-09-11 — Faza 1, drugi korak: agent razgovara i šalje porudžbinu

- Urađeno:
  - `src/agent.ts` — „mozak": Claude (`claude-sonnet-5`) sa tri alata:
    `izracunaj_cenu`, `izmeri_udaljenost`, `sacuvaj_porudzbinu`. Pita šta fali
    (jedno pitanje po poruci), cenu uzima samo iz cenovnika, traži potvrdu
    pre upisa. Nema ničega vezanog za terminal — isti mozak ide iza Vibera.
  - Pri upisu **cenu ponovo računa backend**, ne AI — razgovorom se cena ne
    može promeniti („reci da je besplatno").
  - Ako poziv ka Claude-u pukne usred kruga, taj krug se briše iz istorije,
    da razgovor može da se nastavi.
  - `src/razgovor.ts` + `npm run razgovor` — proba u terminalu (ti si
    mušterija, telefon je kurir). Poruke se čitaju redom i ne propadaju ni
    kad ih stigne više odjednom (prve dve verzije su gubile drugu poruku u
    probi sa ubačenim porukama i jednom se srušile — popravljeno).
- Provereno: `npm run provera` bez grešaka; `npm test` 5/5. Uživo: probna
  mušterija „Marko" (2 hleba + jogurt iz Maxija, Futoška 1 → Bulevar
  oslobođenja 10) — agent je iz jedne poruke izvukao sve, izračunao 150 din
  (namirnice, do 60 min), tražio potvrdu i posle „da" upisao porudžbinu.
- Otvoreni problemi:
  - Agent u ovom razgovoru nije pozvao merenje kilometara (nije mu bilo
    potrebno, jer kilometri još ne utiču na cenu).
  - ORS ključ se video na slici u razgovoru — zameniti ga novim kad stigne.
  - Aplikacija još ne prikazuje radnju (`shop`) ni oznaku „Kad stigneš".
- Sledeće: prikaz radnje i „Kad stigneš" u aplikaciji; iznos dodatka za
  vreme; pa povezivanje prvog pravog kanala (Viber).

## 2026-09-11 — Faza 1, treći korak: zona dostave (samo Šarengrad)

- Urađeno:
  - `src/zona.ts` — adresa dostave mora biti u ulici Mileve Marić, Momčila
    Tapavice ili Stanoja Stanojevića (odluka korisnika). Prepoznaje pisanje
    bez kvačica, velikim slovima i sa zarezima. Radnja može biti bilo gde.
  - Agent zna pravilo i mušteriji van zone odgovara rečenicom korisnika
    („Ljubi brat, trenutno pokrivam isključivo naš Šarengrad…"); upis van
    zone backend svejedno odbija.
  - Odluka i razlog upisani u CLAUDE.md.
- Provereno: `npm run provera` bez grešaka; `npm test` 9/9 (4 nova za
  zonu). ORS ključ radi: Maxi, Futoška 1 → Mileve Marić 14 = 4,1 km biciklom.
- Otvoreni problemi:
  - **Merenje kilometara ne odbija nepostojeće adrese**: za „Ulica Koje Nema
    999" ORS je pogodio neko mesto u blizini i vratio 1,1 km. Pre nego što
    kilometri uđu u cenu, tražiti sigurnost pogotka (npr. da je pronađena
    baš adresa ili ulica, a ne samo grad).
  - Probna porudžbina „Marko" (Bulevar oslobođenja 10) upisana je pre
    pravila o zoni — u pravom radu ne bi prošla; označiti je kao dostavljenu.
  - C: disk je bio skoro pun (1,3 GB slobodno). Uz odobrenje korisnika
    obrisan je Gradle keš (~10 GB) → 11,8 GB slobodno. npm keš (1,5 GB)
    ostao je po želji korisnika. Prvo sledeće pravljenje Android aplikacije
    će trajati duže, jer Gradle ponovo skida ono što mu treba.
- Sledeće: popraviti sigurnost adrese kod merenja; prikaz radnje i „Kad
  stigneš" u aplikaciji; iznos dodatka za vreme; pa Viber.

## 2026-09-11 — Faza 1, četvrti korak: merenje odbija nepostojeće adrese

- Urađeno:
  - `src/udaljenost.ts` — nova provera `tacanPogodak`: ORS uvek nešto
    vrati, pa se pogodak prihvata samo ako je ulica, kućni broj ili radnja
    (ne grad, selo ni kraj) i ako svaka prava reč njegovog imena postoji u
    upisanoj adresi. ORS sad nudi 5 pogodaka, uzima se prvi tačan.
  - `sredi` iz `src/zona.ts` je sad izvezen i koristi se i ovde (ista
    obrada kvačica i velikih slova).
- Provereno: `npm run provera` bez grešaka; `npm test` 14/14 (5 novih).
  Uživo: Maxi, Futoška 1 → Mileve Marić 14 = 4,1 km; Futoška 1 → Stanoja
  Stanojevića 5 = 4,7 km; „Ulica Koje Nema 999" i „Kovilj mesara" (ranije
  pogođeno selo Kovilj) sad vraćaju „Ne mogu da nađem adresu".
- Otvoreni problemi:
  - Za ulice u Šarengradu ORS nema kućne brojeve, pa meri do sredine ulice
    — razlika je par stotina metara, za cenu nebitno.
  - Za „Maxi" nije sigurno da je pogođena baš ta prodavnica (Maxija ima
    više); ime prolazi, ali ne i ulica. Proveriti kad kilometri uđu u cenu.
  - ORS ključ još treba zameniti (korisnik će kasnije).
- Sledeće: prikaz radnje i „Kad stigneš" u aplikaciji; iznos dodatka za
  vreme; merenje trajanja kupovine (korisnik); pa Viber.

## 2026-09-11 — Aplikacija prikazuje radnju i „Kad stigneš"

- Urađeno:
  - `Order` ima polje `shop` (čita se iz baze; prazno ili pogrešnog tipa →
    prazan tekst) i hitnost `kad_stignes`.
  - Kartica: radnja (ikonica prodavnice) stoji iznad adrese; kad radnje nema,
    red se ne prikazuje. Detalji: red „Radnja", a kad je prazno — „Radnja
    nije uneta".
  - Oznaka „Kad stigneš" u prigušenoj boji (nije hitno).
  - Probni podaci: radnja na dve porudžbine, nova porudžbina „Ana Petrović"
    (baterije, Kad stigneš, 0 din).
  - CLAUDE.md i komentar u `backend/src/porudzbine.ts` usklađeni.
- Provereno: `flutter analyze` bez grešaka; `flutter test` 20/20 (3 nova).
  Stari test je morao da se spusti do dugmeta „Preuzeto", jer ga novi red
  gura ispod ivice malog probnog ekrana. Backend `npm test` 14/14.
- Nije provereno na telefonu — sledeći put kad se aplikacija pusti na
  Androidu, pogledati karticu prave porudžbine sa radnjom.
- Sledeće: iznos dodatka za vreme (korisnik); lista radnji sa koordinatama
  (korisnik šalje, ako se odobri); merenje trajanja kupovine; pa Viber.

## 2026-09-11 — Spisak radnji iz komšiluka

- Urađeno:
  - `backend/src/radnje.ts` — deset radnji sa Google Maps linkova korisnika
    (naziv, šta prodaje, adresa, koordinate, napomena). `poznataRadnja`
    prepoznaje radnju kad tekst počinje njenim nazivom (bez obzira na
    kvačice), da „Apoteka Benu" ne postane naša apoteka.
  - Merenje (`udaljenost.ts`) za poznatu radnju uzima koordinate iz spiska,
    bez pretrage.
  - Agent u uputstvu dobija spisak: predlaže radnju po onome što mušterija
    traži i upisuje je tačnim nazivom. Radnja van spiska je i dalje u redu.
- Provereno: `npm run provera` bez grešaka; `npm test` 18/18 (4 nova).
  Uživo: Podrum pića Zarko → Stanoja Stanojevića 5 = 0,3 km; Svetofor →
  Mileve Marić 14 = 0,8 km; Prodavnica jaja → Momčila Tapavice 3 = 0,4 km.
- Otvoreni problemi:
  - Agent sa spiskom još nije proban u pravom razgovoru (`npm run razgovor`).
  - Magic Walls: korisnik nije siguran da li su boje ili tapete.
  - Adresa Svetofora (Veterničke bitke 2) je najbliži kućni broj po mapi,
    ~90 m od tačke — koordinate su tačne, broj možda nije.
- Sledeće: proba razgovora sa spiskom; iznos dodatka za vreme; merenje
  trajanja kupovine; pa Viber.

## 2026-09-11 — Ispravke spiska radnji (korisnik)

- Svetofor je na **Olje Ivanjicki 13** (korisnik, iz Google Maps), ne
  Veterničke bitke 2 — to je bio pogodak po mapi. Koordinate ostaju iste.
- Otvoren problem „nije sigurno da je pogođen baš taj Maxi" je zatvoren:
  u komšiluku su „Maxi" i „Maxi sa mesarom", pa se ne mešaju.

## 2026-09-11 — Windows prozor kao telefon; Dragan Perić zamenjen

- Urađeno:
  - Windows prozor: širina 480, cela visina radnog dela ekrana, na sredini
    (`windows/runner/main.cpp`); širina ograničena na 360–640 i kod
    razvlačenja i kod maksimizovanja (`win32_window.cpp`, WM_GETMINMAXINFO).
    Bez paketa. Razlog upisan u CLAUDE.md.
  - Probna porudžbina „Dragan Perić" (korisnika nervira) zamenjena sa
    „Jelena Kovač": 4 stavke (hleb, mleko 1l, Plazma keks, ofingeri od
    kineza), Prodavnica mešovite robe → Momčila Tapavice 3, 150 din.
    Promenjeno u bazi (dokument `proba-2`, preko service account-a), u
    `tools/seed_firestore.py` (sad upisuje i `shop`) i u `test_orders.dart`.
- Provereno: `flutter analyze` bez grešaka; `flutter test` 20/20. Aplikacija
  napravljena i pokrenuta na Windowsu; izmeren prozor: 480 × 1040, ekran
  1920 × 1040 radnog dela → pun po visini, na sredini. Dragana više nema
  nigde u bazi.
- Sledeće: proba razgovora sa spiskom radnji; iznos dodatka za vreme;
  merenje trajanja kupovine; pa Viber.

## 2026-09-11 — Proba razgovora sa spiskom radnji

- Provereno (bez potvrde porudžbine, ništa nije upisano u bazu):
  - „10 jaja i mleko 1l, Mileve Marić 14" → agent predložio Prodavnicu
    mešovite robe, Mileve Marić 5 („oboje na jednom mestu").
  - „pola kile mlevenog iz Svetofora" → agent upozorio da se u Svetoforu
    meso ne kupuje i pitao za drugu radnju.
  - „buket cveća za ženu, do večeras" → Ana Maria 021, vrsta „specijalno".
- Primećeno: agent pita za broj telefona pre cene, iako kontakt sme biti
  prazan — na Viberu će broj ionako stizati sam. Ton ponekad čudan
  („Ljubi te, ali…"). Nije popravljano, samo zabeleženo.
- Sledeće: Viber (prvo proveriti uslove za nove Viber botove).

## 2026-09-11 — Prijemnica za Messenger i Instagram (+ glasovne poruke)

- Odluke (upisane u CLAUDE.md): Viber otpao (115 €/mes.); kanali Meta
  (Messenger, Instagram, pa WhatsApp); glas preko Groq-a (Whisper,
  besplatno); hosting Koyeb (besplatno, ne zaspi); SMS kasnije preko starog
  Android telefona; pozivi sa glasovnom porukom na kraju (Faza 6).
- Urađeno (bez novih paketa):
  - `src/meta.ts` — provera Metinog potpisa (lažne poruke se odbijaju),
    izvlačenje poruka iz Meta obaveštenja (tekst, glas, ostali prilozi;
    „echo" i potvrde čitanja se preskaču), deljenje odgovora na 2000 znakova,
    slanje odgovora (bez META_PAGE_TOKEN radi „na suvo" — ispis u terminal).
  - `src/glas.ts` — glasovna poruka → tekst preko Groq-a (srpski, nagoveštaj
    sa latinicom i imenima ulica). Bez ključa vraća razlog, ne puca.
  - `src/server.ts` + `npm run server` — prijemnica: Metina provera adrese,
    svaka mušterija ima svoj razgovor, poruke iste mušterije idu redom, ista
    poruka poslata dvaput se obrađuje jednom.
  - Agent: prepis glasa stiže sa oznakom „[glasovna poruka]" (pa zna da
    može biti grešaka), i piše bez markdown zvezdica.
- Provereno: `npm run provera` bez grešaka; `npm test` 26/26 (8 novih).
  Uživo na računaru sa lažnom „Metom": provera adrese sa dobrom rečju vraća
  broj, sa lošom 403; poruka bez potpisa 403; tekst → agent odgovorio
  (bez zvezdica); duplikat → jedan odgovor; glas bez Groq ključa → ljubazna
  poruka da napiše.
- Nije provereno: pravi prepis glasa (čeka GROQ_API_KEY), pravo slanje na
  Messenger/Instagram (čeka Facebook stranicu i Meta aplikaciju).
- Otvoreno: razgovori su samo u memoriji (restart ih briše); kurir ne dobija
  broj mušterije sa Messengera; agent jaja računa kao „osetljivo" (+100) —
  pitati korisnika; za Koyeb treba rešiti service-account.json (nije u
  repozitorijumu).
- Sledeće: korisnik pravi naloge (Facebook stranica, Instagram poslovni,
  developers.facebook.com, Groq, Koyeb); zatim postavljanje na Koyeb.

## 2026-09-11 — Facebook stranica + Instagram; Firebase ključ za hosting

- Korisnik napravio Facebook stranicu (za sad „Brzo nešto", ime se još
  bira) i povezao poslovni Instagram; pristup Instagram porukama u Inbox-u
  uključen. Upisano u CLAUDE.md.
- `backend/src/firebase.ts`: ključ za bazu može da stigne i kao podešavanje
  `FIREBASE_SERVICE_ACCOUNT` (ceo sadržaj service-account.json) — potrebno
  za Koyeb, jer fajl ne ide na GitHub. Na računaru i dalje radi fajl.
- Provereno: `npm run provera` bez grešaka; `npm test` 26/26. Uživo: sa
  ključem iz podešavanja baza je pročitana (7 porudžbina, samo čitanje); sa
  pogrešnim podešavanjem jasna poruka.
- Sledeće: korisnik proverava „Allow access to messages" u Instagram
  aplikaciji na telefonu, pravi nalog na developers.facebook.com i Koyeb;
  zatim postavljanje backend-a na Koyeb (javna adresa za Meta webhook).

## 2026-09-11 — Groq radi; priprema za Koyeb

- Korisnik napravio naloge (developers.facebook.com, Koyeb, Groq) i upisao
  GROQ_API_KEY u backend/.env.
- Urađeno:
  - `src/glas.ts`: `uLatinicu` — Whisper srpski piše ćirilicom i uprkos
    nagoveštaju, pa se prepis prebacuje u latinicu slovo po slovo (agent,
    provera zone i kurir rade na latinici). Bez paketa.
  - `package.json`: `npm start` (Koyeb ga pokreće), `engines: node >=22`,
    `tsx` premešten u dependencies — potreban je i u radu, a hosting posle
    instalacije briše dev pakete. Nije nov paket.
- Provereno: Groq ključ prihvaćen (whisper-large-v3 dostupan); probni
  snimak (Windows engleski glas čita srpsku rečenicu) prepisan i vraćen
  latinicom — iskrivljeno zbog engleskog izgovora, ali ceo put radi.
  `npm run provera` bez grešaka; `npm test` 27/27; baza se čita i posle
  ponovne instalacije (npm upozorio da protobufjs nije pokrenuo postinstall
  — ne smeta).
- Sledeće: push na GitHub (korisnik odobrava), pa Koyeb servis iz foldera
  `backend` sa ključevima kao tajnama; zatim Meta aplikacija i webhook.
