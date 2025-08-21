import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/services/language_service.dart';
import 'package:provider/provider.dart' as provider;

/// Widget de seleção de tema usando Riverpod
/// Versão migrada do seletor de tema que usa ConsumerWidget ao invés de Consumer
class ThemeToggleButtonRiverpod extends ConsumerWidget {
  const ThemeToggleButtonRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar Riverpod para acessar o tema atual
    final themeState = ref.watch(themeProvider);
    
    return ListTile(
      leading: Icon(
        Icons.palette, 
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Tema'),
      subtitle: Text(
        _getThemeDisplayName(themeState.themeMode),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref),
    );
  }

  /// Retorna o nome exibido para cada modo de tema
  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
    }
  }

  /// Mostra o diálogo de seleção de tema usando Riverpod
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    // Ainda precisamos usar Provider para LanguageService e UserSettingsService
    // até que sejam migrados para Riverpod
    final languageService = provider.Provider.of<LanguageService>(context, listen: false);
    final userSettingsService = provider.Provider.of<UserSettingsService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(languageService.strings.selectTheme),
        contentPadding: EdgeInsets.zero,
        content: Consumer(
          builder: (context, ref, child) {
            final themeState = ref.watch(themeProvider);
            final themeNotifier = ref.read(themeProvider.notifier);
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // System theme
                ListTile(
                  leading: Icon(
                    Icons.brightness_auto,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(languageService.strings.systemTheme),
                  trailing: themeState.themeMode == ThemeMode.system
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(width: 24),
                  onTap: () async {
                    await userSettingsService.setTheme(ThemeMode.system);
                    await themeNotifier.setSystemTheme();
                    Navigator.pop(dialogContext);
                  },
                ),
                
                // Light theme
                ListTile(
                  leading: Icon(
                    Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(languageService.strings.lightTheme),
                  trailing: themeState.themeMode == ThemeMode.light
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(width: 24),
                  onTap: () async {
                    await userSettingsService.setTheme(ThemeMode.light);
                    await themeNotifier.setLightTheme();
                    Navigator.pop(dialogContext);
                  },
                ),
                
                // Dark theme
                ListTile(
                  leading: Icon(
                    Icons.dark_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(languageService.strings.darkTheme),
                  trailing: themeState.themeMode == ThemeMode.dark
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(width: 24),
                  onTap: () async {
                    await userSettingsService.setTheme(ThemeMode.dark);
                    await themeNotifier.setDarkTheme();
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(languageService.strings.cancel),
          ),
        ],
      ),
    );
  }
}

/// Widget simples de toggle tema (apenas alterna entre claro/escuro)
class SimpleThemeToggleRiverpod extends ConsumerWidget {
  const SimpleThemeToggleRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    return IconButton(
      icon: Icon(
        themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () {
        themeNotifier.toggleTheme();
      },
      tooltip: themeState.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
    );
  }
}

/// Widget de FloatingActionButton para toggle tema
class ThemeToggleFABRiverpod extends ConsumerWidget {
  const ThemeToggleFABRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    return FloatingActionButton.small(
      onPressed: () {
        themeNotifier.toggleTheme();
      },
      tooltip: themeState.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
      child: Icon(
        themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
    );
  }
}

/// Widget card para configurações de tema
class ThemeSettingsCardRiverpod extends ConsumerWidget {
  const ThemeSettingsCardRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aparência',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ThemeToggleButtonRiverpod(),
            const SizedBox(height: 8),
            Text(
              'Tema atual: ${_getThemeDisplayName(themeState.themeMode)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
    }
  }
}