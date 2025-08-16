import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  String _getValue(Map<String, String> values, LanguageService languageService) {
    return values[languageService.currentLanguageCode] ?? values['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, languageService),
                _buildLegalContent(context, languageService),
                _buildFooter(context, languageService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          // Logo
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            child: SvgPicture.asset(
              'assets/images/versee_logo_header.svg',
              height: 40,
            ),
          ),
          
          const Spacer(),
          
          // Back to Home button
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            child: Text(
              _getValue({
                'pt': 'Voltar ao Início',
                'en': 'Back to Home',
                'es': 'Volver al Inicio',
                'ja': 'ホームに戻る',
              }, languageService),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalContent(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 1200 : double.infinity,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          _buildPageTitle(context, languageService),
          
          const SizedBox(height: 60),
          
          // Legal Information Cards
          _buildLegalCards(context, languageService, isDesktop, isTablet),
        ],
      ),
    );
  }

  Widget _buildPageTitle(BuildContext context, LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _getValue({
            'pt': 'Informações Legais',
            'en': 'Legal Information',
            'es': 'Información Legal',
            'ja': '特定商取引法に基づく表記',
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
            'pt': 'Informações obrigatórias conforme a Lei de Transações Comerciais Específicas do Japão',
            'en': 'Required information under Japan\'s Specified Commercial Transactions Act',
            'es': 'Información requerida bajo la Ley de Transacciones Comerciales Específicas de Japón',
            'ja': 'デジタルサービス：VERSEE',
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

  Widget _buildLegalCards(BuildContext context, LanguageService languageService, bool isDesktop, bool isTablet) {
    final legalSections = _getLegalSections(languageService);
    
    return Column(
      children: legalSections
          .map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _buildLegalCard(context, languageService, section),
              ))
          .toList(),
    );
  }

  Widget _buildLegalCard(BuildContext context, LanguageService languageService, _LegalSection section) {
    return Container(
      width: double.infinity,
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
        children: [
          // Section Title
          Text(
            _getValue(section.titleValues, languageService),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Section Content
          ...section.contentItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.labelValues.isNotEmpty) ...[
                      Text(
                        _getValue(item.labelValues, languageService),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _getValue(item.contentValues, languageService),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<_LegalSection> _getLegalSections(LanguageService languageService) {
    return [
      _LegalSection(
        titleValues: {
          'pt': 'Informações da Empresa',
          'en': 'Company Information',
          'es': 'Información de la Empresa',
          'ja': '販売業者情報',
        },
        contentItems: [
          _LegalContentItem(
            labelValues: {
              'pt': 'Vendedor (Nome/Razão Social)',
              'en': 'Vendor (Name/Trade Name)',
              'es': 'Vendedor (Nombre/Razón Social)',
              'ja': '販売業者（氏名・名称）',
            },
            contentValues: {
              'pt': 'Feltz Alexandre (Empresário Individual)\n※Endereço e número de telefone serão divulgados mediante solicitação.',
              'en': 'Feltz Alexandre (Sole Proprietor)\n※Address and phone number will be disclosed upon request.',
              'es': 'Feltz Alexandre (Empresario Individual)\n※Dirección y número de teléfono serán divulgados bajo solicitud.',
              'ja': 'フェルツ アレシャンドレ（個人事業主）\n※住所・電話番号は請求があった場合に遅滞なく開示いたします。',
            },
          ),
          _LegalContentItem(
            labelValues: {
              'pt': 'Responsável pela Operação',
              'en': 'Person in Charge',
              'es': 'Responsable de la Operación',
              'ja': '運営責任者',
            },
            contentValues: {
              'pt': 'Feltz Alexandre',
              'en': 'Feltz Alexandre',
              'es': 'Feltz Alexandre',
              'ja': 'フェルツ アレシャンドレ',
            },
          ),
          _LegalContentItem(
            labelValues: {
              'pt': 'E-mail',
              'en': 'Email',
              'es': 'Correo Electrónico',
              'ja': 'メールアドレス',
            },
            contentValues: {
              'pt': 'verseepresenter@gmail.com',
              'en': 'verseepresenter@gmail.com',
              'es': 'verseepresenter@gmail.com',
              'ja': 'verseepresenter@gmail.com',
            },
          ),
        ],
      ),
      _LegalSection(
        titleValues: {
          'pt': 'Preços e Planos',
          'en': 'Pricing and Plans',
          'es': 'Precios y Planes',
          'ja': '販売価格',
        },
        contentItems: [
          _LegalContentItem(
            labelValues: {
              'pt': 'Preços de Venda (todos incluem impostos)',
              'en': 'Sales Prices (tax included)',
              'es': 'Precios de Venta (impuestos incluidos)',
              'ja': '販売価格（すべて税込）',
            },
            contentValues: {
              'pt': 'Starter (Plano Gratuito): R\$ 0/mês – Funcionalidades básicas\n\nStandard (Recomendado): R\$ 29/mês – Funcionalidades aprimoradas\n\nAdvanced (Premium): R\$ 59/mês – Todas as funcionalidades premium',
              'en': 'Starter (Free Plan): \$0/month – Basic features\n\nStandard (Most Popular): \$15/month – Enhanced features\n\nAdvanced (Premium): \$29/month – All premium features',
              'es': 'Starter (Plan Gratuito): \$0/mes – Características básicas\n\nStandard (Más Popular): \$15/mes – Características mejoradas\n\nAdvanced (Premium): \$29/mes – Todas las características premium',
              'ja': 'スターター（無料プラン）：¥0／月 – 基本機能\n\nスタンダード（おすすめ）：¥2,200／月 – 機能強化版\n\nアドバンスド（プレミアム）：¥4,300／月 – 全てのプレミアム機能',
            },
          ),
          _LegalContentItem(
            labelValues: {
              'pt': 'Taxas Adicionais',
              'en': 'Additional Fees',
              'es': 'Tarifas Adicionales',
              'ja': '商品代金以外の必要料金',
            },
            contentValues: {
              'pt': 'Taxas de conexão à internet são de responsabilidade do cliente.',
              'en': 'Internet connection fees are the customer\'s responsibility.',
              'es': 'Las tarifas de conexión a internet son responsabilidad del cliente.',
              'ja': 'インターネット接続料金等はお客様負担となります。',
            },
          ),
        ],
      ),
      _LegalSection(
        titleValues: {
          'pt': 'Pagamento e Cobrança',
          'en': 'Payment and Billing',
          'es': 'Pago y Facturación',
          'ja': 'お支払いについて',
        },
        contentItems: [
          _LegalContentItem(
            labelValues: {
              'pt': 'Métodos de Pagamento',
              'en': 'Payment Methods',
              'es': 'Métodos de Pago',
              'ja': 'お支払い方法',
            },
            contentValues: {
              'pt': 'Cartão de Crédito (Visa, MasterCard, JCB, American Express)',
              'en': 'Credit Card (Visa, MasterCard, JCB, American Express)',
              'es': 'Tarjeta de Crédito (Visa, MasterCard, JCB, American Express)',
              'ja': 'クレジットカード（Visa、MasterCard、JCB、American Express）',
            },
          ),
          _LegalContentItem(
            labelValues: {
              'pt': 'Momento do Pagamento',
              'en': 'Payment Timing',
              'es': 'Momento del Pago',
              'ja': 'お支払い時期',
            },
            contentValues: {
              'pt': 'Cobrança no momento da assinatura, com renovação automática mensal na mesma data.',
              'en': 'Charged at the time of subscription, with automatic monthly renewal on the same date.',
              'es': 'Se cobra en el momento de la suscripción, con renovación automática mensual en la misma fecha.',
              'ja': 'お申し込み時に当月分を決済し、その後毎月同日に自動更新となります。',
            },
          ),
        ],
      ),
      _LegalSection(
        titleValues: {
          'pt': 'Fornecimento do Serviço',
          'en': 'Service Delivery',
          'es': 'Entrega del Servicio',
          'ja': 'サービス提供について',
        },
        contentItems: [
          _LegalContentItem(
            labelValues: {
              'pt': 'Início do Serviço',
              'en': 'Service Start Date',
              'es': 'Fecha de Inicio del Servicio',
              'ja': 'サービス提供時期',
            },
            contentValues: {
              'pt': 'Disponível imediatamente após a confirmação do pagamento (planos pagos) ou após o registro (plano gratuito).',
              'en': 'Available immediately after payment confirmation (paid plans) or upon registration (free plan).',
              'es': 'Disponible inmediatamente después de la confirmación del pago (planes pagos) o tras el registro (plan gratuito).',
              'ja': '決済完了後すぐに利用可能。無料プランは登録完了後すぐに利用可能。',
            },
          ),
          _LegalContentItem(
            labelValues: {
              'pt': 'Requisitos do Sistema',
              'en': 'System Requirements',
              'es': 'Requisitos del Sistema',
              'ja': '動作環境',
            },
            contentValues: {
              'pt': 'Smartphone com iOS 16+ ou Android 10+, Chrome/Safari/Edge atualizado, conexão estável com a internet.',
              'en': 'Smartphone with iOS 16+ or Android 10+, latest Chrome/Safari/Edge, stable internet connection.',
              'es': 'Smartphone con iOS 16+ o Android 10+, Chrome/Safari/Edge actualizado, conexión estable a internet.',
              'ja': 'iOS 16以降またはAndroid 10以降のスマートフォン、最新のChrome/Safari/Edge、安定したインターネット接続',
            },
          ),
        ],
      ),
      _LegalSection(
        titleValues: {
          'pt': 'Cancelamento e Reembolso',
          'en': 'Cancellation and Refunds',
          'es': 'Cancelación y Reembolsos',
          'ja': '返品・キャンセルについて',
        },
        contentItems: [
          _LegalContentItem(
            labelValues: {
              'pt': 'Política de Cancelamento',
              'en': 'Cancellation Policy',
              'es': 'Política de Cancelación',
              'ja': '解約について',
            },
            contentValues: {
              'pt': 'Reembolsos por iniciativa do cliente não estão disponíveis. O cancelamento pode ser feito a qualquer momento, até 24 horas antes da próxima renovação. O acesso permanece disponível até o final do período pago.',
              'en': 'Customer-initiated refunds are not available. Cancellation can be made anytime, up to 24 hours before the next renewal. Access remains available until the end of the paid period.',
              'es': 'Los reembolsos iniciados por el cliente no están disponibles. La cancelación se puede hacer en cualquier momento, hasta 24 horas antes de la próxima renovación. El acceso permanece disponible hasta el final del período pagado.',
              'ja': 'お客様都合による返金は不可。解約は次回更新日の24時間前まで可能で、解約後も残り期間は利用可能です。',
            },
          ),
          _LegalContentItem(
            labelValues: {
              'pt': 'Método de Cancelamento',
              'en': 'Cancellation Method',
              'es': 'Método de Cancelación',
              'ja': '解約方法',
            },
            contentValues: {
              'pt': 'Via Painel da Conta > Gerenciamento de Assinatura, pelo menos 24 horas antes da renovação.',
              'en': 'Via Account Panel > Subscription Management, at least 24 hours before renewal.',
              'es': 'A través del Panel de Cuenta > Gestión de Suscripción, al menos 24 horas antes de la renovación.',
              'ja': 'マイページ＞サブスクリプション管理より、更新日の24時間前までに解約',
            },
          ),
        ],
      ),
      _LegalSection(
        titleValues: {
          'pt': 'Contato',
          'en': 'Contact',
          'es': 'Contacto',
          'ja': 'お問い合わせ先',
        },
        contentItems: [
          _LegalContentItem(
            labelValues: {
              'pt': 'Informações de Contato',
              'en': 'Contact Information',
              'es': 'Información de Contacto',
              'ja': 'お問い合わせ',
            },
            contentValues: {
              'pt': 'E-mail: verseepresenter@gmail.com (Segunda-Sexta, 10:00–18:00 JST)\nNúmero de telefone divulgado mediante solicitação.',
              'en': 'Email: verseepresenter@gmail.com (Mon–Fri, 10:00–18:00 JST)\nPhone number disclosed upon request.',
              'es': 'Correo: verseepresenter@gmail.com (Lun–Vie, 10:00–18:00 JST)\nNúmero de teléfono divulgado bajo solicitud.',
              'ja': 'verseepresenter@gmail.com（平日10:00〜18:00 JST）\n電話番号は請求があった場合に遅滞なく開示します。',
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildFooter(BuildContext context, LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: Center(
        child: Text(
          _getValue({
            'pt': '© 2024 VERSEE. Todos os direitos reservados.',
            'en': '© 2024 VERSEE. All rights reserved.',
            'es': '© 2024 VERSEE. Todos los derechos reservados.',
            'ja': '© 2024 VERSEE. All rights reserved.',
          }, languageService),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final Map<String, String> titleValues;
  final List<_LegalContentItem> contentItems;

  _LegalSection({
    required this.titleValues,
    required this.contentItems,
  });
}

class _LegalContentItem {
  final Map<String, String> labelValues;
  final Map<String, String> contentValues;

  _LegalContentItem({
    required this.labelValues,
    required this.contentValues,
  });
}