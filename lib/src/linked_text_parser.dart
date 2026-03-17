/// Parsing logic for linked text templates.
///
/// Provides [parseLinkedText] to split a template string containing
/// `{{link text}}` or `{N{link text}}` placeholders into a list of
/// [LinkedTextSegment]s.
library;

import 'package:flutter/foundation.dart';

/// A segment of parsed linked text.
///
/// Either a [PlainTextSegment] containing literal text, or a
/// [LinkTextSegment] representing a tappable link placeholder.
@immutable
sealed class LinkedTextSegment {
  /// Constructor.
  const LinkedTextSegment();
}

/// A segment of plain (non-link) text.
@immutable
class PlainTextSegment extends LinkedTextSegment {
  /// The literal text content.
  final String text;

  /// Constructor.
  const PlainTextSegment(this.text);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is PlainTextSegment && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'PlainTextSegment("$text")';
}

/// A segment representing a tappable link.
@immutable
class LinkTextSegment extends LinkedTextSegment {
  /// The display text for the link.
  final String text;

  /// The zero-based index into the URLs list.
  final int urlIndex;

  /// Constructor.
  const LinkTextSegment({required this.text, required this.urlIndex});

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LinkTextSegment &&
          other.text == text &&
          other.urlIndex == urlIndex;

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'LinkTextSegment("$text", urlIndex: $urlIndex)';
}

/// The regex pattern for matching link placeholders.
///
/// Matches `{{link text}}` (un-indexed) and `{N{link text}}` (indexed,
/// where N is a 1-based integer).
final RegExp _linkPattern = RegExp(r'{(?<linkIndex>\d+)?{(?<linkText>.+?)}}');

/// Parses a linked text template into a list of [LinkedTextSegment]s.
///
/// Un-indexed placeholders (`{{text}}`) are automatically assigned
/// sequential zero-based indices starting from 0. Indexed placeholders
/// (`{N{text}}`) use the provided 1-based index converted to 0-based.
///
/// Example:
/// ```dart
/// final segments = parseLinkedText('Hello {{world}} and {{dart}}');
/// // Returns:
/// // [
/// //   PlainTextSegment('Hello '),
/// //   LinkTextSegment(text: 'world', urlIndex: 0),
/// //   PlainTextSegment(' and '),
/// //   LinkTextSegment(text: 'dart', urlIndex: 1),
/// // ]
/// ```
List<LinkedTextSegment> parseLinkedText(final String text) {
  if (text.isEmpty) {
    return <LinkedTextSegment>[];
  }

  final List<String> textParts = text.split(_linkPattern);
  final Iterable<RegExpMatch> matches = _linkPattern.allMatches(text);

  if (matches.isEmpty) {
    return <LinkedTextSegment>[PlainTextSegment(text)];
  }

  final List<LinkedTextSegment> segments = <LinkedTextSegment>[];
  int autoIndex = 0;

  for (int i = 0; i < textParts.length; i++) {
    if (textParts[i].isNotEmpty) {
      segments.add(PlainTextSegment(textParts[i]));
    }

    if (i < matches.length) {
      final RegExpMatch match = matches.elementAt(i);
      final String? linkText = match.namedGroup('linkText');
      final String? indexStr = match.namedGroup('linkIndex');

      if (linkText != null) {
        final int urlIndex;
        if (indexStr != null) {
          // Convert 1-based index to 0-based.
          urlIndex = (int.tryParse(indexStr) ?? 1) - 1;
        } else {
          urlIndex = autoIndex;
          autoIndex++;
        }
        segments.add(
          LinkTextSegment(text: linkText, urlIndex: urlIndex),
        );
      }
    }
  }

  return segments;
}
