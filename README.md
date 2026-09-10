# Aj uzmi mi

Mikro-dostava u Novom Sadu — ono što se kaže kad tražiš sitnicu usput
(„aj uzmi mi hleb kad se vraćaš").

Sistem se sastoji iz tri dela: mušterija poruči preko bilo kog kanala (Viber,
WhatsApp, SMS, sajt…), AI agent na serveru razume poruku, izračuna cenu i
isplanira rutu, a kurir na terenu dobije jasnu instrukciju na telefon.

## Šta je u repozitorijumu

| Folder | Šta je |
|---|---|
| `app/` | Kurirska Flutter aplikacija — aktivne porudžbine, predložena ruta, „preuzeto/dostavljeno" |
| `firestore.rules` | Pravila pristupa bazi |
| `CLAUDE.md` | **Izvor istine o projektu** — arhitektura, odluke i razlozi iza njih |
| `APP_NOTES.md` | Dnevnik rada: šta je urađeno u kom koraku i šta je provereno |

## Pokretanje aplikacije

```
cd app
flutter run
```

Aplikacija se povezuje na Firebase projekat `aj-uzmi-mi` (Firestore kolekcija
`orders`, region `europe-west3`).

## Stanje

Faza 2 od šest — kurirska aplikacija radi i čita bazu uživo. Prijava, push
notifikacije i backend agent tek dolaze. Plan svih faza je u `CLAUDE.md`.
