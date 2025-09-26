import 'package:flutter/material.dart';
import 'package:smart_pendant_app/widgets/app_drawer.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

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

  // ADDED const to this constructor
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