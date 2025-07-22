import 'package:flutter/material.dart';

class EventsPlaceholderScreen extends StatelessWidget {
  const EventsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen might eventually have its own Scaffold if complex,
    // but for now, it uses the AppBar provided by MainScreen.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Events Screen\n(Your created/upcoming events will appear here)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}