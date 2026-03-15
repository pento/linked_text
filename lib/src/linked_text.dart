import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'linked_text_parser.dart';

/// Renders text with tappable links interpolated using a template syntax.
///
/// Links are specified in the [text] template using double curly braces:
/// - `{{link text}}` — auto-indexed, assigned sequential indices starting
///   from 0
/// - `{N{link text}}` — explicitly indexed, where N is a 1-based index
///   into the [urls] list
///
/// Example:
/// ```dart
/// LinkedText(
///   text: 'Visit {1{Flutter}} and {2{Dart}} for more info.',
///   urls: ['https://flutter.dev', 'https://dart.dev'],
///   urlLabels: ['Link to Flutter', 'Link to Dart'],
/// )
/// ```
class LinkedText extends StatefulWidget {
  /// The template text with link placeholders.
  final String text;

  /// The URLs to link to from the text.
  ///
  /// If set, this parameter must be the same length as [urlLabels].
  final List<String>? urls;

  /// The corresponding semantic labels for each URL.
  ///
  /// If set, this parameter must be the same length as [urls].
  final List<String>? urlLabels;

  /// Optional style override for the base text.
  final TextStyle? style;

  /// Optional style override for link text.
  final TextStyle? linkStyle;

  /// Optional text alignment.
  final TextAlign? textAlign;

  /// Called when a link is tapped.
  ///
  /// If provided, this callback is used instead of the default
  /// URL launching behavior. The `url` is the URL string from
  /// [urls] at the given `index`.
  final void Function(String url, int index)? onTap;

  /// Constructor.
  const LinkedText({
    required this.text,
    this.urls,
    this.urlLabels,
    this.style,
    this.linkStyle,
    this.textAlign,
    this.onTap,
    super.key,
  }) : assert(
          urls?.length == urlLabels?.length,
          'If the `urls` and `urlLabels` parameters are passed, '
          'they must be the same length.',
        );

  @override
  State<LinkedText> createState() => _LinkedTextState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(IterableProperty<String>('urls', urls))
      ..add(IterableProperty<String>('urlLabels', urlLabels))
      ..add(DiagnosticsProperty<TextStyle?>('style', style))
      ..add(DiagnosticsProperty<TextStyle?>('linkStyle', linkStyle))
      ..add(EnumProperty<TextAlign?>('textAlign', textAlign))
      ..add(
        ObjectFlagProperty<void Function(String, int)?>.has(
          'onTap',
          onTap,
        ),
      );
  }
}

class _LinkedTextState extends State<LinkedText> {
  List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  List<LinkedTextSegment> _segments = <LinkedTextSegment>[];

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant final LinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        !listEquals(oldWidget.urls, widget.urls) ||
        oldWidget.onTap != widget.onTap) {
      _disposeRecognizers();
      _parse();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parse() {
    _segments = parseLinkedText(widget.text);
    _buildRecognizers();
  }

  void _buildRecognizers() {
    final List<String>? urls = widget.urls;
    if (urls == null) {
      return;
    }

    _recognizers = <TapGestureRecognizer>[];

    for (final LinkedTextSegment segment in _segments) {
      if (segment is LinkTextSegment && segment.urlIndex < urls.length) {
        final int index = segment.urlIndex;
        final TapGestureRecognizer recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (widget.onTap != null) {
              widget.onTap!(urls[index], index);
            } else {
              unawaited(launchUrl(Uri.parse(urls[index])));
            }
          };
        _recognizers.add(recognizer);
      }
    }
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = <TapGestureRecognizer>[];
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle? textStyle = widget.style ?? themeData.textTheme.bodyLarge;
    final TextStyle effectiveLinkStyle = widget.linkStyle ??
        themeData.textTheme.bodyLarge!.copyWith(
          color: themeData.colorScheme.secondary,
        );

    final List<InlineSpan> children = <InlineSpan>[];
    int recognizerIndex = 0;

    for (final LinkedTextSegment segment in _segments) {
      switch (segment) {
        case PlainTextSegment():
          children.add(TextSpan(text: segment.text));
        case LinkTextSegment():
          if (widget.urls != null &&
              segment.urlIndex < widget.urls!.length &&
              recognizerIndex < _recognizers.length) {
            children.add(
              TextSpan(
                text: segment.text,
                style: effectiveLinkStyle,
                semanticsLabel: widget.urlLabels != null &&
                        segment.urlIndex < widget.urlLabels!.length
                    ? widget.urlLabels![segment.urlIndex]
                    : null,
                recognizer: _recognizers[recognizerIndex],
              ),
            );
            recognizerIndex++;
          } else {
            children.add(TextSpan(text: segment.text));
          }
      }
    }

    return RichText(
      textAlign: widget.textAlign ?? TextAlign.start,
      text: TextSpan(style: textStyle, children: children),
    );
  }
}
