// Build hook for linked_text that ensures the consuming app's l10n.yaml
// has relax-syntax enabled, which is required for linked_text's
// placeholder syntax.
//
// If relax-syntax is missing, the hook adds it automatically and
// informs the developer. The current build will still fail (gen-l10n
// already ran), but the next build will succeed.

import 'dart:io';

import 'package:hooks/hooks.dart';

import 'src/l10n_validator.dart';

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

    // Don't throw — let the build continue. The current build will likely
    // fail from the gen-l10n errors that already happened, but the next
    // build will succeed.
  });
}
