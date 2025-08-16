import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';

class CommerceDisclosurePage extends StatelessWidget {
  const CommerceDisclosurePage({super.key});

  String _getValue(Map<String, String> values, LanguageService languageService) {
    return values[languageService.currentLanguageCode] ?? values['pt'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getPageTitle(languageService)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, languageService),
                
                const SizedBox(height: 32),
                
                // Japanese Section (Always first - Legal requirement)
                _buildJapaneseSection(context),
                
                const SizedBox(height: 48),
                
                // Multilingual sections based on current language
                if (languageService.currentLanguageCode != 'ja')
                  _buildTranslatedSection(context, languageService),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPageTitle(LanguageService languageService) {
    switch (languageService.currentLanguageCode) {
      case 'ja':
        return '特定商取引法に基づく表記';
      case 'en':
        return 'Legal Disclosure for Japan';
      case 'es':
        return 'Divulgación Legal para Japón';
      case 'pt':
      default:
        return 'Divulgação Legal para o Japão';
    }
  }

  Widget _buildHeader(BuildContext context, LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getValue({
            'pt': 'Informações Legais Obrigatórias',
            'en': 'Required Legal Information',
            'es': 'Información Legal Obligatoria',
            'ja': '法的に必要な情報',
          }, languageService),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          _getValue({
            'pt': 'Esta página contém informações obrigatórias conforme a Lei Japonesa de Transações Comerciais Específicas (特定商取引法).',
            'en': 'This page contains mandatory information under Japan\'s Act on Specified Commercial Transactions (特定商取引法).',
            'es': 'Esta página contiene información obligatoria bajo la Ley Japonesa de Transacciones Comerciales Específicas (特定商取引法).',
            'ja': 'このページには、特定商取引法に基づく表記として必要な情報を記載しています。',
          }, languageService),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildJapaneseSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '特定商取引法に基づく表記',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildJapaneseField('販売業者（氏名・名称）', 'VERSEE株式会社'),
            _buildJapaneseField('運営責任者', 'CEO 山田太郎'),
            _buildJapaneseField('所在地', '〒100-0001 東京都千代田区千代田1-1'),
            _buildJapaneseField('電話番号（日本語対応・受付時間）', '03-1234-5678（平日10:00〜18:00）'),
            _buildJapaneseField('メールアドレス', 'support@versee.jp'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('販売価格', '各商品ページまたは申込ページに税込価格を表示します。'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('商品代金以外の必要料金', 
              '・決済手数料（コンビニ支払い手数料など）\n'
              '・通信料等はお客様負担'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('お支払い方法', 
              'クレジットカード、Apple Pay、Google Pay、コンビニ払い、銀行振込'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('お支払い時期',
              'クレジットカード：ご注文時に即時決済\n'
              '銀行振込／コンビニ払い：ご注文日から3日以内にお支払い'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('引き渡し時期・サービス提供時期',
              'デジタル商品／サブスクリプション：決済完了後すぐにご利用可能'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('返品・交換・キャンセルについて',
              '＜お客様都合による返品・交換＞\n'
              'サブスクリプション：マイページからいつでもキャンセル可能（次回更新日前日まで）\n\n'
              '＜不良品・役務不備の場合＞\n'
              'サポート窓口へご連絡ください。当社負担で返金いたします。'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('定期購入・継続課金',
              '更新間隔：月次／年次\n'
              '最低契約期間：なし\n'
              '解約方法：マイページ＞アカウント設定からいつでも解約可能（次回更新日前日まで）'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('動作環境（ソフトウェア）',
              '対応OS：iOS 13以上、Android 7以上\n'
              'ブラウザ：最新のChrome、Safari、Firefox、Edge'),
            
            const SizedBox(height: 16),
            
            _buildJapaneseField('お問い合わせ窓口',
              'E-mail：support@versee.jp\n'
              'TEL：03-1234-5678（平日10:00〜18:00）'),
          ],
        ),
      ),
    );
  }

  Widget _buildJapaneseField(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslatedSection(BuildContext context, LanguageService languageService) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getValue({
                'pt': 'Informações Obrigatórias (Lei Japonesa)',
                'en': 'Mandatory Information (Japanese Law)',
                'es': 'Información Obligatoria (Ley Japonesa)',
                'ja': '特定商取引法に基づく表記',
              }, languageService),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildTranslatedField(context, languageService, 'fornecedor', 'Supplier', 'Proveedor', 'VERSEE Corporation'),
            _buildTranslatedField(context, languageService, 'responsavel', 'Responsible', 'Responsable', 'CEO Yamada Taro'),
            _buildTranslatedField(context, languageService, 'endereco', 'Address', 'Dirección', '〒100-0001 Tokyo, Chiyoda-ku, Chiyoda 1-1'),
            _buildTranslatedField(context, languageService, 'telefone', 'Phone', 'Teléfono', '03-1234-5678 (Weekdays 10:00-18:00 JST)'),
            _buildTranslatedField(context, languageService, 'email', 'Email', 'Email', 'support@versee.jp'),
            
            const SizedBox(height: 16),
            
            _buildTranslatedField(context, languageService, 'precos', 'Prices', 'Precios', 
              _getValue({
                'pt': 'Preços exibidos em cada página de produto (impostos inclusos)',
                'en': 'Prices displayed on each product page (taxes included)',
                'es': 'Precios mostrados en cada página de producto (impuestos incluidos)',
                'ja': '各商品ページに税込価格を表示',
              }, languageService)),
            
            const SizedBox(height: 16),
            
            _buildTranslatedField(context, languageService, 'taxas', 'Other Fees', 'Otras Tarifas',
              _getValue({
                'pt': '• Taxas de processamento de pagamento\n• Custos de comunicação por conta do cliente',
                'en': '• Payment processing fees\n• Communication costs borne by customer',
                'es': '• Tarifas de procesamiento de pagos\n• Costos de comunicación a cargo del cliente',
                'ja': '決済手数料、通信料等',
              }, languageService)),
            
            const SizedBox(height: 16),
            
            _buildTranslatedField(context, languageService, 'pagamento', 'Payment Methods', 'Métodos de Pago',
              _getValue({
                'pt': 'Cartão de crédito, Apple Pay, Google Pay, transferência bancária',
                'en': 'Credit card, Apple Pay, Google Pay, bank transfer',
                'es': 'Tarjeta de crédito, Apple Pay, Google Pay, transferencia bancaria',
                'ja': 'クレジットカード、Apple Pay、Google Pay、銀行振込',
              }, languageService)),
            
            const SizedBox(height: 16),
            
            _buildTranslatedField(context, languageService, 'entrega', 'Service Delivery', 'Entrega del Servicio',
              _getValue({
                'pt': 'Produtos digitais/assinaturas: disponível imediatamente após pagamento',
                'en': 'Digital products/subscriptions: available immediately after payment',
                'es': 'Productos digitales/suscripciones: disponible inmediatamente después del pago',
                'ja': 'デジタル商品：決済完了後すぐに利用可能',
              }, languageService)),
            
            const SizedBox(height: 16),
            
            _buildTranslatedField(context, languageService, 'reembolso', 'Returns/Cancellations', 'Devoluciones/Cancelaciones',
              _getValue({
                'pt': 'Assinaturas: cancelamento a qualquer momento na conta (até véspera da renovação)\nDefeitos de serviço: reembolso com nossos custos',
                'en': 'Subscriptions: cancel anytime in account (until day before renewal)\nService defects: refund at our expense',
                'es': 'Suscripciones: cancelar en cualquier momento en la cuenta (hasta el día anterior a la renovación)\nDefectos de servicio: reembolso a nuestro cargo',
                'ja': 'サブスクリプション：マイページからいつでもキャンセル可能',
              }, languageService)),
            
            const SizedBox(height: 16),
            
            _buildTranslatedField(context, languageService, 'contato', 'Contact', 'Contacto',
              'support@versee.jp | 03-1234-5678 (10:00-18:00 JST)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslatedField(BuildContext context, LanguageService languageService, 
      String ptLabel, String enLabel, String esLabel, String content) {
    
    final label = _getValue({
      'pt': ptLabel,
      'en': enLabel,
      'es': esLabel,
      'ja': ptLabel, // Fallback to Portuguese for Japanese
    }, languageService);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}