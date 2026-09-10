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
Messenger ide odvojeno preko Meta-inog Graph API-ja. Viber sam po sebi ima i
besplatan REST Bot API ako se kreće bez agregatora, pa se za SMS/WhatsApp
plati kasnije.

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
| Transkripcija glasa | **Whisper API ili Google Speech-to-Text** | Prevodi voice poruke u tekst pre nego što ih agent obradi |
| Multi-channel poruke | **Infobip** (SMS + Viber + WhatsApp) ili pojedinačno Viber Bot API (besplatno) | Jedna integracija umesto tri; Infobip je jak baš na Balkanu |
| Web dashboard | **jednostavna web app** (isti backend, npr. Next.js) | Praćenje i upravljanje dok se sedi za računarom |
| Hosting backend-a | **Railway ili Render** | WhatsApp/Viber/Meta traže javnu HTTPS adresu 24/7; kućni PC bi tražio dinamički DNS, port forwarding i SSL — nepotrebna komplikacija |

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
| 2 | Flutter aplikacija za kurira: aktivne porudžbine, predložena ruta, „preuzeto/dostavljeno", push za novu porudžbinu | |
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
  address: string,
  urgency: string,      // "normal", "hitno", "zakazano"
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

Kreće se ili od **Faze 1** (backend agent koji preuzima logiku iz Go servera)
ili direktno od **Faze 2** (Flutter aplikacija) — koji god deo je zanimljivije
videti „živ". Odluka je korisnikova; zapisati je ovde kad se donese.
