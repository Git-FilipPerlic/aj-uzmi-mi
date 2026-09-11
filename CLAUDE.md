# AI Dispečer — dokumentacija projekta

Dispečerski agent za mikro-dostavu (Novi Sad), nadogradnja na postojeći plan
(Viber bot + Go server). Umesto bota koji prepoznaje ključne reči, cilj je
pravi AI agent koji razume prirodan jezik, razgovara sa mušterijom, planira
rutu, računa cenu i tebi na terenu šalje jasne instrukcije — bez obzira da li
je porudžbina stigla sa sajta, SMS-a, Vibera, WhatsApp-a, Messengera ili (u
kasnijoj fazi) telefonskim pozivom.

---

## Pravila rada za AI asistenta na ovom projektu

Preneto sa projekta `e-vent`, gde se pokazalo da drži kvalitet. **Ovaj fajl je
izvor istine o projektu — pročitati ga u celini pre bilo kakve izmene koda.**

1. **Raditi u malim koracima.** Jedan feature = jedna izmena = jedna provera.
2. **Posle svake izmene pokrenuti proveru koda i testove** i prijaviti
   rezultat. Ako ne prolazi, popraviti pre nego što se ide dalje.
3. **Ne dodavati pakete bez pitanja.** Svaki nov paket je odluka korisnika.
4. **Ne izmišljati feature-e.** Radi se ono što je u fazama niže ili što
   korisnik izričito traži. Ako nešto nedostaje — pitati, ne pretpostaviti.
5. **Ne dirati arhitekturu usput.** Predlog za promenu se iznosi kao predlog,
   pa se čeka odgovor.
6. **Ne refaktorisati kod koji nije tema trenutnog zadatka.**
7. **Svako polje može biti prazno.** Za svaki podatak predvideti prazno
   stanje; aplikacija nikad ne sme da pukne na praznom podatku.
8. **Posle završenog feature-a upisati kratku belešku u `APP_NOTES.md`**
   (šta je urađeno, šta je provereno, šta je sledeće).
9. **Objašnjavati jednostavno.** Korisnik nije profesionalni programer — reći
   šta rešenje radi i zašto, bez nepotrebnog žargona.
10. **Zapisivati i razloge, ne samo odluke.** Kad korisnik nešto odbije ili
    zatraži, u ovaj fajl ide i obrazloženje — da se za pola godine ne
    „popravi" nazad.

---

## 1. Šta agent treba da radi

- **Prijem porudžbina** sa više kanala odjednom (sajt, SMS, Viber, WhatsApp,
  Messenger), sa jednim zajedničkim „mozgom" iza svih njih — mušterija ne
  primeti razliku u kvalitetu odgovora bez obzira odakle piše.
- **Razgovor sa mušterijom**: postavlja pitanja kad nešto fali (adresa,
  hitnost, tačan artikal), nudi opcije (kao što već radi Viber bot), potvrđuje
  porudžbinu pre nego što je prosledi dalje.
- **Razumevanje glasovnih i slikovnih poruka**: mušterija može da pošalje
  glasovnu poruku („Uzmi mi hleb i mleko iz Maxija") ili sliku (npr. spisak
  napisan rukom, ili fotografiju artikla) i agent to pretvara u strukturisanu
  porudžbinu.
