import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pendant_app/widgets/app_drawer.dart';
import 'package:app_links/app_links.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial deep link when the app is launched from a cold state
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(uri);
    }

    // Handle deep links when the app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    
    print('Deep link received: $uri');
    // You can add navigation logic here based on the URI
    // For now, we'll just show a SnackBar as a confirmation.
    final message = 'Deep link handled: ${uri.host}${uri.path}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Smart Pendant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'What can I help with?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [
                        SuggestionChip(label: 'Query on recording', icon: Icons.question_answer_outlined),
                        SuggestionChip(label: 'Summarize last week', icon: Icons.summarize_outlined),
                        SuggestionChip(label: 'Find action items', icon: Icons.check_circle_outline),
                        SuggestionChip(label: 'Translate conversation', icon: Icons.translate_outlined),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: () {},
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mic_none),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.headphones_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const SuggestionChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(color: Colors.white30),
      ),
      backgroundColor: Colors.grey.shade800,
    );
  }
}