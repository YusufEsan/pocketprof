import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/providers/audio_provider.dart';
import 'package:pocket_prof/services/audio_teacher_service.dart';

/// Audio player bar widget
class AudioPlayerBar extends ConsumerWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final isActive = audioState.isPlaying || audioState.isPaused;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              audioState.isLoading ? Icons.hourglass_empty : Icons.school,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hocayı Dinle',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  _getStatus(audioState.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Skip backward - always enabled when active
          IconButton(
            icon: const Icon(Icons.replay_10, size: 22),
            onPressed: isActive
                ? () => ref.read(audioPlayerProvider.notifier).skipBackward(10)
                : null,
            color: AppTheme.primary,
            visualDensity: VisualDensity.compact,
          ),
          // Play/Pause
          IconButton.filled(
            icon: Icon(
              audioState.isLoading
                  ? Icons.hourglass_empty
                  : audioState.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              size: 24,
            ),
            onPressed: audioState.isLoading
                ? null
                : () =>
                      ref.read(audioPlayerProvider.notifier).togglePlayPause(),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          // Skip forward
          IconButton(
            icon: const Icon(Icons.forward_10, size: 22),
            onPressed: isActive
                ? () => ref.read(audioPlayerProvider.notifier).skipForward(10)
                : null,
            color: AppTheme.primary,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => ref.read(audioPlayerProvider.notifier).stop(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _getStatus(AudioState s) => switch (s) {
    AudioState.loading => 'Hazırlanıyor...',
    AudioState.playing => 'Oynatılıyor',
    AudioState.paused => 'Duraklatıldı',
    _ => 'Hazır',
  };
}