- **Računanje cene** na osnovu težine/udaljenosti/hitnosti (logika koja već
  postoji iz MVP-a, samo sad kao „alat" koji agent poziva umesto fiksnog koda).
- **Pravljenje liste za kupovinu** kad porudžbina uključuje više artikala iz
  iste ili više radnji.
- **Planiranje rute** — kombinuje aktivne porudžbine u optimalan redosled,
  uzima u obzir hitnost i geografsku blizinu.
- **Instrukcije kuriru na terenu** — agent porudžbine pretvara u jasnu, kratku
  poruku („Idi kod Kovilj mesare po 1kg mlevenog, zatim Bulevar Kneza Miloša
  45, hitno") koja stiže na telefon dok se vozi.
- **(Kasnija faza) Telefonski poziv** — mušterija zove broj, agent (ili
  transkript poziva) izvlači ključne podatke i odmah šalje instrukciju, bez
  vođenja razgovora.

Sve gore navedeno već postoji delimično u MVP planu (Viber bot + Go server) —
ova dokumentacija ga **proširuje, ne zamenjuje od nule**.

## 2. Arhitektura — kako se sve uklapa

Tri sloja:

**Sloj 1 — Kanali (ulaz poruka).** Svaki kanal (Viber, WhatsApp, Messenger,
SMS, sajt, telefon) prima poruku i prosleđuje je na jedno mesto — backend.
Umesto posebne integracije za svaki kanal, najisplativije je koristiti
**jednog agregatora** koji već ima Viber + WhatsApp + SMS u jednom API-ju —
**Infobip** je vodeća platforma za ovaj region (balkanska firma, dobro pokriva
srpske mobilne operatere) i ima jedinstven „Messages API" za sve kanale.
Messenger ide odvojeno preko Meta-inog Graph API-ja. **Viber bot više nije
besplatan** (od 5.2.2024. samo po ugovoru, 115 € mesečno) — vidi odluku o
kanalima u odeljku 7.

**Sloj 2 — Agent (mozak).** Backend servis prima poruku iz bilo kog kanala,
prosleđuje je AI agentu (Claude API) zajedno sa kontekstom porudžbine
(istorija razgovora, cenovnik, radnje, aktivne rute). Agent ima na
raspolaganju **alate** (funkcije) koje sam poziva kad zatreba:
`izracunaj_cenu`, `planiraj_rutu`, `napravi_listu_za_kupovinu`,
`sacuvaj_porudzbinu`, `posalji_kuriru`.

Ovo je suštinska razlika u odnosu na sadašnji bot: umesto ručno pisanih
„if hitno u poruci → ASAP", agent sam zaključuje iz konteksta i ume da vodi
prirodan razgovor.

Za **glasovne poruke**: audio prvo ide kroz uslugu za prepoznavanje govora —
Claude ne „sluša" audio direktno, pa je potreban jedan korak pre njega
(Whisper API ili Google Speech-to-Text; oba rade i za srpski). Za **slike**:
Claude prima sliku direktno, bez dodatnog koraka.

**Sloj 3 — Prikaz.** Isti backend servisira i **web dashboard** (za računarom)
i **Flutter aplikaciju** na telefonu (na terenu). Oba su samo „prozori" u istu
bazu porudžbina — kad agent kreira instrukciju, ona se u realnom vremenu
pojavi i na jednom i na drugom, bez dupliranja logike.

```
Viber / WhatsApp / Messenger / SMS / Sajt / (Telefon)
                    │
                    ▼
        Infobip / Meta API / Twilio  (ulazne poruke)
                    │
                    ▼
     BACKEND (Node.js) — AI agent (Claude API + alati)
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
   Baza (Firestore)      Push notifikacije (FCM)
        │                       │
        ▼                       ▼
  Web dashboard           Flutter app (kurir — na terenu)
```

## 3. Preporučena tehnologija

| Deo sistema | Preporuka | Zašto |
|---|---|---|
| Kurirska aplikacija (teren) | **Flutter** | Radi na Androidu, jedan kod za kasniji web/iOS |
| Baza podataka | **Firebase Firestore** | Real-time sinhronizacija bez dodatnog posla — čim agent upiše porudžbinu, aplikacija je odmah vidi |
| Push notifikacije | **Firebase Cloud Messaging** | Standard za Flutter, besplatno u ovoj skali |
| Backend / agent servis | **Node.js + TypeScript** | Anthropic (Claude) i sve messaging platforme imaju najbolju podršku baš za JS/TS |
| AI agent | **Claude API** (Sonnet za razgovor/rezonovanje) | Razume prirodan jezik, čita slike nativno, poziva „alate" za cenu/rutu |
| Transkripcija glasa | **Groq (Whisper Large v3)** — besplatno, bez kartice, do 2.000 poruka dnevno | Prevodi voice poruke u tekst pre nego što ih agent obradi; Claude zvuk ne prima (proveren Models API, 11.09.2026.) |
| Multi-channel poruke | **Meta** (Messenger, Instagram, WhatsApp) — besplatno za odgovore u roku 24 h | Viber otpao (115 €/mes.), Infobip se plaća; vidi odluku o kanalima u odeljku 7 |
| Web dashboard | **jednostavna web app** (isti backend, npr. Next.js) | Praćenje i upravljanje dok se sedi za računarom |
| Hosting backend-a | **Render** (besplatno, bez kartice, 750 h mesečno) + besplatan „budilnik" (UptimeRobot / cron-job.org) koji ga poziva na 5–10 min, jer Render zaspi posle 15 min bez saobraćaja. Odluka 11.09.2026.: Koyeb je kupio Mistral i novi nalozi ne mogu da prave servis; Railway se plaća | WhatsApp/Viber/Meta traže javnu HTTPS adresu 24/7; kućni PC bi tražio dinamički DNS, port forwarding i SSL — nepotrebna komplikacija |

**Napomena o postojećem Go serveru:** ništa se ne baca — logika za cene, rute
i zone prelazi direktno u agent kao „alati", samo se piše u Node.js/TS umesto
Go, jer se tu najlakše kači na Claude API i na messaging platforme. Ostanak na
Go-u je izvodljiv, ali sa manje gotovih recepata za multi-channel integracije.

Windows 10 nije prepreka: Android Studio + Flutter rade odlično na Windowsu, a
backend se piše lokalno pa se „šalje" na Railway/Render — ne traži da server
bude upaljen na kućnom računaru.

## 4. Fazni plan

Svaka faza je **samostalno korisna** — ne mora se čekati Faza 6 da bi sistem
štedeo vreme.

| Faza | Šta | Status |
|---|---|---|
| 0 | Viber bot + Go server, cash-on-delivery, jedan kanal (radni prototip logike) | u toku |
| 1 | Backend agent (Node.js + Claude API) preuzima logiku iz Faze 0 kao alate; i dalje samo Viber, ali razgovor vodi pravi AI | |
| 2 | Flutter aplikacija za kurira: aktivne porudžbine, predložena ruta, „preuzeto/dostavljeno", push za novu porudžbinu | gotovo (11.09.2026.) |
| 3 | Dodavanje kanala: WhatsApp, Messenger, SMS, forma na sajtu | |
| 4 | Razumevanje voice i image poruka (transkripcija + Claude vision) | |
| 5 | Web dashboard u browseru, paralelno sa aplikacijom | |
| 6 | Telefonski pozivi: broj koji prima poziv, transkribuje razgovor i šalje instrukciju | |

**Uz Fazu 6 stoje dva upozorenja:** traži telefonski servis (npr. Twilio
Voice) i **pažljivu proveru kvaliteta transkripcije za srpski** pre oslanjanja
u produkciji. Takođe treba proveriti **domaće propise o snimanju poziva** —
pravila o saglasnosti se razlikuju — pre puštanja u rad sa pravim mušterijama.

## 5. Osnovni podaci koje sistem prati

- **Porudžbina**: mušterija, kanal (odakle je stigla), stavke/lista za
  kupovinu, adresa, hitnost, cena, status
  (nova → potvrđena → preuzeta → dostavljena)
- **Mušterija**: ime, kontakt, istorija porudžbina, omiljene radnje
- **Kurir** (za sad jedan): trenutna lokacija/ruta, aktivne porudžbine
- **Ruta**: redosled porudžbina, procenjeno vreme

### Oblik dokumenta u Firestore kolekciji `orders`

```
{
  customerName: string,
  customerContact: string,
  channel: string,      // "viber", "whatsapp", "sms", "web", "messenger"
  items: array of strings,
  shop: string,         // radnja: naziv i adresa, npr. "Maxi, Futoška 1"
  address: string,
  urgency: string,      // "normal", "hitno", "zakazano", "kad_stignes"
  price: number,
  status: string,       // "nova", "potvrdjena", "preuzeta", "dostavljena"
  routeOrder: number,
  createdAt: timestamp
}
```

## 6. Kurirska aplikacija — prva verzija (Faza 2)

Aplikacija se zove **„Dispečer"**, povezuje se na Firebase (Firestore + Cloud
Messaging).

1. **Prijava** — Firebase Authentication, mejl i lozinka.
2. **Aktivne porudžbine** — lista kartica; svaka pokazuje ime mušterije,
   adresu, listu artikala, cenu, hitnost (Normal / Hitno / Zakazano) i status.
   Čita se **real-time** iz kolekcije `orders`.
3. **Detalji porudžbine** — dugmad „Preuzeto" i „Dostavljeno" menjaju status u
   Firestore.
4. **Push notifikacija** kad stigne porudžbina sa statusom `nova` — prikazuje
   ime mušterije i adresu.
5. **Predložena ruta** — lista porudžbina sortirana po `routeOrder`. **Rutu
   računa backend, aplikacija je samo prikazuje.**
6. **Jednostavan, čitljiv dizajn** (Material 3), bez nepotrebnih animacija —
   prioritet je da se brzo čita **dok se vozi bicikl**.

## 7. Sledeći korak

**Odluka (10.09.2026.): kreće se od Faze 2 — Flutter aplikacije za kurira.**
Razlog: to je deo koji se najbrže vidi „živ" i najbrže počne da štedi vreme na
terenu, dok backend agent (Faza 1) može da sačeka.

Unutar Faze 2 dogovoren je redosled: **prvo ekrani sa test podacima, pa tek
onda Firebase.** Razlog: da se raspored ekrana proveri u ruci pre nego što se
kod veže za bazu — prepravka ekrana je jeftina, prepravka ekrana + baze nije.

Zbog toga aplikacija za sad drži porudžbine u memoriji, u klasi `OrderStore`
(`app/lib/data/order_store.dart`). **Kad dođe Firebase, menja se samo ta
klasa** — ekrani je koriste preko istog skupa metoda i ne znaju odakle podaci
stižu.

### Ime i identifikatori (10.09.2026.)

Usluga se zove **„Aj uzmi mi"** — šaljiv naziv iz srpskog slenga, ono što se
kaže kad tražiš sitnicu usput („aj uzmi mi hleb kad se vraćaš"). Na engleskom
bi bilo *could you just run and get me…*. Naziv je namerno domaći i neformalan
jer ga vide mušterije; „Dispečer" ostaje interni naziv sistema.

- Firebase projekat: **`aj-uzmi-mi`** (broj projekta 789558655673)
- Firestore baza: region **`europe-west3`** (Frankfurt) — bira se samo jednom
  i ne može se kasnije promeniti; izabran jer je najbliži Novom Sadu
- Android package ID kurirske aplikacije: **`rs.ajuzmimi.kurir`** — posle
  objavljivanja na Google Play se NIKAD ne menja. Reč „kurir" ostavlja mesta
  da aplikacija za mušterije kasnije bude `rs.ajuzmimi.app`.
- Naziv ispod ikonice na telefonu: **Aj uzmi mi**
- Facebook stranica (napravljena 11.09.2026.):
  `https://www.facebook.com/profile.php?id=61593946365520` — za sad se
  zove **„Brzo nešto"** (korisnik još bira ime usluge). Naziv i @adresa se
  mogu menjati, veza sa backendom ide preko broja i ključa. Instagram
  (poslovni nalog) je povezan sa stranicom i pristup porukama u Inbox-u je
  uključen.

### Gde stoji kod

Kod je u **javnom** GitHub repozitorijumu
`https://github.com/Git-FilipPerlic/aj-uzmi-mi` (korisnik ga je otvorio
11.09.2026.). Bio je privatan dok su pravila baze bila otvorena; od
11.09.2026. su stegnuta. Pre otvaranja je proverena cela istorija: nijedan
ključ ni tajni fajl nikad nije poslat. **Sve u repozitorijumu (i CLAUDE.md,
APP_NOTES.md, cenovnik) vidi svako** — ključevi idu samo u `backend/.env` i u
tajne na hostingu. Glavna grana je `main` (jednom je greškom preimenovana u
`backend` i vraćena).

`firebase_options.dart` i `google-services.json` **jesu** u repozitorijumu, i
tako treba: bez njih se projekat ne može pokrenuti na drugom računaru, a ti
ključevi nisu tajna — svako ih može izvući iz instalirane aplikacije. Bazu
čuvaju pravila pristupa, ne skrivanje ključeva.

### Stanje aplikacije (`app/`)

Gotovo: lista porudžbina, detalji sa dugmadima „Preuzeto" i „Dostavljeno",
predložena ruta po polju `routeOrder`, i **živa veza sa Firestore bazom** —
`FirestoreOrderStore` sluša kolekciju `orders` neprekidno, pa se promena vidi
odmah, bez osvežavanja. Firestore usput čuva kopiju podataka na telefonu, pa
lista radi i kad nestane signal.

Za probu je u bazi pet izmišljenih porudžbina; ubacuje ih
`tools/seed_firestore.py` (bez ijednog dodatnog paketa, preko Firestore REST
API-ja). Skripta traži mejl i lozinku kurira, jer baza pušta samo prijavljene.

**Prijava (11.09.2026.):** kurir se prijavljuje mejlom i lozinkom (Firebase
Authentication). U aplikaciji **nema registracije**, a u Firebase konzoli je
**isključeno samostalno pravljenje naloga** (Authentication → Settings → User
actions). Nalozi se prave samo ručno u konzoli (Authentication → Users → Add
user). Razlog: javni ključ aplikacije može svako da izvuče, pa bi bez toga bilo
ko mogao sebi da napravi nalog i čita porudžbine.

**Pravila baze** (`firestore.rules`): čita i piše samo prijavljen korisnik.
To znači „samo kurir" isključivo zato što je samostalno pravljenje naloga
isključeno — **ne uključivati ga ponovo** bez promene pravila.

**Push obaveštenja (11.09.2026.):** telefon se po prijavi upisuje na Firebase
temu `kurir`, a po odjavi se ispisuje. Poruku na tu temu za sad šalje čovek iz
Firebase konzole; kasnije će je slati backend agent kad upiše novu porudžbinu.
Tema umesto pojedinačnih adresa telefona, jer ništa ne mora da se čuva u bazi
dok je kurir jedan. Obaveštenje dok je aplikacija otvorena je traka koja
**ostaje dok je kurir ne skloni** — kratka traka se u vožnji propušta.
Push radi samo na Androidu; Windows verzija ga preskače.

**Windows prozor (11.09.2026.):** uzak (480) i preko cele visine ekrana, na
sredini; širina se ne može razvući van 360–640, ni maksimizovanjem. Podešeno
u `windows/runner/main.cpp` i `win32_window.cpp`, bez paketa. Razlog (reči
korisnika): kartice razvučene preko cele širine „ne izgledaju kao nijedan
program koji znam" — pregledno je kad izgleda kao telefon.

`android/gradle.properties` ima `kotlin.incremental=false` namerno: projekat je
na disku D:, Flutter paketi na C:, i Kotlin-ov keš zbog toga ruši Android build.

**Faza 2 je gotova.** Sledeće je Faza 1 (backend agent); nacrt uputstva za
agenta je u `docs/agent_prompt.md`, sa otvorenim pitanjima na dnu.

### Faza 1 — backend agent (počet 11.09.2026.)

Kod je u `backend/` (Node.js + TypeScript, pokreće se preko `tsx`).
Paketi (odobreni): `@anthropic-ai/sdk`, `firebase-admin`, `typescript`, `tsx`,
`@types/node`. Provera koda: `npm run provera`.

- **Tajne** su u `backend/.env` (Claude i ORS ključ) i
  `backend/service-account.json` (pun pristup bazi) — oba su u `.gitignore`.
- **Model:** `claude-sonnet-5`, jer odeljak 3 kaže Sonnet za razgovor — dovoljan
  za razgovor sa mušterijom, a jeftiniji i brži od najjačeg modela.
- **Prvi cilj:** razgovor u terminalu na računaru (bez Vibera) → agent upiše
  porudžbinu → ona se pojavi na telefonu i stigne push. Kanali se kače posle.
- **Cena** zavisi od hitnosti, artikala i **kilometara** (odluka korisnika).
  Iznose daje korisnik — ne izmišljati ih.
- **Kilometri** se računaju preko **OpenRouteService**: besplatan ključ (oko
  2000 upita dnevno), evropska firma, daje i adresu→koordinate i put po
  ulicama. Odbačeni: Google Maps (traži karticu, posle besplatnog dela se
  plaća) i vazdušna linija (besplatno, ali netačno za bicikl po ulicama).
- **Udaljenost se meri od radnje do mušterije** (odluka korisnika), po ruti za
  **bicikl** (ORS profil `cycling-regular`), jer kurir vozi bicikl. Ako
  mušterija ne kaže tačno koju radnju, agent pita.
- **Polje `shop`** (dodato 11.09.2026.): porudžbina pamti radnju. Razlog:
  kuriru je radnja prva stvar koju treba da zna („idi kod Kovilj mesare po…"),
  a treba i za merenje udaljenosti. Aplikacija ga prikazuje na kartici
  (iznad adrese, a red se skriva kad radnje nema) i u detaljima („Radnja nije
  uneta" kad je prazno).
- **Nova hitnost „Kad stigneš"** (naziv dao korisnik, u bazi `kad_stignes`)
  za sitnice i posao bez žurbe — pored Normalno/Hitno/Zakazano. Aplikacija je
  prikazuje prigušenom bojom, jer nije hitno.
- **Zona dostave: samo Šarengrad** (odluka korisnika, 11.09.2026.) — adresa
  dostave mora biti u ulici Mileve Marić, Momčila Tapavice ili Stanoja
  Stanojevića; radnja može biti bilo gde. Ovo sužava „Novi Sad" iz odeljka 1
  za početnu fazu. Proverava se u backend-u (`src/zona.ts`), ne samo u
  uputstvu agentu, da nagovaranje u razgovoru ne može da propusti porudžbinu.
  Mušteriji van zone agent odgovara rečenicom korisnika iz nacrta: „Ljubi
  brat, trenutno pokrivam isključivo naš Šarengrad…"
- **Spisak radnji iz komšiluka** (`src/radnje.ts`, 11.09.2026.): deset radnji
  koje je korisnik poslao kao Google Maps linkove — većina u nizu Mileve Marić
  1–5, plus Svetofor i Magic Walls. Svaka ima tačne koordinate, šta prodaje i
  napomenu (npr. Svetofor: „ne kupuješ meso tamo"). Agent ih zna i predlaže,
  a merenje za njih uzima mesto iz spiska umesto pretrage. Razlog: pretraga
  radnju bez imena (jaja, mešovita roba) uopšte ne nađe. (Strah da će „Maxi"
  pogoditi pogrešan Maxi korisnik je odbacio: u komšiluku se jedan zove
  „Maxi", a drugi „Maxi sa mesarom", pa se ne mešaju.) Radnja van spiska je
  i dalje dozvoljena. Adresu radnje korisnik kopira iz Google Maps — ne
  pogađati je po mapi (tako je Svetofor pogrešno dobio Veterničke bitke 2).

- **Kanali (odluka korisnika, 11.09.2026.):** Viber otpada za sad — bot se
  od 2024. pravi samo po ugovoru, 115 € mesečno (oko 90 porudžbina mesečno
  samo da se pokrije). Idu **besplatni kanali sa glasovnim porukama:
  WhatsApp, Instagram i Messenger** — sva tri preko jednog Meta naloga;
  odgovori mušteriji koja je prva pisala su besplatni u roku od 24 h.
  **TikTok** ako njegov API za poruke proradi za Srbiju (u EU nije dostupan,
  a glasovne poruke preko API-ja nisu potvrđene). Razlog: korisnik hoće
  besplatne opcije, a mušterije moraju moći da pošalju glasovnu poruku.
  Web app (besplatan Firebase hosting) ostaje opcija; mejl je na kraju.
  Redosled: Messenger + Instagram → WhatsApp (traži poseban broj/SIM) →
  **SMS preko starog Android telefona** sa SIM karticom i besplatnom
  aplikacijom-prosleđivačem (plaća se samo tarifa; korisnik za sad nema
  telefon) → **pozivi sa ostavljanjem glasovne poruke** (Faza 6, telefonski
  servis se plaća; korisnik to želi — „da ljudi zovu na aparat").

#### Cenovnik (potvrdio korisnik 11.09.2026.)

Cene su po vrsti posla i brzini, u dinarima:

| Šta | Kad | Cena |
|---|---|---|
| Sitnica („donesi kad god") | kad stigneš | prvi artikal besplatno, svaki sledeći +50 |
| Namirnice iz radnje | u roku od 60 min | 150 |
| Piljara / radnja | odmah, pa odmah nazad | 200 — ako ne stiže, ponuditi kasnije i jeftinije |
| Cigare | odmah | 150 |
| Specijalno (cvećara, kafa i kolač — pipavo, prosipa se) | kad stigneš | 200 |
| Specijalno | hitno | 200 + 150 = 350 |

Dodaci:
- **Teško** (više od 2 L tečnosti, 5 L, kilo krompira i više): +150
- **Osetljivo** (lomljivo, ne sme da se ošteti, npr. komplet kozmetike): +100
- **Dugo traje** (više radnji, daleko): dodatak po vremenu — iznos još nije
  određen. Razlog (reči korisnika): „nije samo što je daleko nego što traje;
  za to vreme ja možda mogu raditi neku drugu porudžbinu". Vreme = vožnja po
  ORS-u + procena kupovine po radnji.
- **PODSETNIK za korisnika:** izmeriti koliko stvarno traje jedna kupovina
  (vožnja 500 m, vezivanje bicikla, traženje, 5 artikala, red na kasi,
  pakovanje). List za merenje: `docs/merenje_vremena.md`. Dok ga nema, agent
  računa oko 10 min po radnji — privremena procena, zameniti pravim brojem.

#### Ideje za kasnije (ne praviti bez dogovora)

- **Bonusi za komšije**: kad se ostvari određeni profit, deliti bonuse i
  slične pogodnosti da se komšije stimulišu (ideja korisnika, 11.09.2026.).
