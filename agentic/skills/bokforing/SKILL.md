---
name: bokforing
description: >-
  Bokföring för användarens svenska aktiebolag i Dooer — vilka konton som finns (och saknas) i Dooers kontoplan,
  hur återkommande poster bokas (lön, arbetsgivardeklaration, tjänstepension, utländska kvitton, EU-tjänster med
  omvänd moms) och hur 1930 stäms av mot banken. Använd ALLTID när användaren frågar hur något ska bokföras, delar
  ett kvitto/faktura/orderbekräftelse/skärmdump från Dooer, säger att en verifikation "inte balanserar", jämför
  1930 med kontoutdraget, eller nämner moms, AGI, arbetsgivaravgifter, skattekontot, pension eller bokslut —
  även om ordet "bokföring" eller "Dooer" inte nämns.
---

# Bokföring i Dooer

Användaren driver ett litet svenskt AB (konsultverksamhet + egen app) och bokför själv i Dooer. Svara på svenska.

## Svarsformat

- Ge verifikationen som tabell: `| Konto | Debet | Kredit |`, med kontonamn så som Dooer visar dem.
- Kontrollera själv att debet = kredit innan du svarar. Avrunda moms till öre.
- Föreslå bara konton som finns i Dooer (se nedan). Föreslår du ett BAS-konto som inte finns, frågar användaren
  efter ett alternativ — ta det direkt.
- Om underlaget är en bild/PDF: läs beloppen därifrån, gissa inte. Har användaren skickat fel fil, säg det.

## Kontoplan i Dooer

Konton som bekräftat finns och används:

| Konto | Används till |
|---|---|
| 1630 | Skattekonto (används sällan, se AGI nedan) |
| 1930 | Företagskonto. Företagskortet dras härifrån |
| 2614 | Utgående moms omvänd skattskyldighet 25 % |
| 2640 / 2641 | Ingående moms |
| 2645 | Beräknad ingående moms på förvärv från utlandet |
| 2710 | Personalskatt |
| 2730 | Lagstadgade sociala avgifter och särskild löneskatt (Dooer har inte 2731) |
| 2893 | Skuld till aktieägare — vid köp med privat kort |
| 3740 | Öres- och kronutjämning |
| 4515 | Inköp av varor från annat EU-land |
| 4535 | Inköp av tjänster från annat EU-land (styr ruta 22) |
| 4599 | Omföring/justering omvänd moms (Dooer har inte 4598) |
| 5400 | Förbrukningsinventarier och förbrukningsmaterial |
| 5900 | Reklam och PR (Dooer har inte 5910) |
| 7200 | Löner till tjänstemän och företagsledare |
| 7410 | Pensionsförsäkringspremier |
| 7511 | Arbetsgivaravgifter för löner (Dooer har inte 7510) |

Kostnadskonton för t.ex. molntjänster, parkering och bankavgifter finns också — titta på hur tidigare liknande
verifikationer bokats om användaren delar dem, och föreslå samma konto.

Inte verifierat att de finns: 7530/7533 (särskild löneskatt), 2514. Fråga eller be användaren kolla innan du
förlitar dig på dem.

## Återkommande poster

### Utländskt företag som tar ut svensk moms

Apple, och andra stora bolag med svensk momsregistrering, fakturerar med 25 % svensk moms även om de sitter i
Irland. Då är det ett vanligt inköp:

| Konto | Debet | Kredit |
|---|---|---|
| kostnadskonto | netto | |
| 2640 | moms | |
| 1930 | | brutto |

**Dooer-fälla:** Dooers autofyll lägger ofta in omvänd moms (4515/4599/2645/2614) *ovanpå* ett sådant köp,
dessutom beräknad på bruttobeloppet. Står det moms på fakturan ska de raderna bort.

### Tjänst från EU-företag utan moms (omvänd skattskyldighet)

Säljaren har momsnummer och fakturan säger "reverse charge" / "not subject to VAT". Belopp X = SEK enligt banken.

| Konto | Debet | Kredit |
|---|---|---|
| kostnadskonto (t.ex. 5900) | X | |
| 1930 | | X |
| 4535 | X | |
| 4599 | | X |
| 2645 | 0,25·X | |
| 2614 | | 0,25·X |

4535/4599 tar ut varandra och finns bara för att fylla ruta 22. För varor från EU: 4515 i stället för 4535.
Om säljaren är privatperson utan momsnummer: bara kostnad mot 1930, ingen moms.

### Utländsk valuta

Använd alltid SEK-beloppet som banken drog (finns på kontoutdraget), inte en egen omräkning. Om fakturan bokats
före betalning och kursen ändrats: kursdifferens mot 3960 / 7960 (kontrollera att de finns).

### Kvitton och orderbekräftelser

En orderbekräftelse från en webbshop duger som verifikation om den har datum, belopp, vad som köpts och säljare.
Med 0 kr moms finns inget att dra av. Fråga om betalningen var företagskortet (1930) eller privat kort (2893).

### Lön

Användaren bokför lönen från lönesystemet i en verifikation per månad, ungefär:

| Konto | Debet | Kredit |
|---|---|---|
| 7200 | bruttolön | |
| 7511 | arbetsgivaravgift (31,42 %) | |
| 1930 | | nettolön |
| 2710 | | preliminärskatt |
| 2730 | | arbetsgivaravgift |
| 3740 | | öresutjämning |

### Arbetsgivardeklaration (AGI) / skattedragning

Betalningen till Skatteverket bokas **direkt mot 1930** på dragningsdagen, utan att gå via 1630. Beloppen tas från
AGI:n för föregående månad: ruta 487 (arbetsgivaravgifter) och ruta 497 (skatteavdrag).

| Konto | Debet | Kredit |
|---|---|---|
| 2710 | ruta 497 | |
| 2730 | ruta 487 | |
| 1930 | | summa |

Efter bokningen ska 2710 och 2730 vara nere på den senaste lönens belopp. Blir det en rest kvar: gå bakåt i
huvudboken för 2730 månad för månad och se var saldot efter dragningen inte blev 0. Små gamla differenser rättas
med 2730 debet mot 7511 kredit.

### Tjänstepension

Varje månadsbetalning: 7410 debet mot 1930 kredit. Det är rätt som det är.

Särskild löneskatt (24,26 % av årets pensionspremier) bokas **en gång i bokslutet**, inte per betalning:
7533 (eller 7530) debet mot 2514 kredit. Påminn om detta när det gäller bokslut eller årsskifte.

## Avstämning av 1930 mot banken

När användaren säger att 1930 inte stämmer med banken:

1. Räkna differensen (Dooers utgående saldo − bankens saldo samma dag).
2. Leta efter en enskild banktransaktion med exakt det beloppet som saknas i Dooer — oftast är det en
   Skatteverket-dragning eller en betalning utan kvitto.
3. Om ingen enskild post matchar: matcha rad för rad (bankrad ↔ Dooer-verifikation) och jämför belopp. Små avvikelser
   brukar vara valutaköp där fel belopp skrivits in (t.ex. kvittots belopp i stället för bankens).
4. Datum får skilja sig några dagar (kortköp bokas på köpdag, banken på dragningsdag) — det påverkar inte
   månadens utgående saldo om båda ligger i samma månad.

Bankens kontoutdrag klistras ofta in med dubblerade rader (varje fält två gånger) — läs förbi det.
