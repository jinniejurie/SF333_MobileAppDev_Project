import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId, required this.otherUserId});

  final String chatId;
  final String otherUserId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setPresence(true);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // For reverse ListView, scroll to position 0 (which is the bottom)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _setPresence(false);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setPresence(bool online) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom top bar matching mock (light blue background)
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              width: double.infinity,
              color: const Color(0xFFC8ECF7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                  // Center name
                  Expanded(
                    child: Center(
                      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _firestore.collection('users').doc(widget.otherUserId).snapshots(),
                        builder: (context, snap) {
                          final data = snap.data?.data();
                          final name = data?['name'] ?? 'Name';
                          return Text(
                            name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          );
                        },
                      ),
                    ),
                  ),
                  // More menu button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                // Handle connection state
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Handle errors
                if (snapshot.hasError) {
                  final errorMsg = snapshot.error.toString();
                  final isNetworkError = errorMsg.contains('UNAVAILABLE') || 
                                       errorMsg.contains('Unable to resolve host') ||
                                       errorMsg.contains('network');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isNetworkError ? Icons.wifi_off : Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isNetworkError 
                              ? 'No internet connection\nPlease check your network and try again'
                              : 'Connection error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Handle no data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                final docs = snapshot.data!.docs;
                // Mark as read on new messages
                _chatService.markMessagesAsRead(widget.chatId);
                
                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // Reverse index to show newest messages at bottom
                    final reversedIndex = docs.length - 1 - index;
                    final m = docs[reversedIndex].data();
                    final fromMe = m['senderId'] == uid;
                    final text = (m['text'] ?? '') as String;
                    final imageUrl = m['imageUrl'] as String?;
                    final readBy = List<String>.from(m['readBy'] ?? []);
                    final sent = readBy.isNotEmpty;
                    final read = readBy.contains(widget.otherUserId);
                    final timestamp = m['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null 
                        ? _formatTime(timestamp.toDate()) 
                        : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!fromMe) ...[
                            _SmallAvatar(userId: m['senderId'] as String),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE7F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
                                    child: _buildImageWidget(imageUrl),
                                  ),
                                if (text.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (fromMe && timeStr.isNotEmpty) ...[
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        constraints: const BoxConstraints(maxWidth: 320),
                                        decoration: BoxDecoration(
                                          color: fromMe ? Colors.black : const Color(0xFFEDE7F6),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: fromMe ? Colors.white : const Color(0xFF47424F),
                                            fontWeight: fromMe ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (!fromMe && timeStr.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _MockInputBar(
            chatId: widget.chatId,
            chatService: _chatService,
            onSend: (text) => _chatService.sendTextMessage(widget.chatId, text),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a base64 string (starts with data: or is a long string without http/https)
    if (imageUrl.startsWith('data:image') || 
        (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://') && imageUrl.length > 100)) {
      try {
        // Try to decode as base64
        final imageBytes = base64Decode(imageUrl);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 50);
          },
        );
      } catch (e) {
        // If decoding fails, try as network image
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 50);
          },
        );
      }
    } else {
      // It's a URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50);
        },
      );
    }
  }
}

class _MockInputBar extends StatefulWidget {
  const _MockInputBar({
    required this.onSend,
    required this.chatId,
    required this.chatService,
  });
  final Future<void> Function(String text) onSend;
  final String chatId;
  final ChatService chatService;

  @override
  State<_MockInputBar> createState() => _MockInputBarState();
}

class _MockInputBarState extends State<_MockInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        await widget.chatService.sendImageMessage(widget.chatId, base64Image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFC8ECF7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: _showImagePicker,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add image',
              ),
              IconButton(
                onPressed: () {
                  // Toggle emoji keyboard by focusing/unfocusing
                  if (_focusNode.hasFocus) {
                    _focusNode.unfocus();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _focusNode.requestFocus();
                    });
                  } else {
                    _focusNode.requestFocus();
                  }
                },
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: 'Emoji',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(height: 1.2),
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await widget.onSend(text);
                  _controller.clear();
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final avatarBase64 = snapshot.data?.data()?['avatarBase64'] as String?;
        
        if (avatarBase64 != null && avatarBase64.isNotEmpty) {
          try {
            final imageBytes = base64Decode(avatarBase64);
            return CircleAvatar(
              radius: 14,
              backgroundColor: const Color.fromARGB(255, 247, 240, 255),
              backgroundImage: MemoryImage(imageBytes),
            );
          } catch (e) {
            // If decoding fails, show placeholder
            return _buildPlaceholder();
          }
        }
        
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFE5DEED),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}