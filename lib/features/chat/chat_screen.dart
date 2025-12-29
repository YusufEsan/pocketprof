import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/providers/chat_provider.dart';
import 'package:pocket_prof/providers/audio_provider.dart';
import 'package:pocket_prof/providers/settings_provider.dart';
import 'package:pocket_prof/features/chat/widgets/message_bubble.dart';
import 'package:pocket_prof/features/chat/widgets/audio_player_bar.dart';
import 'package:pocket_prof/services/llm_service.dart';
import 'package:pocket_prof/services/pdf_service.dart';
import 'package:pocket_prof/services/export_service.dart';
import 'package:pocket_prof/services/ocr_service.dart';

/// Chat screen - Output Layer with modern design
class ChatScreen extends ConsumerStatefulWidget {
  final String initialText;
  final String mode;

  const ChatScreen({super.key, this.initialText = '', this.mode = 'explain'});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInitialized = false;

  // Pending attachments (multiple) - now stores file data for deferred processing
  // Each item: {'name': String, 'bytes': Uint8List?, 'type': 'pdf'|'image', 'content': String?}
  final List<Map<String, dynamic>> _pendingAttachments = [];
  bool _isProcessingFile = false;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  // Question/Card count for quiz and flashcard modes
  int _selectedQuestionCount = 5;

  bool _showScrollToTop = false;
  bool _showScrollToBottom = false;

