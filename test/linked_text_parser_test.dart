import 'package:flutter_test/flutter_test.dart';
import 'package:linked_text/linked_text.dart';

void main() {
  group('parseLinkedText', () {
    test('returns empty list for empty input', () {
      expect(parseLinkedText(''), isEmpty);
    });

    test('returns single plain segment for text without links', () {
      final List<LinkedTextSegment> result = parseLinkedText('Hello, world!');

      expect(result, hasLength(1));
      expect(result[0], const PlainTextSegment('Hello, world!'));
    });

    test('parses single un-indexed link', () {
      final List<LinkedTextSegment> result =
          parseLinkedText('Visit {{Flutter}}.');

      expect(result, hasLength(3));
      expect(result[0], const PlainTextSegment('Visit '));
      expect(
        result[1],
        const LinkTextSegment(text: 'Flutter', urlIndex: 0),
      );
      expect(result[2], const PlainTextSegment('.'));
    });

    test('parses single numbered link', () {
      final List<LinkedTextSegment> result =
          parseLinkedText('Visit {1{Flutter}}.');

      expect(result, hasLength(3));
      expect(result[0], const PlainTextSegment('Visit '));
      expect(
        result[1],
        const LinkTextSegment(text: 'Flutter', urlIndex: 0),
      );
      expect(result[2], const PlainTextSegment('.'));
    });

    test('parses multiple numbered links', () {
      final List<LinkedTextSegment> result = parseLinkedText(
        'Use {1{Flutter}} and {2{Dart}}.',
      );

      expect(result, hasLength(5));
      expect(result[0], const PlainTextSegment('Use '));
      expect(
        result[1],
        const LinkTextSegment(text: 'Flutter', urlIndex: 0),
      );
      expect(result[2], const PlainTextSegment(' and '));
      expect(
        result[3],
        const LinkTextSegment(text: 'Dart', urlIndex: 1),
      );
      expect(result[4], const PlainTextSegment('.'));
    });

    test('auto-assigns sequential indices to un-indexed links', () {
      final List<LinkedTextSegment> result = parseLinkedText(
        '{{Privacy Policy}} | {{EULA}}',
      );

      expect(result, hasLength(3));
      expect(
        result[0],
        const LinkTextSegment(text: 'Privacy Policy', urlIndex: 0),
      );
      expect(result[1], const PlainTextSegment(' | '));
      expect(
        result[2],
        const LinkTextSegment(text: 'EULA', urlIndex: 1),
      );
    });

    test('handles text before and after link', () {
      final List<LinkedTextSegment> result = parseLinkedText(
        'Before {{link}} after',
      );

      expect(result, hasLength(3));
      expect(result[0], const PlainTextSegment('Before '));
      expect(
        result[1],
        const LinkTextSegment(text: 'link', urlIndex: 0),
      );
      expect(result[2], const PlainTextSegment(' after'));
    });

    test('handles adjacent links', () {
      final List<LinkedTextSegment> result =
          parseLinkedText('{{first}}{{second}}');

      expect(result, hasLength(2));
      expect(
        result[0],
        const LinkTextSegment(text: 'first', urlIndex: 0),
      );
      expect(
        result[1],
        const LinkTextSegment(text: 'second', urlIndex: 1),
      );
    });

    test('handles link at start of text', () {
      final List<LinkedTextSegment> result = parseLinkedText('{{link}} after');

      expect(result, hasLength(2));
      expect(
        result[0],
        const LinkTextSegment(text: 'link', urlIndex: 0),
      );
      expect(result[1], const PlainTextSegment(' after'));
    });

    test('handles link at end of text', () {
      final List<LinkedTextSegment> result = parseLinkedText('Before {{link}}');

      expect(result, hasLength(2));
      expect(result[0], const PlainTextSegment('Before '));
      expect(
        result[1],
        const LinkTextSegment(text: 'link', urlIndex: 0),
      );
    });

    test('handles special characters in link text', () {
      final List<LinkedTextSegment> result = parseLinkedText(
        'Read the {{Terms & Conditions}}.',
      );

      expect(result, hasLength(3));
      expect(
        result[1],
        const LinkTextSegment(
          text: 'Terms & Conditions',
          urlIndex: 0,
        ),
      );
    });

    test('handles text that is only a link', () {
      final List<LinkedTextSegment> result = parseLinkedText('{{only link}}');

      expect(result, hasLength(1));
      expect(
        result[0],
        const LinkTextSegment(text: 'only link', urlIndex: 0),
      );
    });

    test('PlainTextSegment equality', () {
      expect(
        const PlainTextSegment('a'),
        equals(const PlainTextSegment('a')),
      );
      expect(
        const PlainTextSegment('a'),
        isNot(equals(const PlainTextSegment('b'))),
      );
    });

    test('LinkTextSegment equality', () {
      expect(
        const LinkTextSegment(text: 'a', urlIndex: 0),
        equals(const LinkTextSegment(text: 'a', urlIndex: 0)),
      );
      expect(
        const LinkTextSegment(text: 'a', urlIndex: 0),
        isNot(
          equals(const LinkTextSegment(text: 'a', urlIndex: 1)),
        ),
      );
      expect(
        const LinkTextSegment(text: 'a', urlIndex: 0),
        isNot(
          equals(const LinkTextSegment(text: 'b', urlIndex: 0)),
        ),
      );
    });

    test('segment toString representations', () {
      expect(
        const PlainTextSegment('hello').toString(),
        'PlainTextSegment("hello")',
      );
      expect(
        const LinkTextSegment(text: 'link', urlIndex: 0).toString(),
        'LinkTextSegment("link", urlIndex: 0)',
      );
    });

    test('three un-indexed links get sequential indices', () {
      final List<LinkedTextSegment> result = parseLinkedText(
        '{{A}} {{B}} {{C}}',
      );

      expect(result, hasLength(5));
      expect(
        result[0],
        const LinkTextSegment(text: 'A', urlIndex: 0),
      );
      expect(result[1], const PlainTextSegment(' '));
      expect(
        result[2],
        const LinkTextSegment(text: 'B', urlIndex: 1),
      );
      expect(result[3], const PlainTextSegment(' '));
      expect(
        result[4],
        const LinkTextSegment(text: 'C', urlIndex: 2),
      );
    });
  });
}
