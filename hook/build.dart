// Build hook for linked_text that ensures the consuming app's l10n.yaml
// has relax-syntax enabled, which is required for linked_text's
// placeholder syntax.
//
// If relax-syntax is missing, the hook adds it automatically and
// informs the developer. The current build will still fail (gen-l10n
// already ran), but the next build will succeed.

import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    // We produce no assets. This hook exists solely to ensure l10n.yaml
    // is configured correctly for linked_text's placeholder syntax.

    final Uri? projectRoot = findProjectRoot(input.outputDirectory);

    if (projectRoot == null) {
      // Can't find the project root — unusual, but don't block the build.
      return;
    }

    final File l10nFile = File.fromUri(projectRoot.resolve('l10n.yaml'));

    // Register l10n.yaml as a dependency so the hook re-runs if it changes.
    if (l10nFile.existsSync()) {
      output.dependencies.add(l10nFile.uri);
    }

    if (!l10nFile.existsSync()) {
      // No l10n.yaml means gen-l10n won't run automatically.
      // Nothing to do.
      return;
    }

    try {
      final String content = l10nFile.readAsStringSync();

      if (hasRelaxSyntax(content)) {
        // Already configured correctly.
        return;
      }

      // Add relax-syntax: true to the file.
      final String newContent = addRelaxSyntax(content);
      l10nFile.writeAsStringSync(newContent);

      // Let the developer know what we did. This goes to stderr so it's
      // visible in build output without being mistaken for asset data.
      stderr.writeln(
        '\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '  linked_text: added "relax-syntax: true" to your l10n.yaml\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '\n'
        '  The linked_text package requires the ICU message parser to run\n'
        '  in relaxed mode. This setting has been added automatically.\n'
        '\n'
        '  This build may fail because gen-l10n ran before this change\n'
        '  was applied. If so, just re-run the build — it will succeed.\n'
        '\n'
        '  Modified file:\n'
        '    ${l10nFile.path}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n',
      );
    } on FileSystemException catch (e) {
      // Don't block the build for I/O issues (permissions, concurrent
      // edits, etc.). Just let the developer know.
      stderr.writeln(
        'linked_text: could not update l10n.yaml '
        '(${e.message}). Add "relax-syntax: true" manually.',
      );
    }

    // Don't throw — let the build continue. The current build will likely
    // fail from the gen-l10n errors that already happened, but the next
    // build will succeed.
  });
}

/// Walk up from [startUri] looking for a directory containing pubspec.yaml.
///
/// Returns the [Uri] of the directory containing pubspec.yaml, or `null` if
/// no such directory is found within 20 levels.
Uri? findProjectRoot(Uri startUri) {
  Directory dir = Directory.fromUri(startUri);

  for (int i = 0; i < 20; i++) {
    final File pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      return dir.uri;
    }

    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }

  return null;
}

/// Check whether l10n.yaml content already has `relax-syntax: true`.
///
/// Handles variations in whitespace and optional trailing YAML comments.
/// Lines that are commented out (starting with `#`) are not matched.
bool hasRelaxSyntax(String content) {
  final RegExp pattern = RegExp(
    r'^\s*relax-syntax\s*:\s*true\s*(#.*)?$',
    multiLine: true,
  );
  return pattern.hasMatch(content);
}

/// Add or fix `relax-syntax: true` in the l10n.yaml content.
///
/// If the file already has a `relax-syntax` line set to something other
/// than `true`, replaces it (preserving indentation). Otherwise appends
/// the setting with an explanatory comment.
String addRelaxSyntax(String content) {
  // Check if there's an existing relax-syntax line (set to false or
  // something else).
  final RegExp existingPattern = RegExp(
    r'^(\s*)relax-syntax\s*:.*$',
    multiLine: true,
  );

  if (existingPattern.hasMatch(content)) {
    // Replace the existing line, preserving indentation.
    return content.replaceFirstMapped(existingPattern, (Match match) {
      final String indent = match.group(1) ?? '';
      return '${indent}relax-syntax: true';
    });
  }

  // Append to the end of the file.
  final StringBuffer buffer = StringBuffer(content);

  if (content.isNotEmpty) {
    // Ensure we start on a new line.
    if (!content.endsWith('\n')) {
      buffer.writeln();
    }
    // Blank separator line before our addition.
    buffer.writeln();
  }

  buffer
    ..writeln('# Required by linked_text for its placeholder syntax.')
    ..writeln('relax-syntax: true');

  return buffer.toString();
}
