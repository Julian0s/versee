import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class SocialProofSection extends StatelessWidget {
  const SocialProofSection({super.key});

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
            vertical: 80,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              // Expectations Row
              _buildExpectationsRow(context, languageService, isDesktop, isTablet),
              
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpectationsRow(BuildContext context, LanguageService languageService, bool isDesktop, bool isTablet) {
    final expectations = [
      _ExpectationItem(
        icon: Icons.star,
        titleValues: {
          'pt': 'Qualidade Profissional',
          'en': 'Professional Quality',
          'es': 'Calidad Profesional',
          'ja': 'プロフェッショナル品質',
        },
        descriptionValues: {
          'pt': 'Qualidade profissional em cada apresentação — simples, rápida e impactante.',
          'en': 'Professional quality in every presentation — simple, fast and impactful.',
          'es': 'Calidad profesional en cada presentación — simple, rápida e impactante.',
          'ja': 'すべてのプレゼンテーションでプロフェッショナル品質 — シンプル、高速、インパクト。',
        },
      ),
      _ExpectationItem(
        icon: Icons.flash_on,
        titleValues: {
          'pt': 'Interface Intuitiva',
          'en': 'Intuitive Interface',
          'es': 'Interfaz Intuitiva',
          'ja': '直感的なインターフェース',
        },
        descriptionValues: {
          'pt': 'Interface intuitiva e recursos completos para preparar tudo em minutos.',
          'en': 'Intuitive interface and complete features to prepare everything in minutes.',
          'es': 'Interfaz intuitiva y características completas para preparar todo en minutos.',
          'ja': '数分ですべてを準備するための直感的なインターフェースと完全な機能。',
        },
      ),
      _ExpectationItem(
        icon: Icons.tv,
        titleValues: {
          'pt': 'Projeção Fluida',
          'en': 'Fluid Projection',
          'es': 'Proyección Fluida',
          'ja': '流れるような投影',
        },
        descriptionValues: {
          'pt': 'Projeção em segunda tela com fluidez e sem complicação.',
          'en': 'Second screen projection with fluidity and without complications.',
          'es': 'Proyección en segunda pantalla con fluidez y sin complicación.',
          'ja': '複雑さなく、流れるようなセカンドスクリーン投影。',
        },
      ),
    ];

    return Column(
      children: [
        Text(
          _getValue({
            'pt': 'O que Você Pode Esperar',
            'en': 'What You Can Expect',
            'es': 'Lo que Puedes Esperar',
            'ja': 'ご期待いただけること',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 50),
        
        isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: expectations
                    .map((expectation) => Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildExpectationCard(context, languageService, expectation),
                          ),
                        ))
                    .toList(),
              )
            : isTablet
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: expectations
                            .take(2)
                            .map((expectation) => Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: _buildExpectationCard(context, languageService, expectation),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: expectations
                            .skip(2)
                            .map((expectation) => Flexible(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 350),
                                    child: _buildExpectationCard(context, languageService, expectation),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  )
                : Column(
                    children: expectations
                        .map((expectation) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildExpectationCard(context, languageService, expectation),
                            ))
                        .toList(),
                  ),
      ],
    );
  }

  Widget _buildExpectationCard(BuildContext context, LanguageService languageService, _ExpectationItem expectation) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    
    return Container(
      width: isDesktop ? 350 : (isTablet ? 300 : double.infinity),
      height: 350,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              expectation.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getValue(expectation.titleValues, languageService),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              _getValue(expectation.descriptionValues, languageService),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(BuildContext context, LanguageService languageService, bool isDesktop) {
    final features = [
      _AdvancedFeature(
        icon: Icons.cloud_sync,
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
        color: Colors.blue,
      ),
      _AdvancedFeature(
        icon: Icons.palette,
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
        color: Colors.purple,
      ),
      _AdvancedFeature(
        icon: Icons.devices,
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
        color: Colors.green,
      ),
    ];

    return Column(
      children: [
        Text(
          _getValue({
            'pt': 'Recursos Avançados',
            'en': 'Advanced Features',
            'es': 'Características Avanzadas',
            'ja': '高度な機能',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 50),
        
        isDesktop
            ? Row(
                children: features
                    .map((feature) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildAdvancedFeatureCard(context, languageService, feature),
                          ),
                        ))
                    .toList(),
              )
            : Column(
                children: features
                    .map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: _buildAdvancedFeatureCard(context, languageService, feature),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildAdvancedFeatureCard(BuildContext context, LanguageService languageService, _AdvancedFeature feature) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(30),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            _getValue(feature.titleValues, languageService),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _getValue(feature.descriptionValues, languageService),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectationItem {
  final IconData icon;
  final Map<String, String> titleValues;
  final Map<String, String> descriptionValues;

  _ExpectationItem({
    required this.icon,
    required this.titleValues,
    required this.descriptionValues,
  });
}

class _AdvancedFeature {
  final IconData icon;
  final Map<String, String> titleValues;
  final Map<String, String> descriptionValues;
  final Color color;

  _AdvancedFeature({
    required this.icon,
    required this.titleValues,
    required this.descriptionValues,
    required this.color,
  });
}