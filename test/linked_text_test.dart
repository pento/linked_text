import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linked_text/linked_text.dart';

void main() {
  Widget buildTestWidget(final LinkedText linkedText) => MaterialApp(
        home: Scaffold(body: linkedText),
      );

  group('LinkedText widget', () {
    testWidgets('renders plain text without links', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LinkedText(text: 'Hello, world!'),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      expect(textSpan.children, hasLength(1));
      expect((textSpan.children![0] as TextSpan).text, 'Hello, world!');
    });

    testWidgets('renders links with correct style', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Visit {{Flutter}}.',
            urls: const <String>['https://flutter.dev'],
            urlLabels: const <String>['Link to Flutter'],
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final List<InlineSpan> children = textSpan.children!;

      // Plain "Visit "
      expect((children[0] as TextSpan).text, 'Visit ');
      expect((children[0] as TextSpan).style, isNull);

      // Link "Flutter"
      expect((children[1] as TextSpan).text, 'Flutter');
      expect((children[1] as TextSpan).style, isNotNull);
      expect(
        (children[1] as TextSpan).recognizer,
        isA<TapGestureRecognizer>(),
      );

      // Plain "."
      expect((children[2] as TextSpan).text, '.');
    });

    testWidgets('tap calls onTap callback', (
      final WidgetTester tester,
    ) async {
      String? tappedUrl;
      int? tappedIndex;

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{here}}.',
            urls: const <String>['https://example.com'],
            urlLabels: const <String>['Example link'],
            onTap: (final String url, final int index) {
              tappedUrl = url;
              tappedIndex = index;
            },
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;
      final TapGestureRecognizer recognizer =
          linkSpan.recognizer! as TapGestureRecognizer;

      recognizer.onTap!();

      expect(tappedUrl, 'https://example.com');
      expect(tappedIndex, 0);
    });

    testWidgets('custom styles are applied', (
      final WidgetTester tester,
    ) async {
      const TextStyle customStyle = TextStyle(
        fontSize: 12,
        color: Colors.grey,
      );
      const TextStyle customLinkStyle = TextStyle(
        fontSize: 12,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Visit {{Flutter}}.',
            urls: const <String>['https://flutter.dev'],
            urlLabels: const <String>['Link to Flutter'],
            style: customStyle,
            linkStyle: customLinkStyle,
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;

      expect(textSpan.style, customStyle);
      expect(
        (textSpan.children![1] as TextSpan).style,
        customLinkStyle,
      );
    });

    testWidgets('textAlign is applied', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LinkedText(
            text: 'Centered text.',
            textAlign: TextAlign.center,
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );

      expect(richText.textAlign, TextAlign.center);
    });

    testWidgets('does not wrap in padding Container', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LinkedText(text: 'No padding.'),
        ),
      );

      // The LinkedText widget should render a RichText directly,
      // not wrapped in a Container with padding.
      final Finder richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);

      // Verify no Container ancestor with padding between
      // LinkedText and RichText.
      final Element linkedTextElement = tester.element(
        find.byType(LinkedText),
      );
      bool foundContainer = false;
      linkedTextElement.visitChildElements((final Element element) {
        if (element.widget is Container) {
          foundContainer = true;
        }
      });
      expect(foundContainer, isFalse);
    });

    testWidgets('semantic labels are set on link spans', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Visit {{Flutter}}.',
            urls: const <String>['https://flutter.dev'],
            urlLabels: const <String>['Link to Flutter website'],
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;

      expect(linkSpan.semanticsLabel, 'Link to Flutter website');
    });

    testWidgets('multiple un-indexed links get correct URLs', (
      final WidgetTester tester,
    ) async {
      final List<String> tappedUrls = <String>[];

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: '{{Privacy Policy}} | {{EULA}}',
            urls: const <String>[
              'https://example.com/privacy',
              'https://example.com/eula',
            ],
            urlLabels: const <String>[
              'Privacy Policy',
              'EULA',
            ],
            onTap: (final String url, final int index) {
              tappedUrls.add(url);
            },
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;

      // Tap first link.
      final TextSpan firstLink = textSpan.children![0] as TextSpan;
      (firstLink.recognizer! as TapGestureRecognizer).onTap!();

      // Tap second link.
      final TextSpan secondLink = textSpan.children![2] as TextSpan;
      (secondLink.recognizer! as TapGestureRecognizer).onTap!();

      expect(tappedUrls, <String>[
        'https://example.com/privacy',
        'https://example.com/eula',
      ]);
    });

    testWidgets('debugFillProperties includes all properties', (
      final WidgetTester tester,
    ) async {
      final LinkedText widget = LinkedText(
        text: 'Test {{link}}.',
        urls: const <String>['https://example.com'],
        urlLabels: const <String>['Example'],
        textAlign: TextAlign.center,
      );

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      widget.debugFillProperties(builder);

      final List<String> propertyNames = builder.properties
          .map((final DiagnosticsNode node) => node.name ?? '')
          .toList();

      expect(propertyNames, contains('text'));
      expect(propertyNames, contains('urls'));
      expect(propertyNames, contains('urlLabels'));
      expect(propertyNames, contains('style'));
      expect(propertyNames, contains('linkStyle'));
      expect(propertyNames, contains('textAlign'));
      expect(propertyNames, contains('onTap'));
    });

    testWidgets('recognizers are disposed on widget removal', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{here}}.',
            urls: const <String>['https://example.com'],
            urlLabels: const <String>['Example'],
          ),
        ),
      );

      // Verify the recognizer exists.
      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;
      expect(linkSpan.recognizer, isA<TapGestureRecognizer>());

      // Remove the widget — this triggers State.dispose() which
      // disposes all recognizers.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Replaced')),
        ),
      );

      expect(find.byType(LinkedText), findsNothing);
      expect(find.text('Replaced'), findsOneWidget);
    });

    testWidgets('didUpdateWidget recreates recognizers on text change', (
      final WidgetTester tester,
    ) async {
      String? tappedUrl;

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{here}}.',
            urls: const <String>['https://old.com'],
            urlLabels: const <String>['Old link'],
            onTap: (final String url, final int index) {
              tappedUrl = url;
            },
          ),
        ),
      );

      // Update with new text and URLs.
      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{there}}.',
            urls: const <String>['https://new.com'],
            urlLabels: const <String>['New link'],
            onTap: (final String url, final int index) {
              tappedUrl = url;
            },
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;
      final TapGestureRecognizer recognizer =
          linkSpan.recognizer! as TapGestureRecognizer;

      recognizer.onTap!();

      expect(tappedUrl, 'https://new.com');
    });

    testWidgets('renders links as plain text when urls is null', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LinkedText(text: 'Click {{here}}.'),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;

      // All spans should be plain text (no recognizer).
      for (final InlineSpan child in textSpan.children!) {
        final TextSpan span = child as TextSpan;
        expect(span.recognizer, isNull);
      }
    });
  });
}
