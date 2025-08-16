import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/pages/landing/sections/hero_section.dart';
import 'package:versee/pages/landing/sections/features_section.dart';
import 'package:versee/pages/landing/sections/pricing_section.dart';
import 'package:versee/pages/landing/sections/social_proof_section.dart';
import 'package:versee/pages/landing/sections/footer_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();

  String _getValue(Map<String, String> values, LanguageService languageService) {
    return values[languageService.currentLanguageCode] ?? values['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header/Navigation
            _buildHeader(context),
            
            // Hero Section
            const HeroSection(),
            
            // Features Section
            const FeaturesSection(),
            
            // Social Proof Section
            const SocialProofSection(),
            
            // Pricing Section
            const PricingSection(),
            
            // Footer
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo on the left
              SvgPicture.asset(
                'assets/images/versee_logo_header.svg',
                height: 32,
                fit: BoxFit.contain,
              ),
              
              const Spacer(),
              
              // Everything on the right side
              Row(
                children: [
                  // Navigation Menu
                  _buildNavButton(context, _getValue({
                    'pt': 'Recursos',
                    'en': 'Features',
                    'es': 'Recursos',
                    'ja': '機能',
                  }, languageService), () => _scrollToSection('features')),
                  const SizedBox(width: 32),
                  _buildNavButton(context, _getValue({
                    'pt': 'Preços',
                    'en': 'Pricing',
                    'es': 'Precios',
                    'ja': '料金',
                  }, languageService), () => _scrollToSection('pricing')),
                  const SizedBox(width: 32),
                  _buildNavButton(context, _getValue({
                    'pt': 'Contato',
                    'en': 'Contact',
                    'es': 'Contacto',
                    'ja': 'お問い合わせ',
                  }, languageService), () => _scrollToSection('contact')),
                  const SizedBox(width: 32),
                  
                  // Language Selector
                  _buildLanguageSelector(context, languageService),
                  const SizedBox(width: 24),
                  
                  // CTA Button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      _getValue({
                        'pt': 'Começar Grátis',
                        'en': 'Start Free',
                        'es': 'Empezar Gratis',
                        'ja': '無料で始める',
                      }, languageService),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton(BuildContext context, String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        overlayColor: Colors.white.withOpacity(0.1),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, LanguageService languageService) {
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            _getLanguageFlag(languageService.currentLanguageCode),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      onSelected: (String languageCode) {
        languageService.setLanguage(languageCode);
      },
      itemBuilder: (BuildContext context) {
        return LanguageService.languageNames.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Text(
                  _getLanguageFlag(entry.key),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(entry.value),
                if (entry.key == languageService.currentLanguageCode)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 16),
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'pt':
        return '🇧🇷';
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'ja':
        return '🇯🇵';
      default:
        return '🌍';
    }
  }

  void _scrollToSection(String section) {
    double offset = 0;
    
    switch (section) {
      case 'features':
        offset = 900; // Features section (Powerful Features)
        break;
      case 'pricing':
        offset = 2800; // Pricing section  
        break;
      case 'contact':
        offset = 3600; // Footer/Contact section
        break;
    }
    
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}