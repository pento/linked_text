import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('git hooks path is configured', () {
    // Skip in CI — hooks are enforced locally, CI runs format/analyze directly.
    final bool isCI = Platform.environment['CI'] == 'true';
    if (isCI) {
      return;
    }

    final ProcessResult result = Process.runSync('git', <String>[
      'config',
      'core.hooksPath',
    ]);
    final String hooksPath = result.stdout.toString().trim();

    expect(
      hooksPath,
      '.githooks',
      reason: 'Git hooks are not configured.\n'
          'Run: git config core.hooksPath .githooks\n'
          'This enables the pre-commit hook that auto-formats code '
          'and runs dart analyze.',
    );
  });
}
