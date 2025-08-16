import 'package:flutter/material.dart';

class ImageUtils {
  // Headers padrão para requisições de imagem
  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };

  /// Widget seguro para carregamento de imagens de rede
  static Widget safeNetworkImage({
    required String imageUrl,
    BoxFit fit = BoxFit.contain,
    Widget? errorWidget,
    Widget? loadingWidget,
    double? width,
    double? height,
    Map<String, String>? headers,
  }) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      headers: headers ?? defaultHeaders,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('🖼️ Erro ao carregar imagem: $imageUrl - $error');
        return errorWidget ?? _buildDefaultErrorWidget(context);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return loadingWidget ?? _buildDefaultLoadingWidget(
          context, 
          loadingProgress,
          width: width,
          height: height,
        );
      },
    );
  }

  /// NetworkImage provider seguro para uso em DecorationImage
  static ImageProvider safeNetworkImageProvider(
    String imageUrl, {
    Map<String, String>? headers,
  }) {
    return NetworkImage(
      imageUrl,
      headers: headers ?? defaultHeaders,
    );
  }

  /// Widget de erro padrão
  static Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de carregamento padrão
  static Widget _buildDefaultLoadingWidget(
    BuildContext context,
    ImageChunkEvent loadingProgress, {
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
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
            const SizedBox(height: 8),
            Text(
              'Carregando...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Verifica se uma URL de imagem é válida
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Cria um placeholder personalizado para imagens
  static Widget buildImagePlaceholder({
    required BuildContext context,
    IconData icon = Icons.image,
    String? text,
    double? width,
    double? height,
    Color? backgroundColor,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            size: 48,
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}