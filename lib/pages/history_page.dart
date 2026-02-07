import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/local_storage_service.dart';
import '../constants/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoadingChats = true;
  bool _isLoadingMessages = false;
  String? _error;
  List<ChatSession> _chats = [];
  ChatSession? _selectedChat;
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isSidebarMinimized = false;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchChats() async {
    setState(() {
      _isLoadingChats = true;
      _error = null;
    });

    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final url = Uri.parse('$baseUrl/chats/user/$userId');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final chats = data.map((json) => ChatSession.fromJson(json)).toList();

        // Sort by creation date, most recent first
        chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _chats = chats;
          _isLoadingChats = false;
        });

        // Automatically load the most recent chat
        if (chats.isNotEmpty) {
          await _loadChatHistory(chats[0]);
        }
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load your chat history.';
        _isLoadingChats = false;
      });
      debugPrint('[HistoryPage] Error fetching chats: $e');
    }
  }

  Future<void> _loadChatHistory(ChatSession chat) async {
    if (_selectedChat?.sessionId == chat.sessionId) return;

    setState(() {
      _isLoadingMessages = true;
      _messages = [];
    });

    try {
      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final url = Uri.parse('$baseUrl/chats/${chat.sessionId}');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data['history'] as List<dynamic>?;

        setState(() {
          _selectedChat = chat;
          _messages = history
                  ?.map((json) => ChatMessage.fromJson(json))
                  .toList() ??
              [];
          _isLoadingMessages = false;
          _isSidebarMinimized = true;
        });

        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load chat messages')),
      );
      setState(() {
        _isLoadingMessages = false;
      });
      debugPrint('[HistoryPage] Error loading chat history: $e');
    }
  }

  Future<void> _createNewChat() async {
    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();

      if (userId == null) return;

      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final url = Uri.parse('$baseUrl/chats');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New chat created!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the chat list
        await _fetchChats();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create new chat'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('[HistoryPage] Error creating new chat: $e');
    }
  }

  void _showPlusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.greenAccent,
                  ),
                ),
                title: const Text(
                  'New Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Start a new conversation',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createNewChat();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.blueAccent,
                  ),
                ),
                title: const Text(
                  'View All History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Browse your previous chats',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Already on history page, just scroll to top
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text('Chat History', style: AppTheme.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSidebarMinimized ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _isSidebarMinimized = !_isSidebarMinimized;
              });
            },
            tooltip: _isSidebarMinimized ? 'Expand Sidebar' : 'Minimize Sidebar',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 28),
            onPressed: _showPlusMenu,
            tooltip: 'New Chat or View History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoadingChats
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildChatInterface(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryAccent),
          SizedBox(height: 16),
          Text(
            'Loading your conversations...',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchChats,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Row(
      children: [
        // Left sidebar - Chat list
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isSidebarMinimized ? 70 : 280,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border(
              right: BorderSide(color: AppTheme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isSidebarMinimized
                    ? const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 24,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Conversations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_chats.length}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: _chats.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _isSidebarMinimized
                              ? const Icon(
                                  Icons.inbox,
                                  color: Colors.white30,
                                  size: 32,
                                )
                              : const Text(
                                  'No chat history found.\nStart a conversation in Query AI!',
                                  style: TextStyle(color: Colors.white60),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          final isSelected =
                              _selectedChat?.sessionId == chat.sessionId;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.indigoAccent.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isSidebarMinimized
                                ? InkWell(
                                    onTap: () => _loadChatHistory(chat),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: Icon(
                                          Icons.chat_bubble,
                                          color: isSelected
                                              ? Colors.indigoAccent
                                              : Colors.white60,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListTile(
                                    onTap: () => _loadChatHistory(chat),
                                    title: Text(
                                      chat.title.isEmpty ? 'Chat Session' : chat.title,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.indigoAccent
                                            : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      DateFormat('MMM dd, yyyy hh:mm a')
                                          .format(chat.createdAt),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Right side - Message display
        Expanded(
          child: _selectedChat == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a conversation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a chat from the left panel',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Chat header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedChat!.title.isEmpty
                                  ? 'Chat Details'
                                  : _selectedChat!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: _isLoadingMessages
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.indigoAccent,
                              ),
                            )
                          : _messages.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No messages in this chat yet',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    return _buildMessageBubble(
                                        _messages[index]);
                                  },
                                ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigoAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white, fontSize: 14),
                  code: TextStyle(
                    color: Colors.greenAccent,
                    backgroundColor: Colors.black26,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat Session model
class ChatSession {
  final String sessionId;
  final String title;
  final DateTime createdAt;

  ChatSession({
    required this.sessionId,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['_id']?['\$oid'] ?? json['session_id'] ?? '',
      title: json['title'] ?? '',
      createdAt: json['created_at']?['\$date'] != null
          ? DateTime.parse(json['created_at']['\$date'])
          : DateTime.now(),
    );
  }
}

// Chat Message model
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: json['timestamp']?['\$date'] != null
          ? DateTime.parse(json['timestamp']['\$date'])
          : json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
    );
  }
}
