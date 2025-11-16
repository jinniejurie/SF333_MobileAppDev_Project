import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/tts_service.dart';
import '../widgets/accessible_container.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  final TtsService _ttsService = TtsService();
  bool? _localHighContrastMode;
  bool? _localTtsEnabled;

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        final theme = Theme.of(context);
        
        // Sync local state with provider
        if (_localHighContrastMode == null) {
          _localHighContrastMode = accessibility.highContrastMode;
        }
        if (_localTtsEnabled == null) {
          _localTtsEnabled = accessibility.ttsEnabled;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Accessibility Settings'),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          body: AccessibleContainer(
            decoration: BoxDecoration(
              gradient: !accessibility.highContrastMode
                  ? const LinearGradient(
                      colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: accessibility.highContrastMode ? Colors.white : null,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // High Contrast Mode
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Semantics(
                              label: 'High Contrast Mode icon',
                              child: Icon(Icons.contrast, color: theme.colorScheme.primary),
                            ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      'High Contrast Mode',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Semantics(
                                    child: Text(
                                      'Black and white theme for colorblind users',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: 'High Contrast Mode',
                                  value: (_localHighContrastMode ?? accessibility.highContrastMode) ? 'On' : 'Off',
                                  child: Switch(
                                    value: _localHighContrastMode ?? accessibility.highContrastMode,
                                    onChanged: (value) async {
                                      setState(() {
                                        _localHighContrastMode = value; // Update UI immediately
                                      });
                                      await accessibility.setHighContrastMode(value);
                                      if (mounted) {
                                        setState(() {
                                          _localHighContrastMode = accessibility.highContrastMode; // Sync with provider
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Text-to-Speech
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Semantics(
                              label: 'Text-to-Speech icon',
                              child: Icon(Icons.volume_up, color: theme.colorScheme.primary),
                            ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      'Text-to-Speech',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Semantics(
                                    child: Text(
                                      'Read text aloud for visually impaired users',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: 'Text-to-Speech',
                                  value: (_localTtsEnabled ?? accessibility.ttsEnabled) ? 'On' : 'Off',
                                  child: Switch(
                                    value: _localTtsEnabled ?? accessibility.ttsEnabled,
                                    onChanged: (value) async {
                                      setState(() {
                                        _localTtsEnabled = value; // Update UI immediately
                                      });
                                      await accessibility.setTtsEnabled(value);
                                      if (mounted) {
                                        setState(() {
                                          _localTtsEnabled = accessibility.ttsEnabled; // Sync with provider
                                        });
                                      }
                                      if (value) {
                                        // Wait a bit for TTS to initialize
                                        Future.delayed(const Duration(milliseconds: 500), () {
                                          try {
                                            _ttsService.speak('Text to speech enabled');
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('TTS Error: Please restart the app for TTS to work')),
                                              );
                                            }
                                          }
                                        });
                                      } else {
                                        try {
                                          _ttsService.stop();
                                        } catch (e) {
                                          // Ignore stop errors
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    //
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Semantics(
                              label: 'Font Size icon',
                              child: Icon(Icons.text_fields, color: theme.colorScheme.primary),
                            ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      'Font Size',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Semantics(
                                    label: 'Current font size is ${(accessibility.fontScale * 100).toStringAsFixed(0)} percent',
                                    child: Text(
                                      'Adjust text size: ${(accessibility.fontScale * 100).toStringAsFixed(0)}%',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                        Semantics(
                          label: 'Font size slider',
                          value: '${(accessibility.fontScale * 100).toStringAsFixed(0)} percent',
                          child: Slider(
                            value: accessibility.fontScale.clamp(0.8, 1.5),
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: '${(accessibility.fontScale.clamp(0.8, 1.5) * 100).toStringAsFixed(0)}%',
                            onChanged: (value) {
                              accessibility.setFontScale(value);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Semantics(
                              label: 'Small font size',
                              child: Text('Small', style: theme.textTheme.bodySmall),
                            ),
                            Semantics(
                              label: 'Reset font size to normal',
                              button: true,
                              child: TextButton(
                                onPressed: () {
                                  accessibility.setFontScale(1.0);
                                },
                                child: Text('Reset', style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                )),
                              ),
                            ),
                            Semantics(
                              label: 'Large font size',
                              child: Text('Large', style: theme.textTheme.bodySmall),
                            ),
                          ],
                        ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Test TTS Button
                    if (_localTtsEnabled ?? accessibility.ttsEnabled)
                      Semantics(
                        label: 'Test Text-to-Speech button',
                        button: true,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _ttsService.speak(
                                  'This is a test of the text to speech feature. '
                                  'If you can hear this, the feature is working correctly.',
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('TTS Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Test Text-to-Speech'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

