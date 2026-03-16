import 'dart:io';

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
