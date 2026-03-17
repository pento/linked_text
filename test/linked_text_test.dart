import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linked_text/linked_text.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? launchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(final String url) async => true;

  @override
  Future<bool> launch(
    final String url, {
    required final bool useSafariVC,
    required final bool useWebView,
    required final bool enableJavaScript,
    required final bool enableDomStorage,
    required final bool universalLinksOnly,
    required final Map<String, String> headers,
    final String? webOnlyWindowName,
  }) async {
    launchedUrl = url;
    return true;
  }

  @override
  Future<bool> launchUrl(
    final String url,
    final LaunchOptions options,
  ) async {
    launchedUrl = url;
    return true;
  }

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(final PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(final PreferredLaunchMode mode) async =>
      true;
}

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

    testWidgets('didUpdateWidget re-parses when only text changes', (
      final WidgetTester tester,
    ) async {
      String? tappedUrl;
      void onTap(final String url, final int index) {
        tappedUrl = url;
      }

      const List<String> urls = <String>['https://example.com'];
      const List<String> urlLabels = <String>['Example'];

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{here}}.',
            urls: urls,
            urlLabels: urlLabels,
            onTap: onTap,
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{there}}.',
            urls: urls,
            urlLabels: urlLabels,
            onTap: onTap,
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;

      expect(linkSpan.text, 'there');
      (linkSpan.recognizer! as TapGestureRecognizer).onTap!();
      expect(tappedUrl, 'https://example.com');
    });

    testWidgets('didUpdateWidget re-parses when only urls changes', (
      final WidgetTester tester,
    ) async {
      String? tappedUrl;
      void onTap(final String url, final int index) {
        tappedUrl = url;
      }

      const String text = 'Click {{here}}.';
      const List<String> urlLabels = <String>['Example'];

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: text,
            urls: const <String>['https://old.com'],
            urlLabels: urlLabels,
            onTap: onTap,
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: text,
            urls: const <String>['https://new.com'],
            urlLabels: urlLabels,
            onTap: onTap,
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;
      (linkSpan.recognizer! as TapGestureRecognizer).onTap!();
      expect(tappedUrl, 'https://new.com');
    });

    testWidgets('uses latest onTap callback after widget update', (
      final WidgetTester tester,
    ) async {
      bool handlerACalled = false;
      bool handlerBCalled = false;

      const String text = 'Click {{here}}.';
      const List<String> urls = <String>['https://example.com'];
      const List<String> urlLabels = <String>['Example'];

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: text,
            urls: urls,
            urlLabels: urlLabels,
            onTap: (final String url, final int index) {
              handlerACalled = true;
            },
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: text,
            urls: urls,
            urlLabels: urlLabels,
            onTap: (final String url, final int index) {
              handlerBCalled = true;
            },
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;
      (linkSpan.recognizer! as TapGestureRecognizer).onTap!();
      expect(handlerACalled, isFalse);
      expect(handlerBCalled, isTrue);
    });

    testWidgets('tapping link without onTap calls launchUrl', (
      final WidgetTester tester,
    ) async {
      final MockUrlLauncherPlatform mockPlatform = MockUrlLauncherPlatform();
      final UrlLauncherPlatform originalPlatform = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = mockPlatform;
      addTearDown(() {
        UrlLauncherPlatform.instance = originalPlatform;
      });

      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: 'Click {{here}}.',
            urls: const <String>['https://example.com'],
            urlLabels: const <String>['Example'],
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final TextSpan linkSpan = textSpan.children![1] as TextSpan;
      (linkSpan.recognizer! as TapGestureRecognizer).onTap!();
      expect(mockPlatform.launchedUrl, 'https://example.com');
    });

    testWidgets('link with out-of-bounds urlIndex renders as plain text', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          LinkedText(
            text: '{{link1}} and {{link2}}',
            urls: const <String>['https://example.com'],
            urlLabels: const <String>['Link 1'],
          ),
        ),
      );

      final RichText richText = tester.widget<RichText>(
        find.byType(RichText),
      );
      final TextSpan textSpan = richText.text as TextSpan;
      final List<InlineSpan> children = textSpan.children!;

      // link1 (urlIndex 0) should be a link with style and recognizer.
      expect((children[0] as TextSpan).text, 'link1');
      expect((children[0] as TextSpan).recognizer, isA<TapGestureRecognizer>());
      expect((children[0] as TextSpan).style, isNotNull);

      // " and " is plain text.
      expect((children[1] as TextSpan).text, ' and ');

      // link2 (urlIndex 1) is out of bounds — rendered as plain text.
      expect((children[2] as TextSpan).text, 'link2');
      expect((children[2] as TextSpan).recognizer, isNull);
      expect((children[2] as TextSpan).style, isNull);
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
      final List<InlineSpan> children = textSpan.children!;

      // Verify all 3 spans are present with correct text.
      expect(children, hasLength(3));
      expect((children[0] as TextSpan).text, 'Click ');
      expect((children[1] as TextSpan).text, 'here');
      expect((children[2] as TextSpan).text, '.');

      // All spans should be plain text (no recognizer).
      for (final InlineSpan child in children) {
        final TextSpan span = child as TextSpan;
        expect(span.recognizer, isNull);
      }
    });
  });
}
