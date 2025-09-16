import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_page.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedStartTime = picked);
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? (_selectedStartTime ?? TimeOfDay.now()),
    );
    if (picked != null) setState(() => _selectedEndTime = picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Pick date';
    return '${d.day}/${d.month}/${d.year}';
    }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Pick time';
    final String hh = t.hourOfPeriod.toString().padLeft(2, '0');
    final String mm = t.minute.toString().padLeft(2, '0');
    final String period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hh:$mm$period';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final String organizer = FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
          ? FirebaseAuth.instance.currentUser!.displayName!.trim()
          : (FirebaseAuth.instance.currentUser?.email?.trim().isNotEmpty == true
              ? FirebaseAuth.instance.currentUser!.email!.trim()
              : (uid.isNotEmpty ? uid : 'Anonymous'));

      final DateTime baseDate = _selectedDate!;
      Timestamp dateTs = Timestamp.fromDate(DateTime(baseDate.year, baseDate.month, baseDate.day));

      Timestamp? startTs;
      if (_selectedStartTime != null) {
        final t = _selectedStartTime!;
        startTs = Timestamp.fromDate(DateTime(baseDate.year, baseDate.month, baseDate.day, t.hour, t.minute));
      }
      Timestamp? endTs;
      if (_selectedEndTime != null) {
        final t = _selectedEndTime!;
        endTs = Timestamp.fromDate(DateTime(baseDate.year, baseDate.month, baseDate.day, t.hour, t.minute));
      }

      final Map<String, dynamic> payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'organizer': organizer,
        'ownerId': uid,
        'date': dateTs,
        if (startTs != null) 'start_time': startTs,
        if (endTs != null) 'end_time': endTs,
        'registered': <String>[],
        'likes': <String>[],
        'favorites': <String>[],
        'upvotes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('events').add(payload);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EventDetailPage(
            eventId: docRef.id,
            currentUserId: uid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                    const CircleAvatar(radius: 14, backgroundColor: Colors.black12, child: Icon(Icons.person, size: 16)),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create Event',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              filled: true,
                              fillColor: Color(0xFFF7F8FF),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'Location',
                              filled: true,
                              fillColor: Color(0xFFF7F8FF),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              hintText: 'Image URL (optional)',
                              filled: true,
                              fillColor: Color(0xFFF7F8FF),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Describe your event',
                              filled: true,
                              fillColor: const Color(0xFFD6F0FF),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.black26),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.black87),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickDate,
                                  child: _lightPicker(label: _formatDate(_selectedDate)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickStartTime,
                                  child: _lightPicker(label: 'Start: ${_formatTime(_selectedStartTime)}'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickEndTime,
                                  child: _lightPicker(label: 'End: ${_formatTime(_selectedEndTime)}'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : _submit,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                                    child: _submitting
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Create', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _lightPicker({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}


