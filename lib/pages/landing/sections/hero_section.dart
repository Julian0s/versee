import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.05),
              ],
            ),
          ),
          child: isDesktop 
            ? _buildDesktopLayout(context, languageService)
            : _buildMobileLayout(context, languageService),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, LanguageService languageService) {
    return Row(
      children: [
        // Left side - Text Content
        Expanded(
          flex: 5,
          child: _buildHeroContent(context, languageService),
        ),
        
        const SizedBox(width: 80),
        
        // Right side - App Preview
        Expanded(
          flex: 4,
          child: _buildAppPreview(context, languageService),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, LanguageService languageService) {
    return Column(
      children: [
        _buildHeroContent(context, languageService),
        const SizedBox(height: 60),
        _buildAppPreview(context, languageService),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Headline
        Text(
          _getValue({
            'pt': 'Transforme seus Cultos com\nApresentações Profissionais',
            'en': 'Transform your Worship with\nProfessional Presentations',
            'es': 'Transforma tu Culto con\nPresentaciones Profesionales',
            'ja': '礼拝を変革する\nプロフェッショナルプレゼンテーション',
          }, languageService),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Subheadline
        Text(
          _getValue({
            'pt': 'O aplicativo #1 para igrejas apresentarem versículos bíblicos, slides personalizados e mídias com qualidade profissional.',
            'en': 'The #1 app for churches to present bible verses, custom slides and media with professional quality.',
            'es': 'La aplicación #1 para iglesias presentar versículos bíblicos, diapositivas personalizadas y medios con calidad profesional.',
            'ja': '教会が聖書の節、カスタムスライド、プロ品質のメディアを表示するための#1アプリ。',
          }, languageService),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // CTAs
        Row(
          children: [
            // Primary CTA
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/auth'),
              icon: const Icon(Icons.rocket_launch),
              label: Text(_getValue({
                'pt': 'Começar Gratuitamente',
                'en': 'Start Free',
                'es': 'Empezar Gratis',
                'ja': '無料で始める',
              }, languageService)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Secondary CTA
            OutlinedButton.icon(
              onPressed: () => _showDemo(context),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(_getValue({
                'pt': 'Ver Demonstração',
                'en': 'View Demo',
                'es': 'Ver Demostración',
                'ja': 'デモを見る',
              }, languageService)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Trust indicators
        Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _getValue({
                'pt': 'Gratuito para começar • Sem cartão de crédito',
                'en': 'Free to start • No credit card required',
                'es': 'Gratis para empezar • Sin tarjeta de crédito',
                'ja': '無料でスタート • クレジットカード不要',
              }, languageService),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppPreview(BuildContext context, LanguageService languageService) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Phone mockup background
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 8,
              ),
            ),
          ),
          
          // App content mockup
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            bottom: 40,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.present_to_all,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'VERSEE',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getValue({
                      'pt': 'Preview do App',
                      'en': 'App Preview',
                      'es': 'Vista Previa de la App',
                      'ja': 'アプリプレビュー',
                    }, languageService),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Feature preview cards
                  _buildPreviewCard(context, languageService, Icons.menu_book, {
                    'pt': 'Versículos Bíblicos',
                    'en': 'Bible Verses',
                    'es': 'Versículos Bíblicos',
                    'ja': '聖書の節',
                  }),
                  const SizedBox(height: 12),
                  _buildPreviewCard(context, languageService, Icons.slideshow, {
                    'pt': 'Slides Personalizados',
                    'en': 'Custom Slides',
                    'es': 'Diapositivas Personalizadas',
                    'ja': 'カスタムスライド',
                  }),
                  const SizedBox(height: 12),
                  _buildPreviewCard(context, languageService, Icons.tv, {
                    'pt': 'Projeção Externa',
                    'en': 'External Projection',
                    'es': 'Proyección Externa',
                    'ja': '外部プロジェクション',
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, LanguageService languageService, IconData icon, Map<String, String> titleValues) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            _getValue(titleValues, languageService),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDemo(BuildContext context) {
    // TODO: Implement demo modal or video
    final languageService = Provider.of<LanguageService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getValue({
          'pt': 'Demo em breve! Por enquanto, experimente o app gratuitamente.',
          'en': 'Demo coming soon! For now, try the app for free.',
          'es': '¡Demo próximamente! Por ahora, prueba la aplicación gratis.',
          'ja': 'デモ近日公開！今のところ、アプリを無料でお試しください。',
        }, languageService)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}