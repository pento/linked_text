# Contributing to linked_text

## Development Setup

1. Clone the repository and install dependencies:

   ```bash
   git clone https://github.com/pento/linked_text.git
   cd linked_text
   flutter pub get
   ```

2. Enable the pre-commit hook (recommended):

   ```bash
   git config core.hooksPath .githooks
   ```

   This runs `dart format` and `dart analyze` on staged Dart files before each commit.

## Running Tests

```bash
flutter test
```

With coverage:

```bash
flutter test --coverage
```

## Release Process

### First Release (one-time)

The first version must be published manually, as pub.dev requires an initial manual publish before automated publishing can be enabled.

1. Verify the package is publishable:

   ```bash
   dart pub publish --dry-run
   ```

2. Publish:

   ```bash
   dart pub publish
   ```

3. On [pub.dev](https://pub.dev), go to the package **Admin** tab → **Automated publishing** → enable **GitHub Actions**.

4. Set the repository to `pento/linked_text` and the tag pattern to `v{{version}}`.

### Subsequent Releases

1. Add a changelog entry under a new `## <version>` heading in `CHANGELOG.md`.

2. Run the release script:

   ```bash
   ./tool/release.sh <version>
   ```

   This will:
   - Validate the version is semver-shaped
   - Check the working tree is clean
   - Verify `CHANGELOG.md` has an entry for the version
   - Update the version in `pubspec.yaml`
   - Run `flutter analyze` and `flutter test`
   - Commit the version bump and create an annotated tag

3. Push to trigger the publish workflow:

   ```bash
   git push origin main --tags
   ```

4. GitHub Actions will validate the release, run tests, publish to pub.dev, and create a GitHub Release.
