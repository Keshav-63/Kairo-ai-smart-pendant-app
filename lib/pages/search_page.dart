// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:smart_pendant_app/widgets/app_drawer.dart';
// import 'package:app_links/app_links.dart';

// class SearchPage extends StatefulWidget {
//   const SearchPage({super.key});

//   @override
//   State<SearchPage> createState() => _SearchPageState();
// }

// class _SearchPageState extends State<SearchPage> {
//   final _appLinks = AppLinks();
//   StreamSubscription<Uri>? _linkSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _initDeepLinks();
//   }

//   @override
//   void dispose() {
//     _linkSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> _initDeepLinks() async {
//     // Handle initial deep link when the app is launched from a cold state
//     final uri = await _appLinks.getInitialLink();
//     if (uri != null) {
//       _handleDeepLink(uri);
//     }

//     // Handle deep links when the app is already running
//     _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
//       _handleDeepLink(uri);
//     });
//   }

//   void _handleDeepLink(Uri uri) {
//     if (!mounted) return;
    
//     print('Deep link received: $uri');
//     // You can add navigation logic here based on the URI
//     // For now, we'll just show a SnackBar as a confirmation.
//     final message = 'Deep link handled: ${uri.host}${uri.path}';
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const AppDrawer(),
//       appBar: AppBar(
//         title: const Text('Smart Pendant'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit_outlined),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             const Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'What can I help with?',
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 20),
//                     Wrap(
//                       spacing: 8.0,
//                       runSpacing: 8.0,
//                       alignment: WrapAlignment.center,
//                       children: [
//                         SuggestionChip(label: 'Query on recording', icon: Icons.question_answer_outlined),
//                         SuggestionChip(label: 'Summarize last week', icon: Icons.summarize_outlined),
//                         SuggestionChip(label: 'Find action items', icon: Icons.check_circle_outline),
//                         SuggestionChip(label: 'Translate conversation', icon: Icons.translate_outlined),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Ask anything...',
//                   prefixIcon: IconButton(
//                     icon: const Icon(Icons.camera_alt_outlined),
//                     onPressed: () {},
//                   ),
//                   suffixIcon: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.mic_none),
//                         onPressed: () {},
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.headphones_outlined),
//                         onPressed: () {},
//                       ),
//                     ],
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30.0),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SuggestionChip extends StatelessWidget {
//   final String label;
//   final IconData icon;

//   const SuggestionChip({super.key, required this.label, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return ActionChip(
//       avatar: Icon(icon, size: 18),
//       label: Text(label),
//       onPressed: () {},
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20.0),
//         side: const BorderSide(color: Colors.white30),
//       ),
//       backgroundColor: Colors.grey.shade800,
//     );
//   }
// }







// ...existing code...
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pendant_app/services/api_service.dart';
import 'package:smart_pendant_app/services/local_storage_service.dart';
import 'package:smart_pendant_app/widgets/app_drawer.dart';
import 'package:app_links/app_links.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // <-- IMPORT MARKDOWN

// Data structure for chat messages (remains the same)
class ChatMessage {
  final String text;
  final bool isUser;
  final List<dynamic>? sources;

  ChatMessage({required this.text, required this.isUser, this.sources});
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // ... (rest of the state variables remain the same) ...
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  final TextEditingController _queryController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController(); // To auto-scroll

  String? _sessionId; // Store the current chat session ID
  List<ChatMessage> _chatHistory = [];
  bool _isLoading = false;


