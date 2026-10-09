# Anatti – suunnitelma

iPhone- ja iPad-sovellus, joka luo App Storen ja Play Storen listausmateriaalit: kuvakaappaukset, esittelyvideot, Play-kuvakkeen ja feature graphicin sekä Product Page Optimization -kuvat. Koot: [SPECS.md](SPECS.md), koodina `Sources/AnattiCore/SpecCatalog.swift`.

## Reunaehdot
- **Kaikki data vain laitteella.** Ei omaa palvelinta, ei analytiikkaa, ei tilejä, ei iCloud/CloudKit-synkkaa. App Privacy -tiedoksi "Data Not Collected".
- **Pro-tilaus 7,99 €/kk** (automaattisesti uusiutuva tilaus) maksumuurin takana. Ilman Proa sovellus näyttää vain esikatselun ilman vientiä.
- **Ulkoasu:** SwiftUI + Liquid Glass (iOS 26 API:t, iOS 27 SDK -yhteensopiva). Navigaatio ja työkalut lasia, sisältö tasaista.

## Käyttäjän polku
1. **Projekti:** nimi, sovelluksen kuvake, värit, kielet.
2. **Lähdekuvat:** käyttäjän omat kuvakaappaukset Kuvista/Tiedostoista tai ruudunkaappaus-/ruudunnauhoitusvideo.
3. **Mallipohja:** otsikko, alateksti, tausta, laitekehys (valinnainen).
4. **Kohteet:** valitaan kauppa ja laiteluokat. Pakolliset merkitään, vaihtoehtoiset voi lisätä.
5. **Esikatselu:** jokainen kohde omassa koossaan, tarkistus (alfa, koko, määrä, kesto).
6. **Vienti:** kansio per kauppa/laite/kieli → Tiedostot, jakovalikko tai AirDrop. Käyttäjä lataa itse App Store Connectiin / Play Consoleen.

## Arkkitehtuuri
| Kerros | Valinta |
|---|---|
| UI | SwiftUI, `GlassEffectContainer`, `.glassEffect`, `.buttonStyle(.glass)` |
| Tallennus | SwiftData (laitteen oma tallennus), kuvat ja videot sovelluksen Application Support -kansioon. Ei CloudKit-konfiguraatiota |
| Tilaus | StoreKit 2: `Product`, `Transaction.currentEntitlements`, `Transaction.updates`. Oikeus tarkistetaan laitteella, ei palvelinvahvistusta |
| Kuvien renderöinti | SwiftUI `ImageRenderer` tarkassa pikselikoossa (scale 1), PNG ilman alfaa (`CGImageAlphaInfo.noneSkipLast`) |
| Videot | `AVAssetReader/Writer` tai `AVMutableComposition` + `AVAssetExportSession`; H.264 High L4.0, ≤30 fps, 10–12 Mbps, AAC 256 kbps stereo (hiljainen raita lisätään tarvittaessa), 15–30 s |
| Specit | `AnattiCore`-paketti (`SpecCatalog`), testattu `swift test` |
| Vienti | `fileExporter` / `ShareLink` / `UIDocumentPicker` kansiolle |

## Maksumuuri
- Tilausryhmä "Anatti Pro", tuote `fi.anatti.pro.monthly`, hinta 7,99 € (App Store Connectissa hintataso).
- Näytetään ensimmäisellä käynnistyksellä ja vientipainikkeen kohdalla. Pakolliset: ehdot, tietosuoja, "Palauta ostokset", tilauksen hallinta.
- Offline: viimeisin vahvistettu oikeus StoreKitin lokaalista välimuistista. Oikeuden päättyessä data säilyy, vienti lukittuu.
- Vinkki: StoreKit-konfiguraatiotiedosto testaukseen simulaattorissa.

## Toteutusvaiheet
1. **Perusta:** Xcode-projekti (iPhone + iPad), `AnattiCore`, SwiftData-mallit. *(Specit tehty.)*
2. **Maksumuuri** ja Pro-tilan hallinta.
3. **Kuvaeditori** + renderöinti kaikkiin kuvakokoihin + validointi.
4. **Videopolku:** lähdevideon sovitus (rajaus/skaalaus, kesto, ääniraita, koodaus).
5. **Play-kohteet:** kuvake, feature graphic, tabletti-/Wear-/TV-kuvat.
6. **PPO-kuvat.**
7. **Vienti**, lokalisointi (FI/EN), saavutettavuus, App Store -julkaisu.

## Osaajat/agentit
SwiftUI/Liquid Glass -kehittäjä · StoreKit 2 -asiantuntija · AVFoundation (video) · kuvaprosessointi (Core Graphics) · QA (mitat, alfa, kesto) · suunnittelija · julkaisu/ASO.

## Avoimet kysymykset
- Hyväksyvätkö vain 1 kielen alkuun, vai monta kieltä heti?
- Tarvitaanko laitekehyksiä? Google Play voi hylätä kehystetyt kuvat (vahvista) ja Applen kehykset vaativat lisenssitarkistuksen.
- Play-esittelyvideo on käytännössä YouTube-linkki, joten sovellus voi vain tuottaa videotiedoston (vahvista).
- Tilaukselle: kokeilujakso? Vuosihinta?
- Play Storen tabletti-/Chromebook-koot tulevat kolmannen osapuolen lähteistä ja vaativat vahvistuksen Play Consolesta.
