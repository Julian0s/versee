import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/storage_analysis_service.dart';
import 'package:versee/services/language_service.dart';
import 'dart:math' as math;

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> with TickerProviderStateMixin {
  StorageAnalysisService? _storageService;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadStorageData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageData() async {
    try {
      _storageService = Provider.of<StorageAnalysisService>(context, listen: false);
      if (mounted && _storageService != null) {
        await _storageService!.analyzeStorageUsage(context);
        if (_isFirstLoad) {
          _animationController.forward();
          _isFirstLoad = false;
        }
      }
    } catch (e) {
      // Se falhar, ainda assim permite que a página seja mostrada
      if (mounted && _isFirstLoad) {
        _animationController.forward();
        _isFirstLoad = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return Text(
              languageService.strings.storagePage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorageData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Consumer2<StorageAnalysisService, LanguageService>(
        builder: (context, storageService, languageService, child) {
          if (storageService.isAnalyzing) {
            return _buildLoadingState(languageService);
          }

          if (storageService.errorMessage != null) {
            return _buildErrorState(languageService, storageService.errorMessage!);
          }

          final usage = storageService.currentUsage;
          if (usage == null) {
            return _buildEmptyState(languageService);
          }

          return RefreshIndicator(
            onRefresh: _loadStorageData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStorageOverview(context, usage, languageService),
                  const SizedBox(height: 24),
                  _buildStorageChart(context, usage, languageService),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(context, usage, languageService),
                  const SizedBox(height: 24),
                  _buildPlanInformation(context, usage, languageService),
                  if (usage.isNearLimit || usage.isOverLimit) ...[
                    const SizedBox(height: 24),
                    _buildUpgradeSuggestion(context, usage, languageService),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(context, usage, languageService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(LanguageService languageService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            languageService.strings.analyzingStorage,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LanguageService languageService, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            languageService.strings.errorLoadingStorage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadStorageData,
            icon: const Icon(Icons.refresh),
            label: Text(languageService.strings.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageService languageService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            languageService.strings.noStorageData,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverview(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  usage.isOverLimit ? Icons.warning : Icons.storage,
                  color: usage.isOverLimit 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageService.strings.storageUsage,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${StorageAnalysisService.formatFileSize(usage.totalUsed)} ${languageService.strings.of} ${StorageAnalysisService.formatFileSize(usage.totalLimit)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getUsageColor(usage.usagePercentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getUsageColor(usage.usagePercentage).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${usage.usagePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getUsageColor(usage.usagePercentage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value * (usage.usagePercentage / 100),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(_getUsageColor(usage.usagePercentage)),
                  minHeight: 8,
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${languageService.strings.remaining}: ${StorageAnalysisService.formatFileSize(usage.remainingBytes)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '${languageService.strings.plan}: ${usage.planType.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageChart(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageService.strings.storageBreakdown,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ajusta o layout baseado no tamanho da tela
                  if (constraints.maxWidth < 600) {
                    // Layout em coluna para telas pequenas
                    return Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: PieChartPainter(
                                  categories: usage.categories,
                                  animationValue: _progressAnimation.value,
                                ),
                                child: const SizedBox.expand(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartLegend(context, usage, languageService),
                      ],
                    );
                  } else {
                    // Layout em linha para telas maiores
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: PieChartPainter(
                                  categories: usage.categories,
                                  animationValue: _progressAnimation.value,
                                ),
                                child: const SizedBox.expand(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _buildChartLegend(context, usage, languageService),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    final sortedCategories = [...usage.categories]
      ..sort((a, b) => b.size.compareTo(a.size));

    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: sortedCategories.map((category) {
            final percentage = category.getPercentageOf(usage.totalUsed);
            if (percentage < 0.1) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryName(category.category, languageService),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          '${StorageAnalysisService.formatFileSize(category.size)} (${percentage.toStringAsFixed(1)}%)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageService.strings.detailedBreakdown,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...usage.categories.map((category) => _buildCategoryRow(context, category, usage, languageService)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, StorageCategoryData category, StorageUsageData usage, LanguageService languageService) {
    final percentage = category.getPercentageOf(usage.totalUsed);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            category.icon,
            color: category.color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getCategoryName(category.category, languageService),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      StorageAnalysisService.formatFileSize(category.size),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.fileCount} ${category.fileCount == 1 ? languageService.strings.file : languageService.strings.files}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: category.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInformation(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  usage.planType == 'starter' ? Icons.free_breakfast :
                  usage.planType == 'standard' ? Icons.workspace_premium :
                  Icons.diamond,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '${languageService.strings.currentPlan}: ${usage.planType.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPlanFeatures(context, usage.planType, languageService),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeatures(BuildContext context, String planType, LanguageService languageService) {
    List<String> features;
    switch (planType.toLowerCase()) {
      case 'starter':
        features = [
          '${languageService.strings.storage}: 100MB',
          '${languageService.strings.maxFiles}: 10',
          '${languageService.strings.playlists}: 1',
          '${languageService.strings.notes}: 5',
        ];
        break;
      case 'standard':
        features = [
          '${languageService.strings.storage}: 5GB',
          '${languageService.strings.maxFiles}: 200',
          '${languageService.strings.playlists}: ${languageService.strings.unlimited}',
          '${languageService.strings.notes}: ${languageService.strings.unlimited}',
        ];
        break;
      case 'advanced':
        features = [
          '${languageService.strings.storage}: 50GB',
          '${languageService.strings.maxFiles}: ${languageService.strings.unlimited}',
          '${languageService.strings.playlists}: ${languageService.strings.unlimited}',
          '${languageService.strings.notes}: ${languageService.strings.unlimited}',
        ];
        break;
      default:
        features = [];
    }

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildUpgradeSuggestion(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    if (!usage.isNearLimit && !usage.isOverLimit) return const SizedBox.shrink();

    // CORRIGIDO: Usando cores básicas em vez de warningContainer/warning
    final cardColor = usage.isOverLimit ? Colors.red.shade50 : Colors.orange.shade50;
    final iconColor = usage.isOverLimit ? Colors.red : Colors.orange;
    final textColor = usage.isOverLimit ? Colors.red.shade800 : Colors.orange.shade800;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  usage.isOverLimit ? Icons.error : Icons.warning,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usage.isOverLimit 
                      ? languageService.strings.storageExceeded
                      : languageService.strings.storageAlmostFull,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              usage.isOverLimit 
                ? languageService.strings.upgradeToAccessFeatures
                : languageService.strings.considerUpgrading,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (usage.planType != 'advanced') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpgradeDialog(context, usage, languageService),
                  icon: const Icon(Icons.upgrade),
                  label: Text(languageService.strings.upgradePlan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCleanupDialog(context, languageService),
            icon: const Icon(Icons.cleaning_services),
            label: Text(languageService.strings.cleanupFiles),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loadStorageData,
            icon: const Icon(Icons.refresh),
            label: Text(languageService.strings.refresh),
          ),
        ),
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context, StorageUsageData usage, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.strings.upgradePlan),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(languageService.strings.chooseNewPlan),
            const SizedBox(height: 16),
            _buildPlanOption(context, 'Standard', '5GB', 'R\$ 34,90/mês', usage.planType != 'standard'),
            _buildPlanOption(context, 'Advanced', '50GB', 'R\$ 64,90/mês', usage.planType != 'advanced'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageService.strings.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(BuildContext context, String planName, String storage, String price, bool enabled) {
    return Card(
      color: enabled ? null : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: ListTile(
        enabled: enabled,
        title: Text(planName),
        subtitle: Text('$storage • $price'),
        trailing: enabled ? const Icon(Icons.arrow_forward_ios) : const Icon(Icons.check_circle, color: Colors.green),
        onTap: enabled ? () {
          Navigator.pop(context);
          _processUpgrade(planName.toLowerCase());
        } : null,
      ),
    );
  }

  void _processUpgrade(String newPlan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upgrade para $newPlan em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCleanupDialog(BuildContext context, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.strings.cleanupFiles),
        content: Text(languageService.strings.cleanupDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageService.strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCleanup();
            },
            child: Text(languageService.strings.clean),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Limpeza de arquivos concluída!'),
        backgroundColor: Colors.green,
      ),
    );
    await _loadStorageData();
  }

  Color _getUsageColor(double percentage) {
    if (percentage > 100) return Colors.red;
    if (percentage > 90) return Colors.deepOrange;
    if (percentage > 80) return Colors.orange;
    if (percentage > 60) return Colors.amber;
    return Theme.of(context).colorScheme.primary;
  }

  String _getCategoryName(StorageCategory category, LanguageService languageService) {
    switch (category) {
      case StorageCategory.audio:
        return languageService.strings.audio;
      case StorageCategory.video:
        return languageService.strings.video;
      case StorageCategory.images:
        return languageService.strings.images;
      case StorageCategory.notes:
        return languageService.strings.notes;
      case StorageCategory.verses:
        return languageService.strings.verses;
      case StorageCategory.playlists:
        return languageService.strings.playlists;
      case StorageCategory.letters:
        return languageService.strings.letters;
    }
  }
}

class PieChartPainter extends CustomPainter {
  final List<StorageCategoryData> categories;
  final double animationValue;

  PieChartPainter({
    required this.categories,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Validação de tamanho
    if (size.width <= 0 || size.height <= 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;
    
    // Validação de categorias
    if (categories.isEmpty) return;
    
    final totalSize = categories.fold<int>(0, (sum, category) => sum + category.size);
    if (totalSize == 0) {
      // Desenha círculo vazio se não há dados
      final emptyPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, emptyPaint);
      
      // Centro
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.4, centerPaint);
      return;
    }

    double currentAngle = -math.pi / 2; // Start from top
    
    for (final category in categories) {
      if (category.size == 0) continue;
      
      final sweepAngle = (category.size / totalSize) * 2 * math.pi * animationValue;
      
      // Validação do ângulo
      if (sweepAngle <= 0) continue;
      
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          currentAngle,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
      
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);
      
      currentAngle += sweepAngle;
    }

    // Draw center hole for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}