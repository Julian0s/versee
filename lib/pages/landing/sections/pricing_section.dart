import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

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
              
              const SizedBox(height: 60),
              
              // Pricing Cards
              _buildPricingCards(context, languageService, isDesktop, isTablet),
              
              const SizedBox(height: 60),
              
              // FAQ Section
              _buildFAQSection(context, languageService, isDesktop),
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
            'pt': 'Planos Simples e Transparentes',
            'en': 'Simple and Transparent Plans',
            'es': 'Planes Simples y Transparentes',
            'ja': 'シンプルで透明性のあるプラン',
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
            'pt': 'Comece gratuitamente e evolua conforme sua igreja cresce',
            'en': 'Start free and evolve as your church grows',
            'es': 'Comienza gratis y evoluciona conforme tu iglesia crece',
            'ja': '無料で始めて、教会の成長に合わせて進化',
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

  Widget _buildPricingCards(BuildContext context, LanguageService languageService, bool isDesktop, bool isTablet) {
    final plans = [
      _PricingPlan(
        nameValues: {
          'pt': 'Starter',
          'en': 'Starter',
          'es': 'Starter',
          'ja': 'スターター',
        },
        priceValues: {
          'pt': 'R\$ 0',
          'en': '\$0',
          'es': '\$0',
          'ja': '¥0',
        },
        periodValues: {
          'pt': '/mês',
          'en': '/month',
          'es': '/mes',
          'ja': '/月',
        },
        descriptionValues: {
          'pt': 'Perfeito para começar',
          'en': 'Perfect to get started',
          'es': 'Perfecto para empezar',
          'ja': '始めるのに最適',
        },
        featuresValues: [
          {
            'pt': 'Até 5 apresentações',
            'en': 'Up to 5 presentations',
            'es': 'Hasta 5 presentaciones',
            'ja': '最大5つのプレゼンテーション',
          },
          {
            'pt': 'Versículos básicos',
            'en': 'Basic Bible verses',
            'es': 'Versículos básicos',
            'ja': '基本的な聖書の節',
          },
          {
            'pt': 'Slides simples',
            'en': 'Simple slides',
            'es': 'Diapositivas simples',
            'ja': 'シンプルなスライド',
          },
          {
            'pt': 'Projeção básica',
            'en': 'Basic projection',
            'es': 'Proyección básica',
            'ja': '基本投影',
          },
          {
            'pt': 'Suporte por email',
            'en': 'Email support',
            'es': 'Soporte por correo',
            'ja': 'メールサポート',
          },
        ],
        enabledFeatures: [0, 1, 2, 3, 4],
        buttonTextValues: {
          'pt': 'Começar Grátis',
          'en': 'Start Free',
          'es': 'Empezar Gratis',
          'ja': '無料で始める',
        },
        isPopular: false,
        onPressed: () => Navigator.of(context).pushNamed('/auth'),
      ),
      _PricingPlan(
        nameValues: {
          'pt': 'Standard',
          'en': 'Standard',
          'es': 'Standard',
          'ja': 'スタンダード',
        },
        priceValues: {
          'pt': 'R\$ 29',
          'en': '\$15',
          'es': '\$15',
          'ja': '¥1500',
        },
        periodValues: {
          'pt': '/mês',
          'en': '/month',
          'es': '/mes',
          'ja': '/月',
        },
        descriptionValues: {
          'pt': 'Para igrejas em crescimento',
          'en': 'For growing churches',
          'es': 'Para iglesias en crecimiento',
          'ja': '成長する教会のために',
        },
        featuresValues: [
          {
            'pt': 'Apresentações ilimitadas',
            'en': 'Unlimited presentations',
            'es': 'Presentaciones ilimitadas',
            'ja': '無制限のプレゼンテーション',
          },
          {
            'pt': 'Múltiplas versões bíblicas',
            'en': 'Multiple Bible versions',
            'es': 'Múltiples versiones bíblicas',
            'ja': '複数の聖書バージョン',
          },
          {
            'pt': 'Slides avançados',
            'en': 'Advanced slides',
            'es': 'Diapositivas avanzadas',
            'ja': '高度なスライド',
          },
          {
            'pt': 'Projeção em segunda tela',
            'en': 'Second screen projection',
            'es': 'Proyección en segunda pantalla',
            'ja': 'セカンドスクリーン投影',
          },
          {
            'pt': 'Backgrounds personalizados',
            'en': 'Custom backgrounds',
            'es': 'Fondos personalizados',
            'ja': 'カスタム背景',
          },
          {
            'pt': 'Sincronização na nuvem',
            'en': 'Cloud synchronization',
            'es': 'Sincronización en la nuvem',
            'ja': 'クラウド同期',
          },
          {
            'pt': 'Suporte prioritário',
            'en': 'Priority support',
            'es': 'Soporte prioritario',
            'ja': '優先サポート',
          },
        ],
        enabledFeatures: [0, 1, 2, 3, 4, 5, 6],
        buttonTextValues: {
          'pt': 'Assinar Standard',
          'en': 'Subscribe Standard',
          'es': 'Suscribir Standard',
          'ja': 'スタンダード購読',
        },
        isPopular: true,
        onPressed: () => Navigator.of(context).pushNamed('/auth'),
      ),
      _PricingPlan(
        nameValues: {
          'pt': 'Advanced',
          'en': 'Advanced',
          'es': 'Advanced',
          'ja': 'アドバンスド',
        },
        priceValues: {
          'pt': 'R\$ 59',
          'en': '\$29',
          'es': '\$29',
          'ja': '¥2900',
        },
        periodValues: {
          'pt': '/mês',
          'en': '/month',
          'es': '/mes',
          'ja': '/月',
        },
        descriptionValues: {
          'pt': 'Para igrejas grandes',
          'en': 'For large churches',
          'es': 'Para iglesias grandes',
          'ja': '大きな教会のために',
        },
        featuresValues: [
          {
            'pt': 'Tudo do Standard',
            'en': 'Everything from Standard',
            'es': 'Todo de Standard',
            'ja': 'スタンダードのすべて',
          },
          {
            'pt': 'Múltiplas telas simultâneas',
            'en': 'Multiple simultaneous screens',
            'es': 'Múltiples pantallas simultáneas',
            'ja': '複数の同時スクリーン',
          },
          {
            'pt': 'Gestão de usuários',
            'en': 'User management',
            'es': 'Gestión de usuarios',
            'ja': 'ユーザー管理',
          },
          {
            'pt': 'Temas personalizáveis',
            'en': 'Customizable themes',
            'es': 'Temas personalizables',
            'ja': 'カスタマイズ可能なテーマ',
          },
          {
            'pt': 'API personalizada',
            'en': 'Custom API',
            'es': 'API personalizada',
            'ja': 'カスタムAPI',
          },
          {
            'pt': 'Relatórios avançados',
            'en': 'Advanced reports',
            'es': 'Informes avanzados',
            'ja': '高度なレポート',
          },
          {
            'pt': 'Suporte dedicado',
            'en': 'Dedicated support',
            'es': 'Soporte dedicado',
            'ja': '専用サポート',
          },
          {
            'pt': 'Treinamento incluído',
            'en': 'Training included',
            'es': 'Entrenamiento incluido',
            'ja': 'トレーニング込み',
          },
        ],
        enabledFeatures: [0, 1, 2, 3, 4, 5, 6, 7],
        buttonTextValues: {
          'pt': 'Falar com Vendas',
          'en': 'Contact Sales',
          'es': 'Contactar Ventas',
          'ja': '営業に問い合わせ',
        },
        isPopular: false,
        onPressed: () => _contactSales(context, languageService),
      ),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: plans
            .map((plan) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildPricingCard(context, languageService, plan),
                  ),
                ))
            .toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          _buildPricingCard(context, languageService, plans[1]), // Popular first on mobile
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: _buildPricingCard(context, languageService, plans[0]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: _buildPricingCard(context, languageService, plans[2]),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildPricingCard(context, languageService, plans[1]), // Popular first on mobile
          const SizedBox(height: 30),
          _buildPricingCard(context, languageService, plans[0]),
          const SizedBox(height: 30),
          _buildPricingCard(context, languageService, plans[2]),
        ],
      );
    }
  }

  Widget _buildPricingCard(BuildContext context, LanguageService languageService, _PricingPlan plan) {
    return Column(
      children: [
        // Popular badge above the card
        if (plan.isPopular)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getValue({
                'pt': 'MAIS POPULAR',
                'en': 'MOST POPULAR',
                'es': 'MÁS POPULAR',
                'ja': '最も人気',
              }, languageService),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          )
        else
          const SizedBox(height: 32), // Space to keep alignment
        
        // Card container
        Container(
          height: 600, // Fixed height for consistency
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: plan.isPopular
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: plan.isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(plan.isPopular ? 0.1 : 0.05),
                blurRadius: plan.isPopular ? 30 : 20,
                offset: Offset(0, plan.isPopular ? 15 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan name
              Text(
                _getValue(plan.nameValues, languageService),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                _getValue(plan.descriptionValues, languageService),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getValue(plan.priceValues, languageService),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getValue(plan.periodValues, languageService),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Features - Original style
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plan.featuresValues
                      .map((featureValues) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getValue(featureValues, languageService),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // CTA Button
              SizedBox(
                width: double.infinity,
                child: plan.isPopular
                    ? ElevatedButton(
                        onPressed: plan.onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _getValue(plan.buttonTextValues, languageService),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: plan.onPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _getValue(plan.buttonTextValues, languageService),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection(BuildContext context, LanguageService languageService, bool isDesktop) {
    final faqs = [
      _FAQ(
        questionValues: {
          'pt': 'Posso usar o VERSEE gratuitamente?',
          'en': 'Can I use VERSEE for free?',
          'es': '¿Puedo usar VERSEE gratis?',
          'ja': 'VERSEEを無料で使用できますか？',
        },
        answerValues: {
          'pt': 'Sim! O plano gratuito inclui recursos básicos suficientes para igrejas pequenas começarem. Você pode fazer upgrade a qualquer momento.',
          'en': 'Yes! The free plan includes basic features sufficient for small churches to get started. You can upgrade at any time.',
          'es': '¡Sí! El plan gratuito incluye características básicas suficientes para que las iglesias pequeñas comiencen. Puedes actualizar en cualquier momento.',
          'ja': 'はい！無料プランには、小さな教会が始めるのに十分な基本機能が含まれています。いつでもアップグレードできます。',
        },
      ),
      _FAQ(
        questionValues: {
          'pt': 'Como funciona a projeção em segunda tela?',
          'en': 'How does second screen projection work?',
          'es': '¿Cómo funciona la proyección en segunda pantalla?',
          'ja': 'セカンドスクリーン投影はどのように機能しますか？',
        },
        answerValues: {
          'pt': 'Conecte um projetor ou TV externa ao seu dispositivo. O VERSEE detecta automaticamente e permite controlar o que é exibido na tela de projeção.',
          'en': 'Connect a projector or external TV to your device. VERSEE automatically detects and allows you to control what is displayed on the projection screen.',
          'es': 'Conecta un proyector o TV externa a tu dispositivo. VERSEE detecta automáticamente y te permite controlar lo que se muestra en la pantalla de proyección.',
          'ja': 'プロジェクターまたは外部テレビをデバイスに接続します。VERSEEは自動的に検出し、投影スクリーンに表示される内容を制御できます。',
        },
      ),
      _FAQ(
        questionValues: {
          'pt': 'Preciso de internet para usar?',
          'en': 'Do I need internet to use it?',
          'es': '¿Necesito internet para usar?',
          'ja': '使用にはインターネットが必要ですか？',
        },
        answerValues: {
          'pt': 'Não para funcionalidades básicas. Os versículos e slides ficam salvos localmente. A internet é necessária apenas para sincronização e backup.',
          'en': 'Not for basic functionality. Verses and slides are saved locally. Internet is only needed for synchronization and backup.',
          'es': 'No para funcionalidades básicas. Los versículos y diapositivas se guardan localmente. Internet solo es necesario para sincronización y respaldo.',
          'ja': '基本機能には必要ありません。節とスライドはローカルに保存されます。インターネットは同期とバックアップにのみ必要です。',
        },
      ),
      _FAQ(
        questionValues: {
          'pt': 'Posso cancelar minha assinatura a qualquer momento?',
          'en': 'Can I cancel my subscription at any time?',
          'es': '¿Puedo cancelar mi suscripción en cualquier momento?',
          'ja': 'いつでも購読をキャンセルできますか？',
        },
        answerValues: {
          'pt': 'Sim, você pode cancelar a qualquer momento. Não há taxas de cancelamento e você continuará tendo acesso até o final do período pago.',
          'en': 'Yes, you can cancel at any time. There are no cancellation fees and you will continue to have access until the end of the paid period.',
          'es': 'Sí, puedes cancelar en cualquier momento. No hay tarifas de cancelación y seguirás teniendo acceso hasta el final del período pagado.',
          'ja': 'はい、いつでもキャンセルできます。キャンセル料はありませんし、支払い期間が終了するまでアクセスできます。',
        },
      ),
    ];

    return Column(
      children: [
        Text(
          _getValue({
            'pt': 'Perguntas Frequentes',
            'en': 'Frequently Asked Questions',
            'es': 'Preguntas Frecuentes',
            'ja': 'よくある質問',
          }, languageService),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 40),
        
        Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
          child: Column(
            children: faqs
                .map((faq) => _buildFAQItem(context, languageService, faq))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, LanguageService languageService, _FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          _getValue(faq.questionValues, languageService),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              _getValue(faq.answerValues, languageService),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _contactSales(BuildContext context, LanguageService languageService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getValue({
          'pt': 'Entre em contato: vendas@versee.app',
          'en': 'Contact us: sales@versee.app',
          'es': 'Contáctanos: ventas@versee.app',
          'ja': 'お問い合わせ: sales@versee.app',
        }, languageService)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _PricingPlan {
  final Map<String, String> nameValues;
  final Map<String, String> priceValues;
  final Map<String, String> periodValues;
  final Map<String, String> descriptionValues;
  final List<Map<String, String>> featuresValues;
  final List<int> enabledFeatures;
  final Map<String, String> buttonTextValues;
  final bool isPopular;
  final VoidCallback onPressed;

  _PricingPlan({
    required this.nameValues,
    required this.priceValues,
    required this.periodValues,
    required this.descriptionValues,
    required this.featuresValues,
    required this.enabledFeatures,
    required this.buttonTextValues,
    required this.isPopular,
    required this.onPressed,
  });
}

class _FAQ {
  final Map<String, String> questionValues;
  final Map<String, String> answerValues;

  _FAQ({required this.questionValues, required this.answerValues});
}