  // --- initState, dispose, Deep Link Handling, _createNewChatSession, _sendQuery, _scrollToBottom, _showError remain the same ---
  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _createNewChatSession(); // Start a new session when the page loads
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _handleDeepLink(uri);
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    debugPrint('[SearchPage] Deep link received: $uri');
    final message = 'Deep link handled: ${uri.host}${uri.path}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createNewChatSession() async {
    setState(() {
      _isLoading = true;
      _chatHistory = [];
      _sessionId = null;
    });
    try {
      final sessionId = await _apiService.createChatSession();
      if (mounted) {
        setState(() {
          _sessionId = sessionId;
          _isLoading = false;
        });
        if (sessionId == null) {
           _showError('Could not start a new chat session. Please try again.');
        }
      }
    } catch (e) {
       if (mounted) {
         setState(() => _isLoading = false);
         _showError('Error starting chat session: ${e.toString()}');
       }
    }
  }

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;

    final userId = LocalStorageService.instance.getUserId();

    if (userId == null) {
      _showError('User not logged in. Cannot send query.');
      return;
    }

    if (_sessionId == null) {
      await _createNewChatSession();
      if (_sessionId == null) {
         _showError('Cannot send query without a valid chat session.');
         return;
      }
    }

    setState(() {
      _isLoading = true;
      _chatHistory.add(ChatMessage(text: query, isUser: true));
      _queryController.clear();
    });
    _scrollToBottom();

    try {
      final response = await _api_service_sendQueryWrapper(query, userId, _sessionId!);

      if (mounted) {
        setState(() {
          if (response != null && response['answer'] != null) {
            _chatHistory.add(ChatMessage(
              text: response['answer'],
              isUser: false,
              sources: response['sources'],
            ));
          } else {
            _chatHistory.add(ChatMessage(
              text: "Sorry, I couldn't get a response. Please try again.",
              isUser: false,
            ));
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add(ChatMessage(
            text: "An error occurred: ${e.toString()}",
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // Wrapper to call ApiService with safe null checks (keeps sendQuery usage isolated)
  Future<Map<String, dynamic>?> _api_service_sendQueryWrapper(String query, String userId, String sessionId) async {
    return await _apiService.sendQuery(
      query: query,
      userId: userId,
      sessionId: sessionId,
    );
  }

   void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scroll_controller_animate();
      }
    });
  }

  void _scroll_controller_animate() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showError(String message) {
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
     }
  }


  @override
  Widget build(BuildContext context) {
    // ... (AppBar and overall Scaffold structure remains the same) ...
     return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text('Kairo AI', style: GoogleFonts.oxanium()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Chat',
            onPressed: _isLoading ? null : _createNewChatSession, // Start new session
          ),
        ],
        backgroundColor: const Color(0xFF1E1E24), // Darker app bar
      ),
      backgroundColor: const Color(0xFF0D0D12), // Dark background
      body: Column(
        children: [
          Expanded(
            child: _chatHistory.isEmpty && !_isLoading
                ? _buildInitialSuggestions() // Show suggestions if history is empty
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _chatHistory.length + (_isLoading ? 1 : 0), // Add space for loader
                    itemBuilder: (context, index) {
                      if (index == _chatHistory.length) {
                        return _buildLoadingIndicator(); // Show loader at the bottom
                      }
                      final message = _chatHistory[index];
                      return _buildChatMessage(message);
                    },
                  ),
          ),
          _buildQueryInput(), // Input field at the bottom
        ],
      ),
    );
  }

  // --- _buildInitialSuggestions, _setQueryText remain the same ---
  Widget _buildInitialSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What can I help with?',
            style: GoogleFonts.oxanium(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              SuggestionChip(label: 'Query on recording', icon: Icons.question_answer_outlined, onTap: () => _setQueryText('Query on recording')),
              SuggestionChip(label: 'Summarize last week', icon: Icons.summarize_outlined, onTap: () => _setQueryText('Summarize last week')),
              SuggestionChip(label: 'Find action items', icon: Icons.check_circle_outline, onTap: () => _setQueryText('Find action items from my last meeting')),
              SuggestionChip(label: 'Translate conversation', icon: Icons.translate_outlined, onTap: () => _setQueryText('Translate my last conversation to Spanish')),
            ],
          )
        ],
      ),
    );
  }

  void _setQueryText(String text) {
    _queryController.text = text;
    // Optionally send the query directly: _sendQuery();
  }


  // --- MODIFIED: _buildChatMessage ---
  // Builds the chat message bubble, using Markdown for assistant messages
  Widget _buildChatMessage(ChatMessage message) {
    // Define base text style
    final textStyle = GoogleFonts.inter(color: Colors.white, fontSize: 15);

    // Use the app theme but ensure bodyMedium has a fontSize (prevents flutter_markdown assertion)
    final ThemeData theme = Theme.of(context);
    final safeTextTheme = theme.textTheme.copyWith(
      bodyMedium: theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 15),
    );
    final ThemeData safeTheme = theme.copyWith(textTheme: safeTextTheme);

    final baseMd = MarkdownStyleSheet.fromTheme(safeTheme);
    final markdownStyle = baseMd.copyWith(
      p: textStyle,
      h1: textStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
      h2: textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
      code: const TextStyle(backgroundColor: Color(0xFF0F0F10), color: Colors.greenAccent, fontFamily: 'monospace'),
      blockquote: const TextStyle(color: Colors.white70),
      listBullet: textStyle,
    );

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Max width
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.indigoAccent : const Color(0xFF2A2A30),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min, // Important for Markdown sizing
           children: [
              // Use MarkdownBody for assistant, Text for user
              message.isUser
                ? Text(message.text, style: textStyle)
                : MarkdownBody(
                    data: message.text,
                    styleSheet: markdownStyle,
                    selectable: true, // Allow text selection
                 ),
              // Optionally display sources if they exist
              if (message.sources != null && message.sources!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Sources:',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                ...message.sources!.map((source) {
                   final text = (source is Map && source.containsKey('text')) ? source['text'] ?? '' : source.toString();
                   final snippet = text.length > 80 ? '${text.substring(0, 80)}...' : text;
                   return Padding(
                     padding: const EdgeInsets.only(top: 2.0),
                     child: Text(
                        '- $snippet', // Display longer snippet
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                      ),
                   );
                }).toList(),
              ]
           ],
        ),
      ),
    );
  }
  // --- END MODIFIED: _buildChatMessage ---


  // --- _buildLoadingIndicator, _buildQueryInput remain the same ---
   Widget _buildLoadingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildQueryInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24), // Dark input background
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: [
            // Placeholder buttons - add functionality later
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
              tooltip: 'Attach',
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _queryController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask Kairo anything...',
                  hintStyle: GoogleFonts.inter(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0), // Adjust padding
                ),
                onSubmitted: (_) => _sendQuery(), // Send on enter
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 5, // Allow multi-line input
              ),
            ),
            // Send button
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: _isLoading ? Colors.grey : Colors.indigoAccent,
              ),
              tooltip: 'Send',
              onPressed: _isLoading ? null : _sendQuery,
            ),
          ],
        ),
      ),
    );
  }

}

// --- SuggestionChip remains the same ---
class SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const SuggestionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: GoogleFonts.oxanium(color: Colors.white)),
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(color: Colors.white30),
      ),
      backgroundColor: Colors.grey.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
// ...existing code...