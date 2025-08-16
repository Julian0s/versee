import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  String _getValue(Map<String, String> values, LanguageService languageService) {
    return values[languageService.currentLanguageCode] ?? values['pt'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Logo and app name
                    _buildLogo(context),
                    
                    const SizedBox(height: 40),
                    
                    // Welcome message
                    _buildWelcomeMessage(context, languageService),
                    
                    const SizedBox(height: 60),
                    
                    // Feature highlights
                    _buildFeatureHighlights(context, languageService),
                    
                    const Spacer(flex: 3),
                    
                    // Action buttons
                    _buildActionButtons(context, languageService),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.present_to_all,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(height: 20),
        
        Text(
          'VERSEE',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage(BuildContext context, LanguageService languageService) {
    return Column(
      children: [
        Text(
          _getValue({
            'pt': 'Bem-vindo ao VERSEE!',
            'en': 'Welcome to VERSEE!',
            'es': '¡Bienvenido a VERSEE!',
            'ja': 'VERSEEへようこそ！',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          _getValue({
            'pt': 'Transforme suas apresentações de culto com tecnologia moderna e interface intuitiva.',
            'en': 'Transform your worship presentations with modern technology and intuitive interface.',
            'es': 'Transforma tus presentaciones de culto con tecnología moderna e interfaz intuitiva.',
            'ja': 'モダンなテクノロジーと直感的なインターフェースで礼拝プレゼンテーションを変革しましょう。',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights(BuildContext context, LanguageService languageService) {
    final features = [
      {
        'icon': Icons.menu_book,
        'title': _getValue({
          'pt': 'Versículos Bíblicos',
          'en': 'Bible Verses',
          'es': 'Versículos Bíblicos',
          'ja': '聖書の節',
        }, languageService),
        'description': _getValue({
          'pt': 'Múltiplas versões da Bíblia',
          'en': 'Multiple Bible versions',
          'es': 'Múltiples versiones de la Biblia',
          'ja': '複数の聖書バージョン',
        }, languageService),
      },
      {
        'icon': Icons.slideshow,
        'title': _getValue({
          'pt': 'Slides Personalizados',
          'en': 'Custom Slides',
          'es': 'Diapositivas Personalizadas',
          'ja': 'カスタムスライド',
        }, languageService),
        'description': _getValue({
          'pt': 'Crie apresentações únicas',
          'en': 'Create unique presentations',
          'es': 'Crea presentaciones únicas',
          'ja': 'ユニークなプレゼンテーションを作成',
        }, languageService),
      },
      {
        'icon': Icons.tv,
        'title': _getValue({
          'pt': 'Projeção Externa',
          'en': 'External Projection',
          'es': 'Proyección Externa',
          'ja': '外部プロジェクション',
        }, languageService),
        'description': _getValue({
          'pt': 'Segunda tela para projeção',
          'en': 'Second screen for projection',
          'es': 'Segunda pantalla para proyección',
          'ja': 'プロジェクション用セカンドスクリーン',
        }, languageService),
      },
    ];

    return Column(
      children: features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, LanguageService languageService) {
    return Column(
      children: [
        // Primary button - Get Started
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
            icon: const Icon(Icons.rocket_launch),
            label: Text(
              _getValue({
                'pt': 'Começar Agora',
                'en': 'Get Started',
                'es': 'Comenzar Ahora',
                'ja': '今すぐ始める',
              }, languageService),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Secondary button - Login
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            icon: const Icon(Icons.login),
            label: Text(
              _getValue({
                'pt': 'Já tenho conta',
                'en': 'I already have an account',
                'es': 'Ya tengo cuenta',
                'ja': 'アカウントをお持ちの方',
              }, languageService),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Terms and privacy
        Text(
          _getValue({
            'pt': 'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade',
            'en': 'By continuing, you agree to our Terms of Use and Privacy Policy',
            'es': 'Al continuar, aceptas nuestros Términos de Uso y Política de Privacidad',
            'ja': '続行することで、利用規約とプライバシーポリシーに同意したものとみなされます',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}