import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  String _getValue(Map<String, String> values, LanguageService languageService) {
    return values[languageService.currentLanguageCode] ?? values['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
            vertical: 100,
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Section Header
              _buildSectionHeader(context, languageService),
              
              const SizedBox(height: 80),
              
              // Features Grid
              _buildFeaturesGrid(context, languageService, isDesktop, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, LanguageService languageService) {
    return Column(
      children: [
        Text(
          _getValue({
            'pt': 'Recursos Poderosos para Apresentações Impactantes',
            'en': 'Powerful Features for Impactful Presentations',
            'es': 'Características Potentes para Presentaciones Impactantes',
            'ja': 'インパクトのあるプレゼンテーションのための強力な機能',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 20),
        
        Text(
          _getValue({
            'pt': 'Tudo que você precisa para elevar o nível das apresentações da sua igreja',
            'en': 'Everything you need to elevate your church presentations',
            'es': 'Todo lo que necesitas para elevar las presentaciones de tu iglesia',
            'ja': '教会のプレゼンテーションを向上させるために必要なすべて',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, LanguageService languageService, bool isDesktop, bool isTablet) {
    final features = _getFeatures(context, languageService);
    
    if (isDesktop) {
      return Column(
        children: [
          // First row - 3 cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: features
                  .take(3)
                  .map((feature) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: feature,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 40),
          // Second row - 3 cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: features
                  .skip(3)
                  .take(3)
                  .map((feature) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: feature,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: features
                  .take(2)
                  .map((feature) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: feature,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 40),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: features
                  .skip(2)
                  .take(2)
                  .map((feature) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: feature,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 40),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: features
                  .skip(4)
                  .take(2)
                  .map((feature) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: feature,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: features
            .map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: feature,
                ))
            .toList(),
      );
    }
  }

  List<Widget> _getFeatures(BuildContext context, LanguageService languageService) {
    return [
      _buildFeatureCard(
        context,
        languageService,
        icon: Icons.menu_book,
        iconColor: Colors.blue,
        titleValues: {
          'pt': 'Versículos Bíblicos',
          'en': 'Bible Verses',
          'es': 'Versículos Bíblicos',
          'ja': '聖書の節',
        },
        descriptionValues: {
          'pt': 'Acesso a múltiplas versões da Bíblia com busca inteligente e seleção de versículos para apresentação.',
          'en': 'Access to multiple Bible versions with intelligent search and verse selection for presentation.',
          'es': 'Acceso a múltiples versiones de la Biblia con búsqueda inteligente y selección de versículos para presentación.',
          'ja': 'プレゼンテーション用のインテリジェント検索と節選択機能を備えた複数の聖書バージョンへのアクセス。',
        },
        featuresValues: [
          {
            'pt': 'Múltiplas traduções',
            'en': 'Multiple translations',
            'es': 'Múltiples traducciones',
            'ja': '複数の翻訳',
          },
          {
            'pt': 'Busca por palavras-chave',
            'en': 'Keyword search',
            'es': 'Búsqueda por palabras clave',
            'ja': 'キーワード検索',
          },
          {
            'pt': 'Seleção de versículos',
            'en': 'Verse selection',
            'es': 'Selección de versículos',
            'ja': '節の選択',
          },
          {
            'pt': 'Formatação automática',
            'en': 'Automatic formatting',
            'es': 'Formato automático',
            'ja': '自動フォーマット',
          },
        ],
      ),
      _buildFeatureCard(
        context,
        languageService,
        icon: Icons.slideshow,
        iconColor: Colors.green,
        titleValues: {
          'pt': 'Slides Personalizados',
          'en': 'Custom Slides',
          'es': 'Diapositivas Personalizadas',
          'ja': 'カスタムスライド',
        },
        descriptionValues: {
          'pt': 'Crie slides com textos, formatação personalizada e backgrounds para complementar suas apresentações.',
          'en': 'Create slides with texts, custom formatting and backgrounds to complement your presentations.',
          'es': 'Crea diapositivas con textos, formato personalizado y fondos para complementar tus presentaciones.',
          'ja': 'テキスト、カスタムフォーマット、背景でスライドを作成してプレゼンテーションを補完します。',
        },
        featuresValues: [
          {
            'pt': 'Editor de texto rico',
            'en': 'Rich text editor',
            'es': 'Editor de texto enriquecido',
            'ja': 'リッチテキストエディター',
          },
          {
            'pt': 'Backgrounds personalizados',
            'en': 'Custom backgrounds',
            'es': 'Fondos personalizados',
            'ja': 'カスタム背景',
          },
          {
            'pt': 'Múltiplos layouts',
            'en': 'Multiple layouts',
            'es': 'Múltiples diseños',
            'ja': '複数のレイアウト',
          },
          {
            'pt': 'Preview em tempo real',
            'en': 'Real-time preview',
            'es': 'Vista previa en tiempo real',
            'ja': 'リアルタイムプレビュー',
          },
        ],
      ),
      _buildFeatureCard(
        context,
        languageService,
        icon: Icons.tv,
        iconColor: Colors.purple,
        titleValues: {
          'pt': 'Projeção Externa',
          'en': 'External Projection',
          'es': 'Proyección Externa',
          'ja': '外部プロジェクション',
        },
        descriptionValues: {
          'pt': 'Projete suas apresentações em segunda tela com controle total sobre resolução e configurações.',
          'en': 'Project your presentations on a second screen with full control over resolution and settings.',
          'es': 'Proyecta tus presentaciones en una segunda pantalla con control total sobre resolución y configuraciones.',
          'ja': '解像度と設定を完全にコントロールしてセカンドスクリーンにプレゼンテーションを投影します。',
        },
        featuresValues: [
          {
            'pt': 'Segunda tela dedicada',
            'en': 'Dedicated second screen',
            'es': 'Segunda pantalla dedicada',
            'ja': '専用セカンドスクリーン',
          },
          {
            'pt': 'Múltiplas resoluções',
            'en': 'Multiple resolutions',
            'es': 'Múltiples resoluciones',
            'ja': '複数の解像度',
          },
          {
            'pt': 'Logo da igreja',
            'en': 'Church logo',
            'es': 'Logo de la iglesia',
            'ja': '教会のロゴ',
          },
          {
            'pt': 'Backgrounds customizados',
            'en': 'Custom backgrounds',
            'es': 'Fondos personalizados',
            'ja': 'カスタム背景',
          },
        ],
      ),
      _buildFeatureCard(
        context,
        languageService,
        icon: Icons.cloud_sync,
        iconColor: Colors.blue,
        titleValues: {
          'pt': 'Sincronização na Nuvem',
          'en': 'Cloud Synchronization',
          'es': 'Sincronización en la Nube',
          'ja': 'クラウド同期',
        },
        descriptionValues: {
          'pt': 'Mantenha suas apresentações sempre atualizadas e acessíveis em qualquer dispositivo com sincronização automática na nuvem.',
          'en': 'Keep your presentations always updated and accessible on any device with automatic cloud synchronization.',
          'es': 'Mantén tus presentaciones siempre actualizadas y accesibles en cualquier dispositivo con sincronización automática en la nube.',
          'ja': '自動クラウド同期により、プレゼンテーションを常に最新の状態に保ち、どのデバイスからでもアクセスできます。',
        },
        featuresValues: [
          {
            'pt': 'Backup automático',
            'en': 'Automatic backup',
            'es': 'Respaldo automático',
            'ja': '自動バックアップ',
          },
          {
            'pt': 'Acesso multiplataforma',
            'en': 'Cross-platform access',
            'es': 'Acceso multiplataforma',
            'ja': 'クロスプラットフォームアクセス',
          },
          {
            'pt': 'Sincronização em tempo real',
            'en': 'Real-time sync',
            'es': 'Sincronización en tiempo real',
            'ja': 'リアルタイム同期',
          },
          {
            'pt': 'Armazenamento seguro',
            'en': 'Secure storage',
            'es': 'Almacenamiento seguro',
            'ja': '安全なストレージ',
          },
        ],
      ),
      _buildFeatureCard(
        context,
        languageService,
        icon: Icons.palette,
        iconColor: Colors.purple,
        titleValues: {
          'pt': 'Temas Personalizáveis',
          'en': 'Customizable Themes',
          'es': 'Temas Personalizables',
          'ja': 'カスタマイズ可能なテーマ',
        },
        descriptionValues: {
          'pt': 'Adapte a aparência do aplicativo à identidade visual da sua igreja com temas e cores personalizáveis.',
          'en': 'Adapt the app appearance to your church visual identity with customizable themes and colors.',
          'es': 'Adapta la apariencia de la aplicación a la identidad visual de tu iglesia con temas y colores personalizables.',
          'ja': 'カスタマイズ可能なテーマと色で、アプリの外観を教会のビジュアルアイデンティティに合わせます。',
        },
        featuresValues: [
          {
            'pt': 'Paletas de cores',
            'en': 'Color palettes',
            'es': 'Paletas de colores',
            'ja': 'カラーパレット',
          },
          {
            'pt': 'Fontes customizadas',
            'en': 'Custom fonts',
            'es': 'Fuentes personalizadas',
            'ja': 'カスタムフォント',
          },
          {
            'pt': 'Logos personalizados',
            'en': 'Custom logos',
            'es': 'Logos personalizados',
            'ja': 'カスタムロゴ',
          },
          {
            'pt': 'Modo escuro/claro',
            'en': 'Dark/light mode',
            'es': 'Modo oscuro/claro',
            'ja': 'ダーク/ライトモード',
          },
        ],
      ),
      _buildFeatureCard(
        context,
        languageService,
        icon: Icons.devices,
        iconColor: Colors.green,
        titleValues: {
          'pt': 'Multi-plataforma',
          'en': 'Cross-platform',
          'es': 'Multi-plataforma',
          'ja': 'クロスプラットフォーム',
        },
        descriptionValues: {
          'pt': 'Funciona perfeitamente em Windows, macOS, Linux, iOS e Android. Use em qualquer dispositivo da sua escolha.',
          'en': 'Works perfectly on Windows, macOS, Linux, iOS and Android. Use on any device of your choice.',
          'es': 'Funciona perfectamente en Windows, macOS, Linux, iOS y Android. Úsalo en cualquier dispositivo de tu elección.',
          'ja': 'Windows、macOS、Linux、iOS、Androidで完璧に動作します。お好みのデバイスでご利用ください。',
        },
        featuresValues: [
          {
            'pt': 'Windows compatível',
            'en': 'Windows compatible',
            'es': 'Compatible con Windows',
            'ja': 'Windows対応',
          },
          {
            'pt': 'macOS e Linux',
            'en': 'macOS and Linux',
            'es': 'macOS y Linux',
            'ja': 'macOSとLinux',
          },
          {
            'pt': 'Apps móveis',
            'en': 'Mobile apps',
            'es': 'Apps móviles',
            'ja': 'モバイルアプリ',
          },
          {
            'pt': 'Versão web',
            'en': 'Web version',
            'es': 'Versión web',
            'ja': 'Web版',
          },
        ],
      ),
    ];
  }

  Widget _buildFeatureCard(
    BuildContext context,
    LanguageService languageService, {
    required IconData icon,
    required Color iconColor,
    required Map<String, String> titleValues,
    required Map<String, String> descriptionValues,
    required List<Map<String, String>> featuresValues,
  }) {
    return Container(
      height: 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            _getValue(titleValues, languageService),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            _getValue(descriptionValues, languageService),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Features list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: featuresValues
                  .map((featureValues) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: iconColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getValue(featureValues, languageService),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}