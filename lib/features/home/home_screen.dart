import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/services/pdf_service.dart';
import 'package:pocket_prof/services/llm_service.dart';
import 'package:pocket_prof/providers/settings_provider.dart';
import 'package:pocket_prof/providers/chat_provider.dart';

/// Home screen - Input Layer
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String _loadingMessage = '';
  String _selectedMode = 'explain';
  
  final List<String> _loadingMessages = [
    'Hocanız notları inceliyor...',
    'Ders hazırlanıyor...',
    'Konuyu analiz ediyorum...',
  ];
  
  @override
  void dispose() {
    // Unfocus any active text fields to prevent DOM element errors
    FocusScope.of(context).unfocus();
    _textController.dispose();
    super.dispose();
  }
  
  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          await _processPDF(bytes);
        }
      }
    } catch (e) {
      _showError('PDF seçilirken hata oluştu: $e');
    }
  }
  
  Future<void> _processPDF(Uint8List bytes) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });
    
    try {
      final pdfService = PDFService();
      final text = await pdfService.extractTextFromBytes(bytes);
      
      if (text.isNotEmpty) {
        _navigateToChat(text);
      } else {
        _showError('PDF\'den metin çıkarılamadı.');
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        // For now, show a message that OCR is not yet implemented
        _showError('Görsel tanıma yakında eklenecek. Şimdilik PDF veya metin kullanabilirsiniz.');
      }
    } catch (e) {
      _showError('Resim seçilirken hata oluştu: $e');
    }
  }
  
  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Lütfen bir metin girin.');
      return;
    }
    _navigateToChat(text);
  }
  
  void _navigateToChat(String text) {
    context.go('/chat', extra: {
      'text': text,
      'mode': _selectedMode,
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      appBar: AppBar(
        leading: isWide ? null : Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            const Text('PocketProf'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: 'Ayarlar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(),
      body: _isLoading
          ? _buildLoadingState()
          : isWide
            ? Row(
                children: [
                  // Left Sidebar
                  _buildSidebar(),
                  // Divider
                  Container(width: 1, color: Theme.of(context).dividerColor),
                  // Main Content
                  Expanded(child: _buildMainContent(settings)),
                ],
              )
            : _buildMainContent(settings),
    );
  }
  
  Widget _buildDrawer() {
    final chatState = ref.watch(chatProvider);
    final recentSessions = chatState.recentSessions;
    
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('PocketProf', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            // New Chat Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).clearMessages();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Sohbet'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            // Chat History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sohbetler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: recentSessions.isEmpty
                ? Center(
                    child: Text(
                      'Henüz sohbet yok',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: recentSessions.length,
                    itemBuilder: (context, index) {
                      final session = recentSessions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.chat_bubble_outline, size: 18),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _confirmDelete(session),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () {
                          ref.read(chatProvider.notifier).loadSession(session.id);
                          Navigator.pop(context);
                          context.go('/chat', extra: {'text': '', 'mode': session.mode});
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebar() {
    final chatState = ref.watch(chatProvider);
    final recentSessions = chatState.recentSessions;
    
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => ref.read(chatProvider.notifier).clearMessages(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Sohbet'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
          // Chat History Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Sohbetler',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: recentSessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Henüz sohbet yok.\nYeni bir konu ile başlayın!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: recentSessions.length,
                  itemBuilder: (context, index) {
                    final session = recentSessions[index];
                    return _buildSidebarChatItem(session);
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSidebarChatItem(ChatSession session) {
    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).loadSession(session.id);
        context.go('/chat', extra: {'text': '', 'mode': session.mode});
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: () => _confirmDelete(session),
              color: Theme.of(context).textTheme.bodySmall?.color,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainContent(SettingsState settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(settings),
              const SizedBox(height: 40),
              _buildModeSelector(),
              const SizedBox(height: 32),
              _buildWideInputOptions(),
              const SizedBox(height: 32),
              _buildTextInput(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(SettingsState settings) {
    return Column(
      children: [
        Text(
          'Merhaba! 👋',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Öğrenmek istediğin materyali yükle,\nsenin için anlatayım.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
        if (!settings.hasOpenRouterKey) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Başlamak için Ayarlar\'dan API anahtarı girin',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ne yapmamı istersin?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LLMService.modes.entries.map((entry) {
            final isSelected = _selectedMode == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMode = entry.key);
                }
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Theme.of(context).dividerColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildWideInputOptions() {
    return Row(
      children: [
        Expanded(child: _buildInputCard(
          icon: Icons.picture_as_pdf,
          title: 'PDF Yükle',
          subtitle: 'Ders notlarını yükle',
          onTap: _pickPDF,
          color: Colors.red.shade400,
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildInputCard(
          icon: Icons.image,
          title: 'Fotoğraf Yükle',
          subtitle: 'Kitap sayfası çek',
          onTap: _pickImage,
          color: Colors.blue.shade400,
        )),
      ],
    );
  }
  
  Widget _buildNarrowInputOptions() {
    return Column(
      children: [
        _buildInputCard(
          icon: Icons.picture_as_pdf,
          title: 'PDF Yükle',
          subtitle: 'Ders notlarını yükle',
          onTap: _pickPDF,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 12),
        _buildInputCard(
          icon: Icons.image,
          title: 'Fotoğraf Yükle',
          subtitle: 'Kitap sayfası çek',
          onTap: _pickImage,
          color: Colors.blue.shade400,
        ),
      ],
    );
  }
  
  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(width: 12),
            Text(
              'veya metin yapıştır',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(height: 1, color: Theme.of(context).dividerColor),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _textController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Öğrenmek istediğin konuyu buraya yapıştır...',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitText,
            icon: const Icon(Icons.send),
            label: const Text('Hocaya Gönder'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentChats() {
    final chatState = ref.watch(chatProvider);
    final recentSessions = chatState.recentSessions;
    
    if (recentSessions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Sohbetler',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Chat list - Gemini style
        ...recentSessions.take(10).map((session) => _buildChatItem(session)),
      ],
    );
  }
  
  Widget _buildChatItem(ChatSession session) {
    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).loadSession(session.id);
        context.go('/chat', extra: {'text': '', 'mode': session.mode});
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Chat icon
            Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(session),
              color: Theme.of(context).textTheme.bodySmall?.color,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: const Text('Bu sohbet silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).deleteSession(session.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${date.day}.${date.month}.${date.year}';
  }
}

