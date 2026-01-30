# Prva Flutter Aplikacija

Profesionalni i pregledni README za Flutter projekt.

## Sažetak projekta

**Prva Flutter Aplikacija** je mobilna aplikacija izgrađena koristeći Flutter i Dart. Projekt uključuje integraciju s Firebase uslugama (Authentication, Firestore, itd.) i spreman je za razvoj i proizvodnju na Android, iOS i web platformama.

## Ključne značajke

- Moderni Flutter arhitektonski pristupi
- Firebase autentikacija i pohrana podataka
- Prilagodljiv dizajn za mobilne i web platforme
- Primjeri ekrana i servisa u mapi `lib/Ekrani` i `lib/services`

## Tehnologije

- Flutter
- Dart
- Firebase (Auth, Firestore, Storage, itd.)

## Preduvjeti

Prije pokretanja projekta, instalirajte sljedeće:

- Flutter SDK (preporučena verzija: ona navedena u `pubspec.yaml`)
- Android Studio / Xcode (za native buildove)
- Git

Provjerite da `flutter doctor` ne prijavljuje kritične probleme.

## Instalacija i lokalno pokretanje

1. Klonirajte repozitorij:

```bash
git clone https://your.repo.url/Prva_flutter_aplikacija_projekat.git
cd Prva_flutter_aplikacija_projekat
```

2. Instalirajte dependencije:

```bash
flutter pub get
```

3. Pokrenite aplikaciju na uređaju ili emulatoru:

```bash
flutter run -d <device-id>
```

Za web:

```bash
flutter run -d chrome
```

## Konfiguracija Firebase-a

Projekt već sadrži generirane Firebase konfiguracijske datoteke (`firebase_options.dart` u `lib/`). Ako trebate povezat svoj Firebase projekt:

1. Kreirajte Firebase projekt na https://console.firebase.google.com/
2. Dodajte Android/iOS/web aplikaciju i preuzmite konfiguracijske datoteke
3. Zamijenite postojeće datoteke konfiguracije ili regenerirajte `firebase_options.dart` koristeći službeni FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Provjerite `lib/firebase_options.dart` i sigurnosne postavke Firestore-a prije produkcije.

## Izgradnja za proizvodnju

Android (APK):

```bash
flutter build apk --release
```

Android (AAB):

```bash
flutter build appbundle --release
```

iOS:

```bash
flutter build ios --release
```

Web:

```bash
flutter build web --release
```

## Testiranje

Pokrenite jedinične i widget testove:

```bash
flutter test
```

## Stil koda i linting

Koristimo `analysis_options.yaml` u korijenu repozitorija za statičku analizu. Pokrenite:

```bash
flutter analyze
```

Preporučeno: konfigurirati IDE da primjenjuje formatiranje kod `dart format` prije commita.

## Struktura repozitorija (važnije mape)

- `lib/` — izvorni kod aplikacije
- `lib/Ekrani/` — ekrani aplikacije
- `lib/services/` — servisne klase (Firebase i ostalo)
- `android/`, `ios/`, `web/` — platform-specifične konfiguracije

## Contributing

1. Forkajte repozitorij
2. Kreirajte feature branch: `git checkout -b feature/ime-featurea`
3. Pošaljite izmjene i otvorite Pull Request

Molimo slijedite postojeći stil koda i dodajte relevantne testove za nove funkcionalnosti.

## Sigurnosne napomene

- NE stavljajte osjetljive podatke (API ključeve, tajne) u repozitorij.
- Koristite sigurnosna pravila Firestore-a i provjerite autentikaciju prije izlaganja podataka.

## License

Ovaj repozitorij nema zadanu licencu — dodajte `LICENSE` datoteku prema potrebi (npr. MIT, Apache-2.0).

## Kontakt

Za pitanja i suradnju kontaktirajte lead developera ili otvorite issue u repozitoriju.

---

Ako želite, mogu:
- prevesti README na engleski
- dodati konkretne upute za CI/CD ili GitHub Actions
- prilagoditi upute specifičnim Firebase postavkama vašeg projekta
# flutter_aplikacija

School project, a flutter app used for reporting ecological, social and other types of problems.

