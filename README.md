# linked_text

[![CI](https://github.com/pento/linked_text/actions/workflows/ci.yml/badge.svg)](https://github.com/pento/linked_text/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/linked_text.svg)](https://pub.dev/packages/linked_text)

A Flutter widget that renders text with interpolated tappable links using a simple template syntax.

## Features

- Simple template syntax for embedding links in text
- Auto-indexed (`{{link}}`) and explicitly indexed (`{N{link}}`) placeholders
- Default URL launching via `url_launcher` or custom `onTap` callback
- Semantic labels for accessibility
- Customizable text and link styles
- Proper gesture recognizer lifecycle management

## Installation

```yaml
dependencies:
  linked_text: ^1.0.0
```

## Usage

### Basic usage with a single link

```dart
LinkedText(
  text: 'Visit the {{Flutter website}} for more info.',
  urls: ['https://flutter.dev'],
  urlLabels: ['Link to Flutter website'],
)
```

### Multiple auto-indexed links

Un-indexed placeholders are automatically assigned sequential indices:

```dart
LinkedText(
  text: '{{Privacy Policy}} | {{Terms of Service}}',
  urls: [
    'https://example.com/privacy',
    'https://example.com/terms',
  ],
  urlLabels: [
    'Link to Privacy Policy',
    'Link to Terms of Service',
  ],
)
```

### Explicitly indexed links

Use `{N{text}}` syntax (1-based) to control which URL each placeholder maps to:

```dart
LinkedText(
  text: 'Built with {1{Flutter}}, powered by {2{Dart}}.',
  urls: [
    'https://flutter.dev',
    'https://dart.dev',
  ],
  urlLabels: [
    'Link to Flutter',
    'Link to Dart',
  ],
)
```

### Custom tap handling

```dart
LinkedText(
  text: 'Read the {{documentation}}.',
  urls: ['https://example.com/docs'],
  urlLabels: ['Link to documentation'],
  onTap: (url, index) {
    // Custom handling instead of launching URL
    print('Tapped link $index: $url');
  },
)
```

### Custom styles

```dart
LinkedText(
  text: 'Check out {{this link}}.',
  urls: ['https://example.com'],
  urlLabels: ['Example link'],
  style: TextStyle(fontSize: 14, color: Colors.grey),
  linkStyle: TextStyle(
    fontSize: 14,
    color: Colors.blue,
    decoration: TextDecoration.underline,
  ),
  textAlign: TextAlign.center,
)
```

## Template Syntax

| Syntax      | Description                             | Example           |
| ----------- | --------------------------------------- | ----------------- |
| `{{text}}`  | Auto-indexed link (0-based, sequential) | `{{Click here}}`  |
| `{N{text}}` | Explicitly indexed link (N is 1-based)  | `{1{Click here}}` |

## API Reference

See the [API documentation](https://pub.dev/documentation/linked_text/latest/) for full details.