  // Sidebar search
  String _sidebarSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialText.isNotEmpty && !_hasInitialized) {
        _hasInitialized = true;
        ref
            .read(chatProvider.notifier)
            .sendInitialContent(widget.initialText, widget.mode);
      }
    });

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideIn = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    // Unfocus any active text fields to prevent DOM element errors
    FocusScope.of(context).unfocus();
    _inputController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    final showBottom = offset > 500;
    // Show "Scroll to Top" (Oldest) if we are far from maxScroll
    final showTop = offset < maxScroll - 500;

    if (showBottom != _showScrollToBottom || showTop != _showScrollToTop) {
      setState(() {
        _showScrollToBottom = showBottom;
        _showScrollToTop = showTop;

        // Don't show if list is short
        if (maxScroll < 1000) {
          _showScrollToTop = false;
          _showScrollToBottom = false;
        }
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottom() {
    // With reverse: true, the bottom of the chat is at offset 0
    // So to scroll to bottom, we animate to 0.0
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Go to bottom (latest message)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showDeleteConfirmation(String sessionId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppTheme.error,
            size: 28,
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Sohbeti Sil?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '"$title"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                'Bu sohbet kalıcı olarak silinecek.\nBu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
          top: 16,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(130, 46),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('İptal'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              ref.read(chatProvider.notifier).deleteSession(sessionId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Sohbet silindi'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(130, 46),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportChats() async {
    try {
      final data = ref.read(chatProvider.notifier).exportAllSessions();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Use web download
      final bytes = utf8.encode(jsonString);
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      (web.document.createElement('a') as web.HTMLAnchorElement)
        ..href = url
        ..download =
            'pocketprof_backup_${DateTime.now().millisecondsSinceEpoch}.json'
        ..click();
      web.URL.revokeObjectURL(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${data['chats']?.length ?? 0} sohbet dışa aktarıldı',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _importChats() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        throw Exception('Dosya okunamadı');
      }

      final jsonString = utf8.decode(bytes);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final count = await ref.read(chatProvider.notifier).importSessions(data);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$count sohbet içe aktarıldı')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İçe aktarma hatası: $e')));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    // Process attachments if any have unextracted content
    String? combinedName;
    String? combinedContent;

    if (_pendingAttachments.isNotEmpty) {
      setState(() {
        _isProcessingFile = true;
      });

      try {
        final processedContents = <String>[];
        final names = <String>[];

        for (final attachment in _pendingAttachments) {
          final name = attachment['name'] as String;
          names.add(name);

          // Check if content already extracted
          if (attachment['content'] != null) {
            processedContents.add('--- $name ---\n${attachment['content']}');
            continue;
          }

          // Extract content based on type
          final bytes = attachment['bytes'] as Uint8List?;
          final type = attachment['type'] as String;

          if (bytes == null) continue;

          if (type == 'pdf') {
            final pdfService = PDFService();
            final extractedText = await pdfService.extractTextFromBytes(bytes);
            if (extractedText.isNotEmpty) {
              processedContents.add('--- $name ---\n$extractedText');
            }
          } else if (type == 'image') {
            final settings = ref.read(settingsProvider);
            if (settings.openRouterApiKey != null) {
              final ocrService = OCRService(apiKey: settings.openRouterApiKey!);
              final extractedText = await ocrService.extractText(bytes);
              if (extractedText.isNotEmpty) {
                processedContents.add('--- $name ---\n$extractedText');
              }
            }
          }
        }

        if (names.isNotEmpty) {
          combinedName = names.join(', ');
        }
        if (processedContents.isNotEmpty) {
          combinedContent = processedContents.join('\n\n');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dosya işleme hatası: $e')),
          );
        }
        setState(() {
          _isProcessingFile = false;
        });
        return;
      }

      setState(() {
        _isProcessingFile = false;
      });
    }

    final currentState = ref.read(chatProvider);
    ref
        .read(chatProvider.notifier)
        .sendMessage(
          text.isEmpty ? 'Bu dosyaları analiz et' : text,
          attachmentName: combinedName,
          attachmentContent: combinedContent,
          questionCount:
              (currentState.currentMode == 'quiz' ||
                  currentState.currentMode == 'flashcard')
              ? _selectedQuestionCount
              : null,
        );

    _inputController.clear();
    setState(() {
      _pendingAttachments.clear();
    });
    _scrollToBottom();
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: true, // Allow multiple PDF selection
      );

      if (result != null && result.files.isNotEmpty) {
        int addedCount = 0;

        for (final file in result.files) {
          if (file.bytes != null) {
            setState(() {
              _pendingAttachments.add({
                'name': file.name,
                'bytes': file.bytes,
                'type': 'pdf',
                'content': null, // Will be extracted on send
              });
            });
            addedCount++;
          }
        }

        if (mounted && addedCount > 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$addedCount PDF eklendi')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _clearAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  void _clearAllAttachments() {
    setState(() {
      _pendingAttachments.clear();
    });
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Check file size
          final settings = ref.read(settingsProvider);
          if (settings.openRouterApiKey == null ||
              settings.openRouterApiKey!.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lütfen önce API key ayarlayın'),
                ),
              );
            }
            return;
          }

          final ocrService = OCRService(apiKey: settings.openRouterApiKey!);
          if (!ocrService.isValidImageSize(file.bytes!)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dosya çok büyük (max 10MB)')),
              );
            }
            return;
          }

          setState(() {
            _pendingAttachments.add({
              'name': '📷 ${file.name}',
              'bytes': file.bytes,
              'type': 'image',
              'content': null, // Will be extracted on send
            });
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Görsel eklendi')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _handleExport(String type, ChatState chatState) {
    final exportService = ExportService();
    final title = chatState.messages.isNotEmpty
        ? chatState.messages.first.content
              .split('\n')
              .first
              .substring(
                0,
                chatState.messages.first.content.split('\n').first.length > 50
                    ? 50
                    : chatState.messages.first.content.split('\n').first.length,
              )
        : 'PocketProf Sohbet';

    if (type == 'markdown') {
      exportService.exportToMarkdown(
        messages: chatState.messages,
        title: title,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Markdown indiriliyor...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final settings = ref.watch(settingsProvider);

    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: isWide
                ? null
                : Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
            title: Consumer(
              builder: (context, ref, child) {
                final mode = ref.watch(
                  chatProvider.select((s) => s.currentMode),
                );
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PocketProf',
                          style: TextStyle(fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LLMService.modes[mode] ?? 'Konu Anlatımı',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              // Export menu
              Consumer(
                builder: (context, ref, child) {
                  final hasMessages = ref.watch(
                    chatProvider.select((s) => s.messages.isNotEmpty),
                  );
                  if (!hasMessages) return const SizedBox.shrink();

                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Dışa Aktar',
                    onSelected: (value) {
                      final chatState = ref.read(chatProvider);
                      _handleExport(value, chatState);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'markdown',
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Markdown olarak indir'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Help button
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => context.go('/help'),
                tooltip: 'Yardım',
              ),
              // Home button
              IconButton(
                icon: const Icon(Icons.home_outlined),
                onPressed: () {
                  ref.read(audioPlayerProvider.notifier).stop();
                  context.go('/');
                },
                tooltip: 'Ana Sayfa',
              ),
              // Settings button
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
                tooltip: 'Ayarlar',
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: isWide
              ? null
              : Consumer(
                  builder: (context, ref, child) =>
                      _buildDrawer(ref.watch(chatProvider)),
                ),
          body: isWide
              ? Row(
                  children: [
                    Consumer(
                      builder: (context, ref, child) =>
                          _buildSidebar(ref.watch(chatProvider)),
                    ),
                    Container(width: 1, color: AppTheme.divider),
                    Expanded(
                      child: Stack(
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final chatState = ref.watch(chatProvider);
                              final audioState = ref.watch(audioPlayerProvider);
                              return _buildChatArea(
                                chatState,
                                audioState,
                                settings,
                              );
                            },
                          ),
                          _buildScrollButtons(),
                        ],
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final chatState = ref.watch(chatProvider);
                        final audioState = ref.watch(audioPlayerProvider);
                        return _buildChatArea(chatState, audioState, settings);
                      },
                    ),
                    _buildScrollButtons(),
                  ],
                ),
        ),
        if (_isProcessingFile)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Dosya İşleniyor...',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lütfen bekleyin, metin çıkarılıyor.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer(ChatState chatState) {
    final recentSessions = chatState.recentSessions;
    final filteredSessions = _sidebarSearchQuery.isEmpty
        ? recentSessions
        : recentSessions
            .where((s) => s.title.toLowerCase().contains(
                  _sidebarSearchQuery.toLowerCase(),
                ))
            .toList();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).clearMessages();
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Sohbet'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Sohbet ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _sidebarSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _sidebarSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _sidebarSearchQuery = value;
                  });
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sohbetler',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _sidebarSearchQuery.isEmpty
                              ? 'Henüz sohbet yok'
                              : 'Sonuç bulunamadı',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final isActive =
                            chatState.currentSessionId == session.id;
                  return ListTile(
                    dense: true,
                    selected: isActive,
                    selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                    leading: const Icon(Icons.chat_bubble_outline, size: 18),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _showDeleteConfirmation(
                        session.id,
                        session.title,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onTap: () {
                      ref.read(chatProvider.notifier).loadSession(session.id);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
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

  Widget _buildSidebar(ChatState chatState) {
    final recentSessions = chatState.recentSessions;
    final filteredSessions = _sidebarSearchQuery.isEmpty
        ? recentSessions
        : recentSessions
            .where((s) => s.title.toLowerCase().contains(
                  _sidebarSearchQuery.toLowerCase(),
                ))
            .toList();

    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
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
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Sohbet ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _sidebarSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _sidebarSearchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _sidebarSearchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sohbetler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredSessions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _sidebarSearchQuery.isEmpty
                            ? 'Henüz sohbet yok.\nYeni bir konu ile başlayın!'
                            : 'Sonuç bulunamadı',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      final isActive =
                          chatState.currentSessionId == session.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: isActive
                          ? AppTheme.primary
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? AppTheme.primary : null,
                        fontWeight: isActive ? FontWeight.w500 : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(session.id, session.title),
                      tooltip: 'Sohbeti Sil',
                    ),
                    onTap: () =>
                        ref.read(chatProvider.notifier).loadSession(session.id),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _exportChats,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Dışa Aktar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _importChats,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('İçe Aktar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(
    ChatState chatState,
    AudioPlayerState audioState,
    SettingsState settings,
  ) {
    return Column(
      children: [
        // Error banner
        if (chatState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chatState.error!,
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ),

        // Messages
        Expanded(
          child: chatState.messages.isEmpty
              ? _buildWelcomeState(chatState)
              : ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  // Cache more pixels for smoother scrolling
                  cacheExtent: 1000.0,
                  // Improve performance by keeping state
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  itemCount:
                      chatState.messages.length + (chatState.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (chatState.isLoading) {
                      if (index == 0) return _buildLoadingIndicator();
                      final message =
                          chatState.messages[chatState.messages.length - index];
                      final messageIndex = chatState.messages.length - index;
                      // Use RepaintBoundary to isolate message paints
                      return RepaintBoundary(
                        key: ValueKey('loading-${message.id}'),
                        child: MessageBubble(
                          message: message,
                          index: messageIndex,
                          isStreaming: true,
                          onSpeak: !message.isUser && settings.ttsEnabled
                              ? () => ref
                                    .read(audioPlayerProvider.notifier)
                                    .speak(message.content)
                              : null,
                        ),
                      );
                    }

                    final messageIndex = chatState.messages.length - 1 - index;
                    final message = chatState.messages[messageIndex];
                    return RepaintBoundary(
                      key: ValueKey(message.id),
                      child: MessageBubble(
                        message: message,
                        index: messageIndex,
                        isStreaming: false,
                        shouldAnimate:
                            index ==
                            0, // Only animate if it's the latest message
                        onSpeak: !message.isUser && settings.ttsEnabled
                            ? () => ref
                                  .read(audioPlayerProvider.notifier)
                                  .speak(message.content)
                            : null,
                      ),
                    );
                  },
                ),
        ),

        // Audio bar
        if (audioState.hasText && settings.ttsEnabled) const AudioPlayerBar(),

        // Input area
        _buildInputArea(chatState),
      ],
    );
  }

  /// Build FABs for scrolling with entrance animations
  Widget _buildScrollButtons() {
    return Positioned(
      right: 20,
      bottom: 120, // Above input area
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Chat Start" button (Go to Oldest)
          AnimatedScale(
            scale: _showScrollToTop ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _showScrollToTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: AppTheme.primary,
                  heroTag: 'scrollTop',
                  tooltip: 'Sohbetin Başına Git',
                  child: const Icon(Icons.arrow_upward, size: 20),
                ),
              ),
            ),
          ),

          // "Chat End" button (Go to Latest)
          AnimatedScale(
            scale: _showScrollToBottom ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _showScrollToBottom ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                heroTag: 'scrollBottom',
                tooltip: 'Sohbetin Sonuna Git',
                child: const Icon(Icons.arrow_downward, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState(ChatState chatState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated welcome
            RepaintBoundary(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: Column(
                    children: [
                      Text(
                        'Merhaba! 👋',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ne yapmamı istersin?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Mode-specific action buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildModeButton(
                  icon: Icons.school,
                  label: 'Konu Anlat',
                  mode: 'explain',
                  isActive: chatState.currentMode == 'explain',
                ),
                _buildModeButton(
                  icon: Icons.summarize,
                  label: 'Özet Çıkar',
                  mode: 'summary',
                  isActive: chatState.currentMode == 'summary',
                ),
                _buildModeButtonWithCount(
                  icon: Icons.quiz,
                  label: 'Sınav Sorusu',
                  mode: 'quiz',
                  isActive: chatState.currentMode == 'quiz',
                ),
                _buildModeButtonWithCount(
                  icon: Icons.style,
                  label: 'Hatırlatma Kartı',
                  mode: 'flashcard',
                  isActive: chatState.currentMode == 'flashcard',
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Quick start hint
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PDF yükleyebilir veya metin yazabilirsin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required String mode,
    required bool isActive,
  }) {
    return Material(
      color: isActive ? AppTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => ref.read(chatProvider.notifier).setMode(mode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary
                  : Theme.of(context).dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButtonWithCount({
    required IconData icon,
    required String label,
    required String mode,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primary : Theme.of(context).dividerColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ref.read(chatProvider.notifier).setMode(mode),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isActive ? Colors.white : AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: isActive ? Colors.white30 : Theme.of(context).dividerColor,
          ),
          Theme(
            data: Theme.of(context).copyWith(canvasColor: Colors.white),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedQuestionCount,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                selectedItemBuilder: (context) {
                  return List.generate(20, (index) => index + 1).map((count) {
                    return Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: List.generate(20, (index) => index + 1)
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isActive && _selectedQuestionCount == count
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: _selectedQuestionCount == count
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedQuestionCount = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _inputController.text = text;
        _sendMessage();
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).dividerColor),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Düşünüyorum...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pending attachments indicator
            if (_pendingAttachments.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pendingAttachments.length,
                  padding: const EdgeInsets.only(bottom: 8),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final attachment = _pendingAttachments[index];
                    final isImage =
                        attachment['name']?.startsWith('📷') ?? false;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isImage ? Icons.image : Icons.picture_as_pdf,
                            color: isImage ? Colors.blue : AppTheme.error,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              attachment['name'] ?? 'Dosya',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () => _clearAttachment(index),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Input row
            Row(
              children: [
                // Text input
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: _pendingAttachments.isNotEmpty
                          ? '${_pendingAttachments.length} dosya eklendi...'
                          : 'Bir soru sor...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.background,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !chatState.isLoading,
                  ),
                ),
                const SizedBox(width: 6),

                // PDF button
                _buildPdfButton(chatState),

                const SizedBox(width: 6),

                // Mode selector button
                _buildModeSelector(chatState),

                // Question/Card count selector in input area
                if (chatState.currentMode == 'quiz' ||
                    chatState.currentMode == 'flashcard') ...[
                  const SizedBox(width: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedQuestionCount,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        borderRadius: BorderRadius.circular(16),
                        items: List.generate(20, (index) => index + 1)
                            .map(
                              (count) => DropdownMenuItem(
                                value: count,
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedQuestionCount = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 6),

                // Send button
                InkWell(
                  onTap: chatState.isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: chatState.isLoading
                          ? null
                          : LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                      color: chatState.isLoading ? AppTheme.divider : null,
                      shape: BoxShape.circle,
                      boxShadow: chatState.isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: const Center(
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfButton(ChatState chatState) {
    final hasAttachment = _pendingAttachments.isNotEmpty;
    return PopupMenuButton<String>(
      enabled: !chatState.isLoading,
      onSelected: (value) {
        if (value == 'pdf') {
          _pickPDF();
        } else if (value == 'image') {
          _pickImage();
        }
      },
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasAttachment
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasAttachment
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Icon(
          Icons.attach_file,
          size: 20,
          color: hasAttachment
              ? AppTheme.primary
              : Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 12),
              Text('PDF Yükle'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'image',
          child: Row(
            children: [
              Icon(Icons.image, color: Colors.blue),
              SizedBox(width: 12),
              Text('Fotoğraf Yükle (OCR)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ChatState chatState) {
    final modeIcons = {
      'explain': Icons.school,
      'summary': Icons.summarize,
      'quiz': Icons.quiz,
      'flashcard': Icons.style,
    };

    return PopupMenuButton<String>(
      onSelected: (mode) => ref.read(chatProvider.notifier).setMode(mode),
      offset: const Offset(0, -200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              modeIcons[chatState.currentMode] ?? Icons.school,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _getModeShortName(chatState.currentMode),
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
      itemBuilder: (context) => LLMService.modes.entries.map((entry) {
        final isSelected = chatState.currentMode == entry.key;
        return PopupMenuItem(
          value: entry.key,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    modeIcons[entry.key] ?? Icons.school,
                    size: 18,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _getModeDescription(entry.key),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: AppTheme.primary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getModeShortName(String mode) {
    return switch (mode) {
      'explain' => 'Anlat',
      'summary' => 'Özet',
      'quiz' => 'Quiz',
      'flashcard' => 'Kart',
      _ => 'Mod',
    };
  }

  String _getModeDescription(String mode) {
    return switch (mode) {
      'explain' => 'Konuyu detaylı açıkla',
      'summary' => 'Kısa ve öz özet çıkar',
      'quiz' => 'Test soruları hazırla',
      'flashcard' => 'Hatırlatma kartları oluştur',
      _ => '',
    };
  }
}
