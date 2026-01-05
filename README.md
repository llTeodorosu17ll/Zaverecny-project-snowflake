# Zaverecny-project-snowflake
Toto je záverečný projekt študentov UKF: Fedir Vernyhorov a Oleksandr Shtanov

---

ELT proces a dátový sklad v Snowflake – World Bank Indicators

Tento projekt sa zameriava na návrh a implementáciu ELT procesu v prostredí Snowflake. Výsledkom je dátový sklad postavený na dimenzionálnom modeli typu Star Schema a sada analytických vizualizácií. Projekt pracuje výhradne s dátami zo Snowflake Marketplace, konkrétne s datasetom World Bank Indicators.

Cieľom projektu je ukázať celý proces práce s dátami – od pochopenia zdrojovej štruktúry, cez návrh dátového modelu až po analytické dotazy a vizualizácie.

---

1. Úvod a popis zdrojových dát

Analyzované dáta pochádzajú zo Svetovej banky (World Bank) a predstavujú dlhodobé časové rady socio-ekonomických a demografických ukazovateľov pre jednotlivé krajiny sveta. Dataset bol zvolený najmä pre svoju dôveryhodnosť, šírku pokrytia a vhodnosť na analytické spracovanie.

Dáta sú dostupné prostredníctvom Snowflake Marketplace v databáze SNOWFLAKE_PUBLIC_DATA_FREE. Obsahujú informácie o populácii, demografickej štruktúre a ďalších indikátoroch sledovaných naprieč desiatkami rokov.

Biznis proces, ktorý tieto dáta podporujú, spočíva v analytickom hodnotení vývoja populácie a porovnávaní krajín v čase. Takéto analýzy sú využiteľné napríklad pri strategickom plánovaní, demografických štúdiách alebo hodnotení globálnych trendov.

Dataset obsahuje:
- časové rady indikátorov,
- identifikátory krajín a indikátorov,
- numerické hodnoty,
- metadáta opisujúce význam jednotlivých ukazovateľov.

Analýza je zameraná najmä na vývoj podielu populácie podľa pohlavia, vekovú štruktúru obyvateľstva a porovnanie vybraných krajín.

---

1.1 Popis zdrojových tabuliek

WORLD_BANK_TIMESERIES  
Táto tabuľka obsahuje samotné merané hodnoty indikátorov. Každý záznam reprezentuje hodnotu jedného indikátora pre konkrétnu krajinu a dátum.

WORLD_BANK_ATTRIBUTES  
Táto tabuľka slúži ako zdroj metadát k indikátorom. Obsahuje názvy indikátorov, jednotky, frekvenciu a zdroj dát.

Vzťah medzi tabuľkami je realizovaný prostredníctvom identifikátora indikátora (VARIABLE).

ERD diagram pôvodnej dátovej štruktúry je uložený v priečinku /img.

---

2. Návrh dimenzionálneho modelu

Na základe analytických potrieb bol navrhnutý dimenzionálny model typu Star Schema. Model pozostáva z jednej faktovej tabuľky a troch dimenzií. Návrh vychádza zo zásad Kimballovej metodológie.

---

2.1 Faktová tabuľka

fact_world_bank_metrics

Faktová tabuľka uchováva merané hodnoty indikátorov a odkazy na jednotlivé dimenzie. Každý záznam reprezentuje jednu hodnotu indikátora v danom čase a pre konkrétnu krajinu.

Hlavné stĺpce:
- fact_id – primárny kľúč,
- country_id – väzba na dimenziu krajín,
- indicator_id – väzba na dimenziu indikátorov,
- date_id – väzba na časovú dimenziu,
- value – hodnota indikátora,
- yearly_rank – poradie krajiny v rámci daného indikátora a roka.

Vo faktovej tabuľke je použitá window function ROW_NUMBER(), ktorá umožňuje porovnanie krajín medzi sebou v rámci rovnakého roka.

---

2.2 Dimenzie

dim_country  
Dimenzia krajín obsahuje zoznam krajín identifikovaných pomocou GEO_ID. Ide o statickú dimenziu typu SCD Typ 0.

dim_indicator  
Dimenzia indikátorov uchováva metadáta o jednotlivých ukazovateľoch, ako je názov, jednotka a zdroj. Táto dimenzia je tiež typu SCD Typ 0, keďže opis indikátorov sa v čase nemení.

dim_date  
Časová dimenzia obsahuje dátum, rok a dekádu. Slúži na časové analýzy a sledovanie trendov.

Diagram hviezdicového modelu je uložený v priečinku /img.

---

3. ELT proces v Snowflake

Projekt využíva ELT prístup, pri ktorom sú transformácie realizované priamo v databáze Snowflake.

---

3.1 Extract

Dáta boli extrahované priamo zo Snowflake Marketplace pomocou SQL príkazov typu CREATE TABLE AS SELECT. Zdrojové tabuľky boli skopírované do staging vrstvy projektu.

---

3.2 Load

Zo staging tabuliek boli následne vytvorené dimenzné tabuľky a faktová tabuľka. Počas tohto kroku boli vytvorené surrogate keys a zabezpečené väzby medzi tabuľkami.

---

3.3 Transform

Transformačná fáza zahŕňala deduplikáciu dát, úpravu dátových typov, tvorbu časovej dimenzie a výpočet poradia krajín pomocou window functions.

Použitá window function umožňuje jednoduché porovnanie krajín v rámci rovnakého indikátora a roka, čo je dôležité pre následnú analytickú vrstvu.

---

4. Vizualizácia dát

Na základe dátového skladu bolo vytvorených päť vizualizácií, ktoré odpovedajú na hlavné analytické otázky projektu:

- Top 10 krajín podľa podielu mužskej populácie v poslednom dostupnom roku,
- Vývoj podielu mužskej populácie na globálnej úrovni v čase,
- Porovnanie vybraných krajín z hľadiska demografického vývoja,
- Vývoj podielu populácie v produktívnom veku (15–64),
- Vývoj zloženia populácie podľa pohlavia.

Vizualizácie boli vytvorené priamo nad dimenzionálnym modelom a umožňujú jednoduchú interpretáciu trendov. Obrázky dashboardov sú uložené v priečinku /img.

---

5. Štruktúra repozitára

/sql  
SQL skripty pre fázy Extract, Load a Transform

/img  
ERD diagram zdrojových dát  
diagram Star Schema  
vizualizácie a dashboardy

README.md  
dokumentácia projektu

---

Záver

Projekt prezentuje kompletný proces návrhu a implementácie dátového skladu v prostredí Snowflake. Od analýzy zdrojových dát, cez návrh modelu až po vizualizácie, riešenie pokrýva všetky základné kroky práce s analytickými dátami. Výsledný dátový sklad umožňuje ďalšie rozšírenie analýz aj doplnenie nových indikátorov.

