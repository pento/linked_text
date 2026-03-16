# Changelog

## 1.1.0

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
