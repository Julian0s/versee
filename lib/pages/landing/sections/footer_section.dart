import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

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
            vertical: 60,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              // CTA Section
              _buildCTASection(context, languageService),
              
              const SizedBox(height: 60),
              
              // Footer Links
              _buildFooterContent(context, languageService, isDesktop, isTablet),
              
              const SizedBox(height: 40),
              
              // Copyright
              _buildCopyright(context, languageService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCTASection(BuildContext context, LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            _getValue({
              'pt': 'Pronto para Transformar suas Apresentações?',
              'en': 'Ready to Transform Your Presentations?',
              'es': '¿Listo para Transformar tus Presentaciones?',
              'ja': 'プレゼンテーションを変革する準備はできましたか？',
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
              'pt': 'Junte-se a centenas de igrejas que já usam o VERSEE',
              'en': 'Join hundreds of churches already using VERSEE',
              'es': 'Únete a cientos de iglesias que ya usan VERSEE',
              'ja': '既にVERSEEを使用している数百の教会に参加してください',
            }, languageService),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getValue({
                  'pt': 'Sem cartão de crédito • Configuração em 2 minutos',
                  'en': 'No credit card • 2-minute setup',
                  'es': 'Sin tarjeta de crédito • Configuración en 2 minutos',
                  'ja': 'クレジットカード不要 • 2分で設定完了',
                }, languageService),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterContent(BuildContext context, LanguageService languageService, bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and description
          Expanded(
            flex: 2,
            child: _buildCompanyInfo(context, languageService),
          ),
          
          // Product links
          Expanded(
            child: _buildLinkColumn(
              context,
              languageService,
              {
                'pt': 'Produto',
                'en': 'Product',
                'es': 'Producto',
                'ja': '製品',
              },
              [
                _FooterLink({
                  'pt': 'Recursos',
                  'en': 'Features',
                  'es': 'Recursos',
                  'ja': '機能',
                }, () {}),
                _FooterLink({
                  'pt': 'Preços',
                  'en': 'Pricing',
                  'es': 'Precios',
                  'ja': '料金',
                }, () {}),
                _FooterLink({
                  'pt': 'Demonstração',
                  'en': 'Demo',
                  'es': 'Demostración',
                  'ja': 'デモ',
                }, () {}),
                _FooterLink({
                  'pt': 'Atualizações',
                  'en': 'Updates',
                  'es': 'Actualizaciones',
                  'ja': 'アップデート',
                }, () {}),
              ],
            ),
          ),
          
          // Support links
          Expanded(
            child: _buildLinkColumn(
              context,
              languageService,
              {
                'pt': 'Suporte',
                'en': 'Support',
                'es': 'Soporte',
                'ja': 'サポート',
              },
              [
                _FooterLink({
                  'pt': 'Central de Ajuda',
                  'en': 'Help Center',
                  'es': 'Centro de Ayuda',
                  'ja': 'ヘルプセンター',
                }, () {}),
                _FooterLink({
                  'pt': 'Documentação',
                  'en': 'Documentation',
                  'es': 'Documentación',
                  'ja': 'ドキュメント',
                }, () {}),
                _FooterLink({
                  'pt': 'Contato',
                  'en': 'Contact',
                  'es': 'Contacto',
                  'ja': 'お問い合わせ',
                }, () {}),
                _FooterLink({
                  'pt': 'Status',
                  'en': 'Status',
                  'es': 'Estado',
                  'ja': 'ステータス',
                }, () {}),
              ],
            ),
          ),
          
          // Company links
          Expanded(
            child: _buildLinkColumn(
              context,
              languageService,
              {
                'pt': 'Empresa',
                'en': 'Company',
                'es': 'Empresa',
                'ja': '会社',
              },
              [
                _FooterLink({
                  'pt': 'Sobre Nós',
                  'en': 'About Us',
                  'es': 'Acerca de Nosotros',
                  'ja': '私たちについて',
                }, () {}),
                _FooterLink({
                  'pt': 'Blog',
                  'en': 'Blog',
                  'es': 'Blog',
                  'ja': 'ブログ',
                }, () {}),
                _FooterLink({
                  'pt': 'Carreiras',
                  'en': 'Careers',
                  'es': 'Carreras',
                  'ja': 'キャリア',
                }, () {}),
                _FooterLink({
                  'pt': 'Parceiros',
                  'en': 'Partners',
                  'es': 'Socios',
                  'ja': 'パートナー',
                }, () {}),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyInfo(context, languageService),
          
          const SizedBox(height: 40),
          
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLinkColumn(
                    context,
                    languageService,
                    {
                      'pt': 'Produto',
                      'en': 'Product',
                      'es': 'Producto',
                      'ja': '製品',
                    },
                    [
                      _FooterLink({
                        'pt': 'Recursos',
                        'en': 'Features',
                        'es': 'Recursos',
                        'ja': '機能',
                      }, () {}),
                      _FooterLink({
                        'pt': 'Preços',
                        'en': 'Pricing',
                        'es': 'Precios',
                        'ja': '料金',
                      }, () {}),
                      _FooterLink({
                        'pt': 'Demonstração',
                        'en': 'Demo',
                        'es': 'Demostración',
                        'ja': 'デモ',
                      }, () {}),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildLinkColumn(
                    context,
                    languageService,
                    {
                      'pt': 'Suporte',
                      'en': 'Support',
                      'es': 'Soporte',
                      'ja': 'サポート',
                    },
                    [
                      _FooterLink({
                        'pt': 'Central de Ajuda',
                        'en': 'Help Center',
                        'es': 'Centro de Ayuda',
                        'ja': 'ヘルプセンター',
                      }, () {}),
                      _FooterLink({
                        'pt': 'Contato',
                        'en': 'Contact',
                        'es': 'Contacto',
                        'ja': 'お問い合わせ',
                      }, () {}),
                      _FooterLink({
                        'pt': 'Status',
                        'en': 'Status',
                        'es': 'Estado',
                        'ja': 'ステータス',
                      }, () {}),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLinkColumn(
                  context,
                  languageService,
                  {
                    'pt': 'Links Úteis',
                    'en': 'Useful Links',
                    'es': 'Enlaces Útiles',
                    'ja': '便利なリンク',
                  },
                  [
                    _FooterLink({
                      'pt': 'Recursos',
                      'en': 'Features',
                      'es': 'Recursos',
                      'ja': '機能',
                    }, () {}),
                    _FooterLink({
                      'pt': 'Preços',
                      'en': 'Pricing',
                      'es': 'Precios',
                      'ja': '料金',
                    }, () {}),
                    _FooterLink({
                      'pt': 'Suporte',
                      'en': 'Support',
                      'es': 'Soporte',
                      'ja': 'サポート',
                    }, () {}),
                    _FooterLink({
                      'pt': 'Contato',
                      'en': 'Contact',
                      'es': 'Contacto',
                      'ja': 'お問い合わせ',
                    }, () {}),
                  ],
                ),
              ],
            ),
        ],
      );
    }
  }

  Widget _buildCompanyInfo(BuildContext context, LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Row(
          children: [
            Icon(
              Icons.present_to_all,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'VERSEE',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Description
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            _getValue({
              'pt': 'Transformando apresentações de cultos com tecnologia moderna e interface intuitiva.',
              'en': 'Transforming worship presentations with modern technology and intuitive interface.',
              'es': 'Transformando presentaciones de culto con tecnología moderna e interfaz intuitiva.',
              'ja': '現代技術と直感的なインターフェースで礼拝プレゼンテーションを変革しています。',
            }, languageService),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Social links
        Row(
          children: [
            _buildSocialButton(
              context,
              Icons.mail,
              () => _openEmail(context, languageService),
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              context,
              Icons.phone,
              () => _openPhone(context, languageService),
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              context,
              Icons.web,
              () => _openWebsite(context, languageService),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkColumn(
    BuildContext context,
    LanguageService languageService,
    Map<String, String> titleValues,
    List<_FooterLink> links,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getValue(titleValues, languageService),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: link.onPressed,
            child: Text(
              _getValue(link.textValues, languageService),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildCopyright(BuildContext context, LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getValue({
              'pt': '© ${DateTime.now().year} VERSEE. Todos os direitos reservados.',
              'en': '© ${DateTime.now().year} VERSEE. All rights reserved.',
              'es': '© ${DateTime.now().year} VERSEE. Todos los derechos reservados.',
              'ja': '© ${DateTime.now().year} VERSEE. すべての権利を保有しています。',
            }, languageService),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          Row(
            children: [
              TextButton(
                onPressed: () => _showPrivacyPolicy(context, languageService),
                child: Text(
                  _getValue({
                    'pt': 'Privacidade',
                    'en': 'Privacy',
                    'es': 'Privacidad',
                    'ja': 'プライバシー',
                  }, languageService),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => _showTerms(context, languageService),
                child: Text(
                  _getValue({
                    'pt': 'Termos',
                    'en': 'Terms',
                    'es': 'Términos',
                    'ja': '利用規約',
                  }, languageService),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/legal'),
                child: Text(
                  _getValue({
                    'pt': 'Informações Legais',
                    'en': 'Legal Information',
                    'es': 'Información Legal',
                    'ja': '特定商取引法に基づく表記',
                  }, languageService),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openEmail(BuildContext context, LanguageService languageService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getValue({
          'pt': 'Email: contato@versee.app',
          'en': 'Email: contact@versee.app',
          'es': 'Email: contacto@versee.app',
          'ja': 'Email: contact@versee.app',
        }, languageService)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openPhone(BuildContext context, LanguageService languageService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getValue({
          'pt': 'Telefone: (11) 99999-9999',
          'en': 'Phone: +55 (11) 99999-9999',
          'es': 'Teléfono: +55 (11) 99999-9999',
          'ja': '電話: +55 (11) 99999-9999',
        }, languageService)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openWebsite(BuildContext context, LanguageService languageService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getValue({
          'pt': 'Site: www.versee.app',
          'en': 'Website: www.versee.app',
          'es': 'Sitio web: www.versee.app',
          'ja': 'ウェブサイト: www.versee.app',
        }, languageService)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getValue({
          'pt': 'Política de Privacidade',
          'en': 'Privacy Policy',
          'es': 'Política de Privacidad',
          'ja': 'プライバシーポリシー',
        }, languageService)),
        content: Text(_getValue({
          'pt': 'Política de privacidade em desenvolvimento.',
          'en': 'Privacy policy under development.',
          'es': 'Política de privacidad en desarrollo.',
          'ja': 'プライバシーポリシーは開発中です。',
        }, languageService)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getValue({
              'pt': 'Fechar',
              'en': 'Close',
              'es': 'Cerrar',
              'ja': '閉じる',
            }, languageService)),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getValue({
          'pt': 'Termos de Uso',
          'en': 'Terms of Use',
          'es': 'Términos de Uso',
          'ja': '利用規約',
        }, languageService)),
        content: Text(_getValue({
          'pt': 'Termos de uso em desenvolvimento.',
          'en': 'Terms of use under development.',
          'es': 'Términos de uso en desarrollo.',
          'ja': '利用規約は開発中です。',
        }, languageService)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getValue({
              'pt': 'Fechar',
              'en': 'Close',
              'es': 'Cerrar',
              'ja': '閉じる',
            }, languageService)),
          ),
        ],
      ),
    );
  }
}

class _FooterLink {
  final Map<String, String> textValues;
  final VoidCallback onPressed;

  _FooterLink(this.textValues, this.onPressed);
}