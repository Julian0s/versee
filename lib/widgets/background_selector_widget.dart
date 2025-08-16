import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/media_service.dart';
import 'package:versee/models/media_models.dart';

class BackgroundSelectorWidget extends StatefulWidget {
  final Color? currentBackgroundColor;
  final String? currentBackgroundImageUrl;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<String> onBackgroundImageChanged;
  final VoidCallback? onRemoveBackground;

  const BackgroundSelectorWidget({
    super.key,
    this.currentBackgroundColor,
    this.currentBackgroundImageUrl,
    required this.onBackgroundColorChanged,
    required this.onBackgroundImageChanged,
    this.onRemoveBackground,
  });

  @override
  State<BackgroundSelectorWidget> createState() => _BackgroundSelectorWidgetState();
}

class _BackgroundSelectorWidgetState extends State<BackgroundSelectorWidget> with TickerProviderStateMixin {
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
              offset: const Offset(0, -4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Personalizar Fundo',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Cores', 0, Icons.color_lens_rounded),
                    _buildTabButton('Imagens', 1, Icons.image_rounded),
                    _buildTabButton('Mídia', 2, Icons.photo_library_rounded),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Content based on selected tab
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildColorsTab(context),
                  _buildDefaultImagesTab(context),
                  _buildMediaImagesTab(context),
                ],
              ),
            ),
            
            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione uma cor sólida',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildColorGrid(context)),
        ],
      ),
    );
  }

  Widget _buildDefaultImagesTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Imagens pré-definidas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildImageGrid(context)),
        ],
      ),
    );
  }

  Widget _buildMediaImagesTab(BuildContext context) {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        final images = mediaService.imageItems;
        
        if (images.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma imagem encontrada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione imagens na página de mídia para usá-las como fundo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suas imagens (${images.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildUserImagesGrid(context, images)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          // Preview container showing current background
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: widget.currentBackgroundColor ?? Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: widget.currentBackgroundImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _SafeNetworkImage(
                      imageUrl: widget.currentBackgroundImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            'Atual',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // Remove background button
          if (widget.currentBackgroundImageUrl != null || widget.currentBackgroundColor != Colors.black)
            TextButton.icon(
              onPressed: () {
                widget.onBackgroundColorChanged(Colors.black);
                if (widget.onRemoveBackground != null) {
                  widget.onRemoveBackground!();
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text('Remover'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.grey.shade900,
      Colors.white,
      Colors.blue.shade900,
      Colors.indigo.shade900,
      Colors.purple.shade900,
      Colors.deepPurple.shade900,
      Colors.red.shade900,
      Colors.pink.shade900,
      Colors.orange.shade900,
      Colors.amber.shade900,
      Colors.green.shade900,
      Colors.teal.shade900,
      Colors.cyan.shade900,
      Colors.lightBlue.shade900,
      Colors.brown.shade900,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = widget.currentBackgroundColor == color && widget.currentBackgroundImageUrl == null;
        
        return GestureDetector(
          onTap: () {
            widget.onBackgroundColorChanged(color);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: _getContrastingColor(color),
                    size: 20,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    // URLs de imagens de fundo mais simples e confiáveis
    final backgroundImages = [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop&auto=format',
      'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800&h=600&fit=crop&auto=format',
      'https://images.unsplash.com/photo-1476842634003-7dcca8f832de?w=800&h=600&fit=crop&auto=format',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop&auto=format',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&h=600&fit=crop&auto=format',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop&auto=format&sat=-100',
      'https://images.unsplash.com/photo-1553913861-c0fddf2619ee?w=800&h=600&fit=crop&auto=format',
      'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800&h=600&fit=crop&auto=format',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: backgroundImages.length,
      itemBuilder: (context, index) {
        final imageUrl = backgroundImages[index];
        final isSelected = widget.currentBackgroundImageUrl == imageUrl;
        
        return GestureDetector(
          onTap: () {
            widget.onBackgroundImageChanged(imageUrl);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SafeNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                  if (isSelected)
                    Container(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserImagesGrid(BuildContext context, List<ImageItem> images) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final isSelected = widget.currentBackgroundImageUrl == image.sourcePath;
        
        return GestureDetector(
          onTap: () {
            widget.onBackgroundImageChanged(image.sourcePath);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SafeNetworkImage(
                    imageUrl: image.sourcePath,
                    fit: BoxFit.cover,
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        image.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getContrastingColor(Color backgroundColor) {
    // Calcula a luminância para determinar se deve usar texto claro ou escuro
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Widget para carregamento seguro de imagens de rede
class _SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const _SafeNetworkImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Erro ao carregar imagem: $imageUrl - $error');
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                'Erro',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
      headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );
  }
}