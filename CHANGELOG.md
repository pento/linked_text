# Changelog

## 1.1.3

- Updated the `hooks` dependency to `^2.0.0`.
- Bumped the minimum Dart SDK constraint to 3.10.0 and the minimum Flutter SDK to 3.38.0, matching the new requirement from `hooks` 2.0.

## 1.1.2

- Prevent an out-of-bounds URL index in a string template from causing a crash. If an index is out of bounds, the link will simply be non-interactive.

## 1.1.1

- Updated the minimum Dart SDK constraint to 3.6.0.
- Fixed compatibility with Flutter's `gen_l10n`: a build hook automatically adds `relax-syntax: true` to
  `l10n.yaml` when missing. If the first build fails, re-running it will succeed.

## 1.0.0

- Initial release.
- `LinkedText` widget for rendering text with interpolated tappable links.
- Template syntax: `{{link text}}` for auto-indexed links, `{N{link text}}` for explicitly indexed links.
- Optional `onTap` callback for custom link handling.
- Default URL launching via `url_launcher`.
- Proper `TapGestureRecognizer` lifecycle management.
