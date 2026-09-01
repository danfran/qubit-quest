# Qubit Quest

Qubit Quest is an interactive Flutter application for learning quantum computing
through guided lessons, circuit-building challenges, a searchable Quantum Notebook,
Mastery Challenges, a free-form Composer, and a Bloch Sphere Explorer.

## Web application

Qubit Quest Web 0.1 is published at:

**https://danfran.github.io/qubit-quest/**

The Web application is client-side. Progress, Notebook discoveries, Mastery state,
preferences, and Composer workspaces are stored in the current browser through the
shared application-storage abstraction. There is no account or cloud synchronization
in Web 0.1.

## Mobile application

Qubit Quest also has a production Android application built from the same repository.
The mobile and Web applications share canonical learning content, progression,
quantum models, Composer behavior, Bloch mathematics, and persistence schemas while
using platform-appropriate layouts. A public Google Play listing URL is not currently
documented in this repository.

## Local development

Install a stable Flutter SDK, then run:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

Run the mobile application on a connected device or emulator:

```bash
flutter run
```

Run Web locally on a stable origin:

```bash
flutter run -d chrome --web-port=8080
```

Build the GitHub Pages form locally:

```bash
flutter build web --release --base-href /qubit-quest/
python3 -m http.server 8080 --directory build/web
```

When testing a subpath build locally, open
`http://localhost:8080/qubit-quest/` only if the static server maps that path to the
built artifact. For a direct `build/web` server, build with `/` as the base href or
serve it beneath a `qubit-quest` directory.

## Web deployment

Pushes to `main` trigger [`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml).
The workflow:

1. installs stable Flutter;
2. resolves dependencies;
3. runs `flutter analyze --no-fatal-infos` (warnings and errors remain fatal);
4. builds with `--base-href /qubit-quest/`;
5. publishes `build/web` through GitHub Pages.

The repository's Pages source must be configured as **GitHub Actions**. The static
host requires no backend or server API. Qubit Quest currently uses workspace-local
navigation, so the deployed entry point is the repository base path.

The build also copies `docs/public/` into the Pages artifact so the established mobile
privacy-policy and documentation URLs remain available alongside the Flutter app.

## Project structure

- `lib/models/` — canonical learning, progression, quantum, and persistence models
- `lib/widgets/` — reusable Composer, Bloch, maths, and application components
- `lib/screens/` — mobile and Web presentation/composition
- `test/` — focused model, interaction, parity, persistence, and Web acceptance tests
- `web/` — browser metadata and Qubit Quest branding assets
- `docs/` — public mobile documentation, technical notes, and archived product history

## Android release build

```bash
flutter build appbundle --release
```
