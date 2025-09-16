import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;
  final String currentUserId;
  const EventDetailPage({super.key, required this.eventId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Center(
        child: Text('Event $eventId for user $currentUserId'),
      ),
    );
  }
}


