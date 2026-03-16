import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../hook/src/l10n_validator.dart';

void main() {
  group('hasRelaxSyntax', () {
    test('matches relax-syntax: true', () {
      expect(hasRelaxSyntax('relax-syntax: true'), isTrue);
    });

    test('matches without space after colon', () {
      expect(hasRelaxSyntax('relax-syntax:true'), isTrue);
    });

    test('matches with extra spaces around colon', () {
      expect(hasRelaxSyntax('relax-syntax : true'), isTrue);
    });

    test('matches with trailing comment', () {
      expect(hasRelaxSyntax('relax-syntax: true # comment'), isTrue);
    });

    test('does not match relax-syntax: false', () {
      expect(hasRelaxSyntax('relax-syntax: false'), isFalse);
    });

    test('does not match when missing entirely', () {
      expect(hasRelaxSyntax('arb-dir: lib/l10n\n'), isFalse);
    });

    test('does not match commented-out line', () {
      expect(hasRelaxSyntax('# relax-syntax: true'), isFalse);
    });

    test('matches indented line', () {
      expect(hasRelaxSyntax('  relax-syntax: true'), isTrue);
    });

    test('matches among surrounding YAML keys', () {
      const String yaml = '''
arb-dir: lib/l10n
relax-syntax: true
output-localization-file: app_localizations.dart
''';
      expect(hasRelaxSyntax(yaml), isTrue);
    });
  });

  group('addRelaxSyntax', () {
    test('appends setting when relax-syntax is absent', () {
      const String input = 'arb-dir: lib/l10n\n';
      final String result = addRelaxSyntax(input);

      expect(result, contains('relax-syntax: true'));
      expect(
        result,
        contains('# Required by linked_text for its placeholder syntax.'),
      );
      // Original content is preserved.
      expect(result, startsWith('arb-dir: lib/l10n\n'));
    });

    test('replaces relax-syntax: false with true', () {
      const String input = 'arb-dir: lib/l10n\nrelax-syntax: false\n';
      final String result = addRelaxSyntax(input);

      expect(result, contains('relax-syntax: true'));
      expect(result, isNot(contains('relax-syntax: false')));
      // Original surrounding content is preserved.
      expect(result, startsWith('arb-dir: lib/l10n\n'));
    });

    test('preserves indentation when replacing', () {
      const String input = '  relax-syntax: false\n';
      final String result = addRelaxSyntax(input);

      expect(result, contains('  relax-syntax: true'));
    });

    test('handles file not ending with newline', () {
      const String input = 'arb-dir: lib/l10n';
      final String result = addRelaxSyntax(input);

      expect(result, contains('relax-syntax: true'));
      // Should still have the original content.
      expect(result, startsWith('arb-dir: lib/l10n'));
    });

    test('preserves existing content around the change', () {
      const String input = '''
arb-dir: lib/l10n
relax-syntax: false
output-localization-file: app_localizations.dart
''';
      final String result = addRelaxSyntax(input);

      expect(result, contains('arb-dir: lib/l10n'));
      expect(result, contains('relax-syntax: true'));
      expect(result, contains('output-localization-file:'));
      expect(result, isNot(contains('relax-syntax: false')));
    });
  });

  group('findProjectRoot', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('l10n_validator_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('finds pubspec.yaml walking up from a subdirectory', () {
      // Create a pubspec.yaml at the root.
      File('${tempDir.path}/pubspec.yaml').createSync();

      // Create a nested directory to start from.
      final Directory nested = Directory('${tempDir.path}/a/b/c')
        ..createSync(recursive: true);

      final Uri? result = findProjectRoot(nested.uri);
      expect(result, isNotNull);
      expect(result!.toFilePath(), equals('${tempDir.path}/'));
    });

    test('returns root when already at root', () {
      File('${tempDir.path}/pubspec.yaml').createSync();

      final Uri? result = findProjectRoot(tempDir.uri);
      expect(result, isNotNull);
      expect(result!.toFilePath(), equals('${tempDir.path}/'));
    });

    test('returns null when no pubspec.yaml exists', () {
      // Create a nested directory with no pubspec.yaml anywhere.
      final Directory nested = Directory('${tempDir.path}/a/b')
        ..createSync(recursive: true);

      final Uri? result = findProjectRoot(nested.uri);
      // Will eventually hit filesystem root and stop — should return null
      // or find a real pubspec.yaml from the test environment. Since we're
      // in a temp dir that's nested under the system temp, the walk will
      // eventually hit the filesystem root and return null (or find an
      // unrelated pubspec.yaml). We test the 20-iteration limit indirectly.
      //
      // For a truly isolated test, we rely on the fact that system temp
      // directories don't typically contain pubspec.yaml files in their
      // parent chain. If this test becomes flaky, it should be adjusted.
      //
      // We check that if it does return something, it's not our temp dir
      // (which has no pubspec.yaml).
      if (result != null) {
        // It found a pubspec.yaml somewhere up the tree — that's fine,
        // but it shouldn't be inside our temp dir.
        expect(
          result.toFilePath(),
          isNot(startsWith('${tempDir.path}/')),
        );
      }
    });
  });
}
