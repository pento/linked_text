# Changelog

## 1.0.0

- Initial release.
- `LinkedText` widget for rendering text with interpolated tappable links.
- Template syntax: `{{link text}}` for auto-indexed links, `{N{link text}}` for explicitly indexed links.
- Optional `onTap` callback for custom link handling.
- Default URL launching via `url_launcher`.
- Proper `TapGestureRecognizer` lifecycle management.
