import 'package:flutter/material.dart';
import 'package:linked_text/linked_text.dart';

void main() {
  runApp(const LinkedTextExampleApp());
}

/// Example app demonstrating the LinkedText widget.
class LinkedTextExampleApp extends StatelessWidget {
  /// Constructor.
  const LinkedTextExampleApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
        title: 'LinkedText Example',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const ExamplePage(),
      );
}

/// Example page showing various LinkedText configurations.
class ExamplePage extends StatelessWidget {
  /// Constructor.
  const ExamplePage({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('LinkedText Examples')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Plain text (no links):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const LinkedText(
                text: 'This is plain text without any links.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Single link:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinkedText(
                text: 'Built with {{Flutter}}.',
                urls: const <String>['https://flutter.dev'],
                urlLabels: const <String>['Link to Flutter website'],
              ),
              const SizedBox(height: 24),
              const Text(
                'Multiple auto-indexed links:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinkedText(
                text: '{{Privacy Policy}} | {{Terms of Service}}',
                urls: const <String>[
                  'https://example.com/privacy',
                  'https://example.com/terms',
                ],
                urlLabels: const <String>[
                  'Link to Privacy Policy',
                  'Link to Terms of Service',
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Explicitly indexed links:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinkedText(
                text: 'Weather data from {1{Bureau of Meteorology}}, '
                    'via the {2{WillyWeather API}}.',
                urls: const <String>[
                  'http://www.bom.gov.au/',
                  'https://www.willyweather.com.au/',
                ],
                urlLabels: const <String>[
                  'Link to Bureau of Meteorology',
                  'Link to WillyWeather',
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Custom styles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinkedText(
                text: 'Check out {{this link}}.',
                urls: const <String>['https://example.com'],
                urlLabels: const <String>['Example link'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                linkStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Custom onTap handler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinkedText(
                text: 'Tap {{here}} to show a snackbar.',
                urls: const <String>['snackbar'],
                urlLabels: const <String>['Show snackbar'],
                onTap: (final String url, final int index) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped link $index (url: $url)'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}
