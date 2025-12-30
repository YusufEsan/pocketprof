import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/providers/settings_provider.dart';

/// Settings screen - API key configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _openRouterController = TextEditingController();
  final _elevenLabsController = TextEditingController();
  bool _openRouterObscured = true;
  bool _elevenLabsObscured = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _openRouterController.text = settings.openRouterApiKey ?? '';
    _elevenLabsController.text = settings.elevenLabsApiKey ?? '';
  }

  @override
  void dispose() {
    // Unfocus any active text fields to prevent DOM element errors
    FocusScope.of(context).unfocus();
    _openRouterController.dispose();
    _elevenLabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Ayarlar'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 120 : 20,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'API Anahtarları',
              subtitle:
                  'Yapay zeka ve ses servisleri için API anahtarlarınızı girin',
              children: [
                _buildApiKeyField(
                  label: 'OpenRouter API Key',
                  hint: 'sk-or-...',
                  controller: _openRouterController,
                  obscured: _openRouterObscured,
                  onToggle: () => setState(
                    () => _openRouterObscured = !_openRouterObscured,
                  ),
                  onSave: (v) => ref
                      .read(settingsProvider.notifier)
                      .setOpenRouterApiKey(v),
                  helpUrl: 'https://openrouter.ai/keys',
                ),
                const SizedBox(height: 16),
                _buildApiKeyField(
                  label: 'ElevenLabs API Key (Opsiyonel)',
                  hint: 'xi-...',
                  controller: _elevenLabsController,
                  obscured: _elevenLabsObscured,
                  onToggle: () => setState(
                    () => _elevenLabsObscured = !_elevenLabsObscured,
                  ),
                  onSave: (v) => ref
                      .read(settingsProvider.notifier)
                      .setElevenLabsApiKey(v),
                  helpUrl: 'https://elevenlabs.io/api',
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Ses Ayarları',
              subtitle: 'Metin okuma ayarlarını yapılandırın',
              children: [
                SwitchListTile(
                  title: const Text('Sesli Okuma'),
                  subtitle: Text(
                    settings.hasElevenLabsKey
                        ? 'ElevenLabs (Premium ses)'
                        : 'Tarayıcı sesi kullanılıyor',
                  ),
                  value: settings.ttsEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setTtsEnabled(v),
                  activeColor: AppTheme.primary,
                ),
                if (settings.hasElevenLabsKey) ...[
                  const Divider(),
                  _buildVoiceSelector(settings),
                ],
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Hakkında',
              subtitle: 'PocketProf v1.0.0',
              children: [const Text('AI destekli kişisel eğitmen uygulaması.')],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscured,
    required VoidCallback onToggle,
    required Function(String) onSave,
    required String helpUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton(onPressed: () => context.go('/help'), child: const Text('Nasıl alınır?')),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscured,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    obscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: onToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    onSave(controller.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kaydedildi!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector(SettingsState settings) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(audioTeacherServiceProvider).getElevenLabsVoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final voices = snapshot.data ?? [];
        if (voices.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ses listesi alınamadı. API anahtarınızı kontrol edin.',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Ses Modeli Seçin',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: voices.length,
              itemBuilder: (context, index) {
                final voice = voices[index];
                final isSelected = settings.selectedVoice == voice['id'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? AppTheme.primary
                        : Colors.grey[200],
                    child: Icon(
                      isSelected ? Icons.check : Icons.record_voice_over,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(voice['name'] ?? 'İsimsiz Ses'),
                  subtitle: Text(voice['category'] ?? 'Genel'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    tooltip: 'Dinle',
                    onPressed: () {
                      ref
                          .read(audioTeacherServiceProvider)
                          .previewVoice(
                            voice['id'],
                            'Selam! Ben PocketProf. Bugün hangi konuyu öğrenmek istersin?',
                          );
                    },
                  ),
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setSelectedVoice(voice['id']);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
