import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../providers/accessibility_provider.dart';
import 'package:provider/provider.dart';

class TtsButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;

  const TtsButton({
    super.key,
    required this.text,
    this.icon = Icons.volume_up,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  final TtsService _ttsService = TtsService();
  bool _isSpeaking = false;

  // TTS will be initialized lazily when speak() is called

  Future<void> _handleTts() async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    
    if (!accessibility.ttsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text-to-Speech is disabled. Please enable it in settings.')),
      );
      return;
    }

    if (_isSpeaking) {
      try {
        await _ttsService.stop();
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSpeaking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TTS Error: Please restart the app for TTS to work')),
          );
        }
      }
    } else {
      setState(() => _isSpeaking = true);
      try {
        await _ttsService.speak(widget.text);
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSpeaking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TTS Error: Please restart the app for TTS to work')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final theme = Theme.of(context);
    
    if (!accessibility.ttsEnabled) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: _handleTts,
      icon: Icon(
        _isSpeaking ? Icons.volume_off : widget.icon,
        color: widget.iconColor ?? theme.iconTheme.color,
      ),
      tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
    );
  }
}

