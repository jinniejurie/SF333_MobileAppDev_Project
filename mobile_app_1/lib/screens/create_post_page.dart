import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'community_home.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final List<String> _tags = [];
  final List<XFile> _media = [];
  bool _isPosting = false;

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _media.add(image));
    }
  }

  void _addTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(controller: c, decoration: const InputDecoration(prefixText: '# ')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Add')),
          ],
        );
      },
    );
    if (tag != null && tag.isNotEmpty) {
      setState(() => _tags.add(tag.replaceAll('#', '')));
    }
  }

  Future<List<String>> _convertMediaToBase64() async {
    if (_media.isEmpty) return [];
    final base64Images = <String>[];
    for (final media in _media) {
      try {
        final file = File(media.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        base64Images.add(base64String);
      } catch (e) {
        // Skip failed conversion
        print('Failed to convert image to base64: $e');
      }
    }
    return base64Images;
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isPosting = true);
    final posts = FirebaseFirestore.instance.collection('posts');
    final newDoc = posts.doc();
    final base = {
      'postId': newDoc.id,
      'uid': 'demo-user-001',
      'authorName': 'Jane Doe',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      'title': _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      'content': text,
      'communityId': null,
      'likesCount': 0,
      'commentsCount': 0,
      'likes': <String>[],
      'tags': _tags,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      final base64Images = await _convertMediaToBase64();
      final data = {...base, 'mediaUrls': base64Images};
      await newDoc.set(data);
      if (!mounted) return;
      // Navigate back to feed immediately on success
      Navigator.of(context).pop(true);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Image.asset('assets/cloud_logo.png', width: 40, height: 32),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profileSettings');
                      },
                      child: const CircleAvatar(radius: 14, backgroundColor: Colors.black12, child: Icon(Icons.person, size: 16)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jane Doe',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Title (optional)',
                            filled: true,
                            fillColor: const Color(0xFFF7F8FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ).copyWith(
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            decoration: InputDecoration(
                              hintText: 'Write your post  here',
                              filled: true,
                              fillColor: const Color(0xFFD6F0FF),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_media.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _media.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, i) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(File(_media[i].path), fit: BoxFit.cover, width: 120, height: 90),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _media.removeAt(i)),
                                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final choice = await showModalBottomSheet<String>(
                                  context: context,
                                  builder: (context) => SafeArea(
                                    child: Wrap(children: [
                                      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(context, 'camera')),
                                      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(context, 'gallery')),
                                    ]),
                                  ),
                                );
                                if (choice == 'camera') _pickMedia(ImageSource.camera);
                                if (choice == 'gallery') _pickMedia(ImageSource.gallery);
                              },
                              child: _lightButton(icon: Icons.attach_file, label: 'Add media'),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _addTag,
                              child: _lightButton(icon: Icons.tag, label: 'Add Tag'),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _tags
                                .map((t) => Chip(label: Text('#$t'), onDeleted: () => setState(() => _tags.remove(t))))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _isPosting ? null : _submit,
                            icon: const Icon(Icons.send),
                            label: Text(_isPosting ? 'Posting...' : 'Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF90CAF9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightButton({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)]),
    );
  }
}


