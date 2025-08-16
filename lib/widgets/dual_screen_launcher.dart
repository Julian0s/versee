import 'package:flutter/material.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/pages/presentation_control_page.dart';

/// Widget utilitário para lançar apresentações em dual screen
/// Pode ser usado em qualquer página que queira oferecer apresentação
class DualScreenLauncher {
  /// Inicia apresentação de um item único em dual screen
  static void presentSingleItem({
    required BuildContext context,
    required PresentationItem item,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresentationControlPage(
          initialItem: item,
        ),
      ),
    );
  }

  /// Inicia apresentação de múltiplos itens em dual screen
  static void presentMultipleItems({
    required BuildContext context,
    required List<PresentationItem> items,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresentationControlPage(
          playlistItems: items,
          playlistTitle: title,
        ),
      ),
    );
  }

  /// Cria um PresentationItem a partir de um versículo
  static PresentationItem createBibleItem({
    required String reference,
    required String text,
    required String version,
  }) {
    return PresentationItem(
      id: 'bible_${DateTime.now().millisecondsSinceEpoch}',
      title: reference,
      type: ContentType.bible,
      content: text,
      metadata: {
        'reference': reference,
        'version': version,
      },
    );
  }

  /// Cria um PresentationItem a partir de texto livre (nota/letra)
  static PresentationItem createTextItem({
    required String title,
    required String content,
    ContentType type = ContentType.notes,
  }) {
    return PresentationItem(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: type,
      content: content,
    );
  }

  /// Cria um PresentationItem a partir de mídia
  static PresentationItem createMediaItem({
    required String title,
    required String path,
    required ContentType type,
  }) {
    return PresentationItem(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: type,
      content: path,
    );
  }

  /// Mostra diálogo de confirmação antes de iniciar apresentação
  static void showPresentationDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.cast_connected,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Iniciar Apresentação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja apresentar em dual screen?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Será aberta uma janela de controle separada da tela de projeção.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Apresentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget botão rápido para apresentação dual screen
class DualScreenButton extends StatelessWidget {
  final PresentationItem? item;
  final List<PresentationItem>? items;
  final String? title;
  final bool mini;

  const DualScreenButton({
    super.key,
    this.item,
    this.items,
    this.title,
    this.mini = false,
  }) : assert(item != null || items != null);

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return IconButton(
        onPressed: _hasContent ? () => _startPresentation(context) : null,
        icon: const Icon(Icons.cast_connected),
        tooltip: 'Apresentar em Dual Screen',
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _hasContent ? () => _startPresentation(context) : null,
      icon: const Icon(Icons.cast_connected),
      label: const Text('Dual Screen'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  bool get _hasContent => item != null || (items != null && items!.isNotEmpty);

  void _startPresentation(BuildContext context) {
    if (item != null) {
      DualScreenLauncher.showPresentationDialog(
        context: context,
        title: item!.title,
        subtitle: _getContentTypeLabel(item!.type),
        onConfirm: () {
          DualScreenLauncher.presentSingleItem(
            context: context,
            item: item!,
          );
        },
      );
    } else if (items != null && items!.isNotEmpty) {
      DualScreenLauncher.showPresentationDialog(
        context: context,
        title: title ?? 'Apresentação',
        subtitle: '${items!.length} itens',
        onConfirm: () {
          DualScreenLauncher.presentMultipleItems(
            context: context,
            items: items!,
            title: title ?? 'Apresentação',
          );
        },
      );
    }
  }

  String _getContentTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.bible: return 'Versículo Bíblico';
      case ContentType.lyrics: return 'Letra de Música';
      case ContentType.notes: return 'Nota/Sermão';
      case ContentType.audio: return 'Áudio';
      case ContentType.video: return 'Vídeo';
      case ContentType.image: return 'Imagem';
    }
  }
}