import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:web/web.dart' as web;

/// Help/Info screen - API key instructions
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _launchUrl(String url) {
    web.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Yardım & Bilgi'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 120 : 20,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PocketProf Nasıl Kullanılır?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API anahtarlarını ayarlayarak başlayın',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // API Sections - Side by side on desktop, stacked on mobile
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OpenRouter Section
                  Expanded(
                    child: _buildApiSection(
                      context,
                      icon: Icons.auto_awesome,
                      iconColor: Colors.purple,
                      title: 'OpenRouter API Key',
                      subtitle: 'Yapay zeka motoru için gerekli',
                      isRequired: true,
                      steps: [
                        _StepInfo(
                          number: '1',
                          title: 'Hesap Oluşturun',
                          description: 'openrouter.ai adresine gidin ve ücretsiz hesap oluşturun.',
                        ),
                        _StepInfo(
                          number: '2',
                          title: 'API Key Alın',
                          description: 'Dashboard > Keys bölümünden "Create Key" butonuna tıklayın.',
                        ),
                        _StepInfo(
                          number: '3',
                          title: 'Ayarlara Ekleyin',
                          description: 'Anahtarı Ayarlar > OpenRouter API Key alanına yapıştırın.',
                        ),
                      ],
                      highlights: [
                        _HighlightInfo(
                          icon: Icons.monetization_on,
                          color: Colors.green,
                          title: 'İlk \$1 Ücretsiz!',
                          description: 'Yeni hesaplara 1 dolarlık ücretsiz kredi verilir.',
                        ),
                        _HighlightInfo(
                          icon: Icons.security,
                          color: Colors.orange,
                          title: 'Anahtarınızı Saklayın',
                          description: 'API anahtarınızı kimseyle paylaşmayın.',
                        ),
                        _HighlightInfo(
                          icon: Icons.credit_card_off,
                          color: Colors.blue,
                          title: 'Kredi Kartı Gerekmez',
                          description: 'Ücretsiz kredi için ödeme bilgisi gerekmez.',
                        ),
                      ],
                      buttonText: 'OpenRouter\'a Git',
                      buttonUrl: 'https://openrouter.ai/keys',
                    ),
                  ),
                  const SizedBox(width: 24),
                  // ElevenLabs Section
                  Expanded(
                    child: _buildApiSection(
                      context,
                      icon: Icons.record_voice_over,
                      iconColor: Colors.teal,
                      title: 'ElevenLabs API Key',
                      subtitle: 'Premium sesli okuma için (opsiyonel)',
                      isRequired: false,
                      steps: [
                        _StepInfo(
                          number: '1',
                          title: 'Hesap Oluşturun',
                          description: 'elevenlabs.io adresine gidin ve ücretsiz hesap oluşturun.',
                        ),
                        _StepInfo(
                          number: '2',
                          title: 'API Key Alın',
                          description: 'Profile > API Keys bölümünden anahtarınızı alın.',
                        ),
                        _StepInfo(
                          number: '3',
                          title: 'Ayarlara Ekleyin',
                          description: 'Anahtarı Ayarlar > ElevenLabs API Key alanına yapıştırın.',
                        ),
                      ],
                      highlights: [
                        _HighlightInfo(
                          icon: Icons.volunteer_activism,
                          color: Colors.green,
                          title: 'Ücretsiz Plan Mevcut!',
                          description: 'Her ay 10.000 karakter ücretsiz ses üretimi.',
                        ),
                        _HighlightInfo(
                          icon: Icons.speaker_notes,
                          color: Colors.purple,
                          title: 'Tarayıcı Sesi Alternatif',
                          description: 'ElevenLabs olmadan da tarayıcı sesi kullanılır.',
                        ),
                        _HighlightInfo(
                          icon: Icons.security,
                          color: Colors.orange,
                          title: 'Güvenli Saklama',
                          description: 'Anahtarınız sadece tarayıcınızda saklanır.',
                        ),
                      ],
                      buttonText: 'ElevenLabs\'a Git',
                      buttonUrl: 'https://elevenlabs.io/api',
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // OpenRouter Section
                  _buildApiSection(
                    context,
                    icon: Icons.auto_awesome,
                    iconColor: Colors.purple,
                    title: 'OpenRouter API Key',
                    subtitle: 'Yapay zeka motoru için gerekli',
                    isRequired: true,
                    steps: [
                      _StepInfo(
                        number: '1',
                        title: 'Hesap Oluşturun',
                        description: 'openrouter.ai adresine gidin ve ücretsiz hesap oluşturun.',
                      ),
                      _StepInfo(
                        number: '2',
                        title: 'API Key Alın',
                        description: 'Dashboard > Keys bölümünden "Create Key" butonuna tıklayın.',
                      ),
                      _StepInfo(
                        number: '3',
                        title: 'Kopyalayın',
                        description: 'Oluşturulan anahtarı kopyalayıp Ayarlar ekranına yapıştırın.',
                      ),
                    ],
                    highlights: [
                      _HighlightInfo(
                        icon: Icons.monetization_on,
                        color: Colors.green,
                        title: 'İlk \$1 Ücretsiz!',
                        description: 'Yeni hesaplara 1 dolarlık ücretsiz kredi verilir. Bu, yüzlerce mesaj için yeterli!',
                      ),
                      _HighlightInfo(
                        icon: Icons.security,
                        color: Colors.orange,
                        title: 'Anahtarınızı Saklayın',
                        description: 'API anahtarınızı kimseyle paylaşmayın. Sadece sizin cihazınızda saklanır.',
                      ),
                      _HighlightInfo(
                        icon: Icons.credit_card_off,
                        color: Colors.blue,
                        title: 'Kredi Kartı Gerekmez',
                        description: 'Ücretsiz kredi için ödeme bilgisi girmeniz gerekmez.',
                      ),
                    ],
                    buttonText: 'OpenRouter\'a Git',
                    buttonUrl: 'https://openrouter.ai/keys',
                  ),
                  const SizedBox(height: 24),
                  // ElevenLabs Section
                  _buildApiSection(
                    context,
                    icon: Icons.record_voice_over,
                    iconColor: Colors.teal,
                    title: 'ElevenLabs API Key',
                    subtitle: 'Premium sesli okuma için (opsiyonel)',
                    isRequired: false,
                    steps: [
                      _StepInfo(
                        number: '1',
                        title: 'Hesap Oluşturun',
                        description: 'elevenlabs.io adresine gidin ve ücretsiz hesap oluşturun.',
                      ),
                      _StepInfo(
                        number: '2',
                        title: 'API Key Alın',
                        description: 'Profile > API Keys bölümünden anahtarınızı alın.',
                      ),
                      _StepInfo(
                        number: '3',
                        title: 'Ayarlara Ekleyin',
                        description: 'Anahtarı kopyalayıp Ayarlar > ElevenLabs API Key alanına yapıştırın.',
                      ),
                    ],
                    highlights: [
                      _HighlightInfo(
                        icon: Icons.volunteer_activism,
                        color: Colors.green,
                        title: 'Ücretsiz Plan Mevcut!',
                        description: 'Her ay 10.000 karakter ücretsiz ses üretimi. Başlangıç için yeterli!',
                      ),
                      _HighlightInfo(
                        icon: Icons.speaker_notes,
                        color: Colors.purple,
                        title: 'Tarayıcı Sesi Alternatif',
                        description: 'ElevenLabs olmadan da tarayıcının yerleşik sesi kullanılır.',
                      ),
                      _HighlightInfo(
                        icon: Icons.security,
                        color: Colors.orange,
                        title: 'Güvenli Saklama',
                        description: 'Anahtarınız sadece sizin tarayıcınızda şifreli olarak saklanır.',
                      ),
                    ],
                    buttonText: 'ElevenLabs\'a Git',
                    buttonUrl: 'https://elevenlabs.io/api',
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Tips Section
            _buildTipsSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isRequired,
    required List<_StepInfo> steps,
    required List<_HighlightInfo> highlights,
    required String buttonText,
    required String buttonUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRequired ? Colors.red : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isRequired ? 'Zorunlu' : 'Opsiyonel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Steps
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nasıl Alınır?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            step.number,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Highlights
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: highlights.map((highlight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(highlight.icon, color: highlight.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            highlight.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: highlight.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            highlight.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(buttonUrl),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'İpuçları',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            context,
            '💡',
            'Ücretsiz kredi bittikten sonra OpenRouter\'a bakiye ekleyebilirsiniz. Fiyatlar çok uygun!',
          ),
          _buildTipItem(
            context,
            '🔒',
            'API anahtarlarınız sadece sizin tarayıcınızda saklanır, hiçbir sunucuya gönderilmez.',
          ),
          _buildTipItem(
            context,
            '🎯',
            'ElevenLabs opsiyoneldir. Olmadan da tarayıcının yerleşik sesi ile metinler okunabilir.',
          ),
          _buildTipItem(
            context,
            '📱',
            'Ayarlar ekranından istediğiniz zaman API anahtarlarınızı güncelleyebilirsiniz.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final String number;
  final String title;
  final String description;

  _StepInfo({
    required this.number,
    required this.title,
    required this.description,
  });
}

class _HighlightInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  _HighlightInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
