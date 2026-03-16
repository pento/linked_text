import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../hook/build.dart';

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
      expect(result, equals(tempDir.uri));
    });

    test('returns root when already at root', () {
      File('${tempDir.path}/pubspec.yaml').createSync();

      final Uri? result = findProjectRoot(tempDir.uri);
      expect(result, isNotNull);
      expect(result, equals(tempDir.uri));
    });

    test('returns null when exceeding depth limit', () {
      // Create a directory nested >20 levels deep with no pubspec.yaml
      // anywhere in the tree. The 20-iteration limit guarantees null.
      final String deepPath =
          List<String>.generate(21, (int i) => 'd$i').join('/');
      final Directory nested = Directory('${tempDir.path}/$deepPath')
        ..createSync(recursive: true);

      final Uri? result = findProjectRoot(nested.uri);
      expect(result, isNull);
    });
  });
}
