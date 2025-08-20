import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/services/user_settings_service.dart';
import 'package:provider/provider.dart' as provider;

/// Widget de seleção de idioma usando Riverpod
/// Versão migrada do seletor de idioma que usa ConsumerWidget ao invés de Consumer
class LanguageSelectorRiverpod extends ConsumerWidget {
  const LanguageSelectorRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar Riverpod para acessar o idioma atual
    final languageState = ref.watch(languageProvider);
    
    return ListTile(
      leading: Icon(
        Icons.language, 
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Idioma'),
      subtitle: Text(
        _getLanguageDisplayName(languageState.currentLanguageCode),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, ref),
    );
  }

  /// Retorna o nome exibido para cada idioma
  String _getLanguageDisplayName(String languageCode) {
    return LanguageNotifier.languageNames[languageCode] ?? 'Português';
  }

  /// Mostra o diálogo de seleção de idioma usando Riverpod
  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    // Ainda precisamos usar Provider para UserSettingsService
    // até que seja migrado para Riverpod
    final userSettingsService = provider.Provider.of<UserSettingsService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selecionar idioma'),
        contentPadding: EdgeInsets.zero,
        content: Consumer(
          builder: (context, ref, child) {
            final languageState = ref.watch(languageProvider);
            final languageNotifier = ref.read(languageProvider.notifier);
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: LanguageNotifier.languageNames.entries.map((entry) {
                final languageCode = entry.key;
                final languageName = entry.value;
                final isSelected = languageState.currentLanguageCode == languageCode;
                
                IconData languageIcon;
                switch (languageCode) {
                  case 'pt':
                    languageIcon = Icons.flag;
                    break;
                  case 'en':
                    languageIcon = Icons.flag_outlined;
                    break;
                  case 'es':
                    languageIcon = Icons.flag_circle;
                    break;
                  case 'ja':
                    languageIcon = Icons.flag_circle_outlined;
                    break;
                  default:
                    languageIcon = Icons.language;
                }
                
                return ListTile(
                  leading: Icon(
                    languageIcon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(languageName),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(width: 24),
                  onTap: () async {
                    await userSettingsService.setLanguage(languageCode);
                    await languageNotifier.setLanguage(languageCode);
                    Navigator.pop(dialogContext);
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

/// Widget simples de dropdown para idiomas
class SimpleLanguageDropdownRiverpod extends ConsumerWidget {
  const SimpleLanguageDropdownRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);
    
    return DropdownButton<String>(
      value: languageState.currentLanguageCode,
      items: LanguageNotifier.languageNames.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getLanguageFlag(entry.key),
              const SizedBox(width: 8),
              Text(entry.value),
            ],
          ),
        );
      }).toList(),
      onChanged: (languageCode) {
        if (languageCode != null) {
          languageNotifier.setLanguage(languageCode);
        }
      },
    );
  }

  Widget _getLanguageFlag(String languageCode) {
    IconData icon;
    switch (languageCode) {
      case 'pt':
        icon = Icons.flag;
        break;
      case 'en':
        icon = Icons.flag_outlined;
        break;
      case 'es':
        icon = Icons.flag_circle;
        break;
      case 'ja':
        icon = Icons.flag_circle_outlined;
        break;
      default:
        icon = Icons.language;
    }
    return Icon(icon, size: 20);
  }
}

/// Widget de FloatingActionButton para trocar idioma
class LanguageToggleFABRiverpod extends ConsumerWidget {
  const LanguageToggleFABRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);
    
    return FloatingActionButton.small(
      onPressed: () {
        // Cicla entre os idiomas: pt -> en -> es -> ja -> pt
        final currentCode = languageState.currentLanguageCode;
        String nextCode;
        switch (currentCode) {
          case 'pt':
            nextCode = 'en';
            break;
          case 'en':
            nextCode = 'es';
            break;
          case 'es':
            nextCode = 'ja';
            break;
          case 'ja':
            nextCode = 'pt';
            break;
          default:
            nextCode = 'pt';
        }
        languageNotifier.setLanguage(nextCode);
      },
      tooltip: 'Trocar idioma',
      child: const Icon(Icons.language),
    );
  }
}

/// Widget card para configurações de idioma
class LanguageSettingsCardRiverpod extends ConsumerWidget {
  const LanguageSettingsCardRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Idioma',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LanguageSelectorRiverpod(),
            const SizedBox(height: 8),
            Text(
              'Idioma atual: ${_getLanguageDisplayName(languageState.currentLanguageCode)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    return LanguageNotifier.languageNames[languageCode] ?? 'Português';
  }
}