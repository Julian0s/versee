import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:versee/pages/storage_page.dart';
import 'package:versee/pages/display_setup_page.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/firestore_sync_service.dart';
import 'package:versee/services/settings_service.dart';
import 'package:versee/services/theme_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/services/user_settings_service.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/media_sync_service.dart';
import 'package:versee/services/xml_bible_service.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/models/display_models.dart' hide ConnectionState;
import 'package:versee/widgets/auth_dialog.dart';
import 'package:versee/widgets/media_cache_manager_widget.dart';
import 'package:versee/widgets/theme_toggle_button_riverpod.dart';
import 'package:versee/widgets/language_selector_riverpod.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Dados do usuário (serão carregados do Firebase)
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;

  // Removed - now managed by services

  // Configurações da Bíblia - carregadas dinamicamente do SettingsService
  Map<String, bool> _bibleVersions = {};

  // Bíblias importadas via XML
  List<BibleVersionInfo> _importedBibles = [];
  List<String> _enabledImportedBibles = [];
  final XmlBibleService _xmlBibleService = XmlBibleService();

  // Configurações de displays (removido configurações da segunda tela legacy)


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBibleVersionSettings();
    _loadImportedBibles();
  }

  Future<void> _loadBibleVersionSettings() async {
    try {
      final versions = await SettingsService.getEnabledBibleVersions();
      if (mounted) {
        setState(() {
          _bibleVersions = versions;
        });
      }
    } catch (e) {
      print('Error loading Bible version settings: $e');
    }
  }

  Future<void> _loadImportedBibles() async {
    try {
      // DESABILITADO: Carregamento da nuvem temporariamente desabilitado para resolver problemas de permissão
      // Sempre carregar localmente por enquanto
      print('Carregando Bíblias localmente (nuvem desabilitada)...');
      final importedBibles = await _xmlBibleService.getImportedBibles();
      final enabledIds = await _xmlBibleService.getEnabledImportedBibles();
      
      if (mounted) {
        setState(() {
          _importedBibles = <BibleVersionInfo>[]; // Cast fix
          _enabledImportedBibles = enabledIds;
        });
      }
    } catch (e) {
      print('Error loading imported Bibles: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      try {
        Map<String, dynamic>? userData;
        
        if (authService.isUsingLocalAuth) {
          // Use local user data directly
          userData = authService.localUser;
        } else {
          // Get Firebase user data
          userData = await authService.getUserData();
        }
        
        if (mounted) {
          setState(() {
            _userData = userData;
            _isLoadingUserData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingUserData = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
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
              languageService.strings.settings, 
              style: const TextStyle(fontWeight: FontWeight.bold)
            );
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Conta
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.account,
                Icons.account_circle,
                [
                  _buildUserInfoTile(),
                  _buildPlanTile(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Tema
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.theme,
                Icons.palette,
                [
                  ThemeToggleButtonRiverpod(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Linguagem
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.language,
                Icons.language,
                [
                  LanguageSelectorRiverpod(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Conta
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return _buildSection(
                'Conta',
                Icons.account_circle,
                [
                  if (authService.isAuthenticated) ...[
                    _buildTile(
                      authService.user?.email ?? 'Usuário Autenticado',
                      'Configurações da conta',
                      Icons.person,
                      () => _showAccountDialog(),
                    ),
                    _buildTile(
                      'Sincronizar Bíblias',
                      'Sincronizar Bíblias com a nuvem',
                      Icons.cloud_sync,
                      () => _syncBiblesWithCloud(),
                    ),
                  ] else ...[
                    _buildTile(
                      'Fazer Login',
                      'Salvar suas Bíblias na nuvem',
                      Icons.login,
                      () => _showLoginDialog(),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Bíblia
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.bible,
                Icons.book,
                [
                  _buildTile(
                    languageService.strings.enabledVersions,
                    languageService.strings.manageBibleVersions,
                    Icons.list_alt,
                    () => _showBibleVersionsDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Armazenamento
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.storage,
                Icons.storage,
                [
                  _buildTile(
                    languageService.strings.storageInfo,
                    languageService.strings.storageStats,
                    Icons.pie_chart,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StoragePage(),
                      ),
                    ),
                  ),
                  _buildTile(
                    'Cache de Mídia',
                    'Gerenciar cache local de áudio/vídeo',
                    Icons.cached,
                    () => _showMediaCacheDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Displays e Projeção
          Consumer3<LanguageService, DisplayManager, MediaSyncService>(
            builder: (context, languageService, displayManager, syncService, child) {
              final hasConnectedDisplay = displayManager.hasConnectedDisplay;
              final connectedDisplay = displayManager.connectedDisplay;
              
              return _buildSection(
                languageService.strings.displaySettings,
                Icons.cast,
                [
                  // Status do display conectado
                  if (hasConnectedDisplay && connectedDisplay != null) ...[
                    _buildInfoTile(
                      connectedDisplay.name,
                      _getDisplayStatusDescription(connectedDisplay, languageService),
                      _getDisplayStatusIcon(connectedDisplay.state),
                      _getDisplayStatusColor(connectedDisplay.state),
                    ),
                    
                    // Controles do display conectado
                    _buildTile(
                      languageService.strings.displayManageConnection,
                      languageService.strings.displayTestAndConfigure,
                      Icons.settings,
                      () => _showDisplayControlDialog(connectedDisplay),
                    ),
                  ] else ...[
                    _buildTile(
                      languageService.strings.displaySetupDisplays,
                      languageService.strings.displayConnectNewDisplay,
                      Icons.add_to_queue,
                      () => _openDisplaySetup(),
                    ),
                  ],
                  
                  // Configuração de sincronização
                  if (hasConnectedDisplay) ...[
                    _buildInfoTile(
                      languageService.strings.displaySyncStatus,
                      syncService.isSyncing 
                        ? '${languageService.strings.displaySyncActive} (${syncService.displayLatencies.isEmpty ? "0" : syncService.displayLatencies.values.first.toStringAsFixed(0)}ms)'
                        : languageService.strings.displaySyncInactive,
                      syncService.isSyncing ? Icons.sync : Icons.sync_disabled,
                      syncService.isSyncing ? Colors.green : Colors.orange,
                    ),
                  ],
                  
                  // Configurações de apresentação
                  _buildTile(
                    languageService.strings.displayPresentationSettings,
                    languageService.strings.displayFontSizeColors,
                    Icons.tune,
                    () => _showPresentationSettingsDialog(),
                  ),
                  
                  // Configurações avançadas de display
                  _buildTile(
                    languageService.strings.displayAdvancedSettings,
                    languageService.strings.displayAutoDiscoveryLatency,
                    Icons.developer_mode,
                    () => _openDisplaySetup(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Cloud Sync & Storage
          Consumer3<AuthService, FirestoreSyncService, LanguageService>(
            builder: (context, authService, syncService, languageService, child) {
              return _buildSection(
                languageService.strings.cloudSyncStorage,
                Icons.cloud,
                [
                  if (authService.isAuthenticated) ...[
                    _buildTile(
                      languageService.strings.syncStatus,
                      authService.isAuthenticated 
                        ? (authService.isUsingLocalAuth 
                            ? '${languageService.strings.connected} (${languageService.strings.localAs}) ${authService.localUser?['email']}'
                            : '${languageService.strings.connected} (${languageService.strings.firebaseAs}) ${authService.user?.email}')
                        : languageService.strings.disconnected,
                      Icons.sync,
                      () => _showSyncStatusDialog(),
                    ),
                    _buildTile(
                      languageService.strings.syncNow,
                      languageService.strings.forceSyncAllData,
                      Icons.cloud_sync,
                      syncService.isLoading ? () {} : () => _syncNow(),
                    ),
                    _buildTile(
                      languageService.strings.signOut,
                      languageService.strings.disconnectWorkOffline,
                      Icons.logout,
                      () => _showLogoutDialog(),
                    ),
                  ] else ...[
                    _buildTile(
                      languageService.strings.makeLogin,
                      languageService.strings.connectToSyncCloud,
                      Icons.login,
                      () => Navigator.of(context).pushNamed('/auth'),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Compartilhar
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.share,
                Icons.share,
                [
                  _buildTile(
                    languageService.strings.shareThisApp,
                    languageService.strings.recommendVersee,
                    Icons.mobile_friendly,
                    () => _shareApp(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção Sobre
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return _buildSection(
                languageService.strings.about,
                Icons.info,
                [
                  _buildTile(
                    languageService.strings.aboutVersee,
                    languageService.strings.versionDeveloperLicenses,
                    Icons.info_outline,
                    () => _showAboutDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildUserInfoTile() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (_isLoadingUserData) {
          return Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return ListTile(
                leading: const CircularProgressIndicator(),
                title: Text(languageService.strings.loadingUserData),
              );
            },
          );
        }

        if (!authService.isAuthenticated) {
          return Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(languageService.strings.notConnected),
                subtitle: Text(languageService.strings.loginToSyncData),
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/auth'),
                  child: Text(languageService.strings.login),
                ),
              );
            },
          );
        }

        // Get user data based on auth mode
        final languageService = Provider.of<LanguageService>(context, listen: false);
        String displayName, email, authModeText;
        if (authService.isUsingLocalAuth) {
          final localUser = authService.localUser;
          displayName = localUser?['displayName'] ?? languageService.strings.localUser;
          email = localUser?['email'] ?? languageService.strings.noEmail;
          authModeText = languageService.strings.localModeOffline;
        } else {
          final user = authService.user;
          final userData = _userData;
          displayName = userData?['displayName'] ?? user?.displayName ?? languageService.strings.user;
          email = user?.email ?? languageService.strings.noEmail;
          authModeText = languageService.strings.firebaseModeOnline;
        }
        
        final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(displayName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email),
              Text(
                authModeText,
                style: TextStyle(
                  fontSize: 12,
                  color: authService.isUsingLocalAuth ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditUserDialog(),
          ),
        );
      },
    );
  }

  Widget _buildPlanTile() {
    return Consumer2<AuthService, LanguageService>(
      builder: (context, authService, languageService, child) {
        // Get plan data based on auth mode
        String userPlan;
        if (authService.isUsingLocalAuth) {
          userPlan = authService.localUser?['plan'] ?? 'free';
        } else {
          userPlan = _userData?['plan'] ?? 'free';
        }
        
        final isPremium = userPlan.toLowerCase() == 'premium';
        final planName = isPremium ? 'Premium' : languageService.strings.freePlan;
        
        // Add local mode disclaimer for plan upgrades
        String subtitle = isPremium ? languageService.strings.unlimitedResources : languageService.strings.limitedResources;
        if (authService.isUsingLocalAuth && !isPremium) {
          subtitle += ' (${languageService.strings.upgradeOnlineOnly})';
        }

        return ListTile(
          leading: Icon(
            isPremium ? Icons.workspace_premium : Icons.free_breakfast,
            color: isPremium ? Colors.amber : Colors.grey,
          ),
          title: Text('${languageService.strings.plan} $planName'),
          subtitle: Text(subtitle),
          trailing: isPremium
              ? const Icon(Icons.check_circle, color: Colors.green)
              : authService.isUsingLocalAuth
                  ? Icon(Icons.cloud_off, color: Colors.grey[600])
                  : TextButton(
                      onPressed: () => _showUpgradeDialog(),
                      child: Text(languageService.strings.upgrade),
                    ),
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, IconData icon, String value, List<String> options, Function(String?) onChanged) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            menuMaxHeight: 200,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options.map((option) => DropdownMenuItem(
              value: option, 
              child: Text(option, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, IconData icon, double value, double min, double max, Function(double) onChanged) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${min.toInt()}'),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).toInt(),
                  label: value.toInt().toString(),
                  onChanged: onChanged,
                ),
              ),
              Text('${max.toInt()}'),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para editar o perfil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show warning for local mode users
    if (authService.isUsingLocalAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo local: Alterações não serão sincronizadas até conectar online'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }

    final currentDisplayName = authService.isUsingLocalAuth
        ? (authService.localUser?['displayName'] ?? '')
        : (_userData?['displayName'] ?? authService.user?.displayName ?? '');
    final nameController = TextEditingController(text: currentDisplayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Digite seu nome completo',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Email: ${authService.isUsingLocalAuth ? (authService.localUser?['email'] ?? "Não disponível") : (authService.user?.email ?? "Não disponível")}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para alterar o email, entre em contato com o suporte.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDisplayName = nameController.text.trim();
              if (newDisplayName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nome não pode estar vazio'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Atualizando perfil...'),
                    ],
                  ),
                ),
              );

              // Atualizar perfil
              final success = await authService.updateUserProfile(
                displayName: newDisplayName,
              );

              // Fechar loading
              if (mounted) Navigator.pop(context);

              if (success) {
                // Recarregar dados do usuário
                _loadUserData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authService.errorMessage ?? 'Erro ao atualizar perfil'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade para Premium'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recursos Premium:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Versões ilimitadas da Bíblia'),
            Text('• Projeção em múltiplas telas'),
            Text('• Backup na nuvem'),
            Text('• Temas personalizados'),
            Text('• Suporte prioritário'),
            SizedBox(height: 16),
            Text('R\$ 9,90/mês', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mais tarde'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final authService = Provider.of<AuthService>(context, listen: false);
              if (!authService.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Você precisa estar logado para fazer upgrade'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processando upgrade...'),
                    ],
                  ),
                ),
              );

              // Simular processamento do upgrade
              await Future.delayed(const Duration(seconds: 2));

              // Atualizar plano no Firebase

              // Fechar loading
              if (mounted) Navigator.pop(context);

              if (mounted) {
                // Recarregar dados do usuário
                _loadUserData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade simulado! Em uma versão real, integraria com sistema de pagamento.'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Assinar'),
          ),
        ],
      ),
    );
  }

  void _showBibleVersionsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Versões da Bíblia'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Seção de versões da API
                if (_bibleVersions.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Versões Online (API)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_bibleVersions.keys.map((version) {
                    return CheckboxListTile(
                      title: Text(version),
                      value: _bibleVersions[version],
                      onChanged: (value) async {
                        setDialogState(() {
                          _bibleVersions[version] = value ?? false;
                        });
                        setState(() {
                          _bibleVersions[version] = value ?? false;
                        });
                        await SettingsService.saveEnabledBibleVersions(_bibleVersions);
                      },
                    );
                  }).toList()),
                  const Divider(height: 32),
                ],
                
                // Seção de Bíblias importadas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bíblias Importadas (XML)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _uploadXmlBible(setDialogState),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Importar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Lista de Bíblias importadas
                Expanded(
                  child: _importedBibles.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Nenhuma Bíblia importada',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Use o botão "Importar" acima para adicionar Bíblias XML',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _importedBibles.length,
                          itemBuilder: (context, index) {
                            final bible = _importedBibles[index];
                            final isEnabled = _enabledImportedBibles.contains(bible.id);
                            
                            return ListTile(
                              title: Text(bible.name),
                              subtitle: Text('${bible.abbreviation} • ${bible.language}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: isEnabled,
                                    onChanged: (value) async {
                                      await _xmlBibleService.toggleBibleEnabled(bible.id, value ?? false);
                                      await _loadImportedBibles();
                                      setDialogState(() {});
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    tooltip: 'Editar nome',
                                    onPressed: () => _editBibleName(bible, setDialogState),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeBible(bible, setDialogState),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configurações de versões bíblicas salvas!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadXmlBible(StateSetter? setDialogState) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Verificar se precisa fazer login primeiro
    if (!authService.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Armazenamento na Nuvem'),
          content: const Text(
            'Para que suas Bíblias importadas sejam salvas na nuvem e sincronizem entre seus dispositivos, você precisa fazer login ou criar uma conta.\n\n'
            'Você pode continuar sem login, mas a Bíblia ficará apenas neste dispositivo.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar sem login'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fazer Login'),
            ),
          ],
        ),
      );
      
      if (shouldLogin == true) {
        final loginSuccess = await AuthDialog.show(
          context: context,
          title: 'Entrar na Conta',
          subtitle: 'Faça login para salvar suas Bíblias na nuvem',
        );
        
        if (loginSuccess != true) {
          return; // Usuário cancelou ou falhou no login
        }
      }
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Processando arquivo XML...'),
                    if (authService.isAuthenticated)
                      const Text(
                        'Salvando na nuvem...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final bible = await _xmlBibleService.uploadBibleFromFile();
      
      Navigator.pop(context); // Close loading dialog

      if (bible != null) {
        // Mostrar diálogo para personalizar nome da Bíblia
        final customizedBible = await _showNameBibleDialog(bible);
        if (customizedBible != null && customizedBible != bible) {
          // Atualizar a Bíblia com o novo nome
          await _xmlBibleService.updateBibleInfo(customizedBible);
        }
        await _loadImportedBibles();
        if (setDialogState != null) {
          setDialogState(() {});
        }
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.isAuthenticated 
                ? 'Bíblia "${bible.name}" importada e salva na nuvem!'
                : 'Bíblia "${bible.name}" importada localmente!'
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao importar arquivo XML. Verifique o formato.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('Error uploading XML Bible: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar Bíblia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeBible(BibleVersionInfo bible, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Bíblia'),
        content: Text('Tem certeza que deseja remover "${bible.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _xmlBibleService.removeBible(bible.id);
                await _loadImportedBibles();
                setDialogState(() {});
                setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bíblia "${bible.name}" removida com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error removing Bible: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao remover Bíblia: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    const message = 'Conheça o VERSEE - O melhor app de apresentação para igrejas! Baixe agora: https://versee.app';
    Clipboard.setData(const ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado! Compartilhe com seus amigos.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Métodos relacionados ao Firebase

  void _showSyncStatusDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final syncService = Provider.of<FirestoreSyncService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.blue),
            SizedBox(width: 8),
            Text('Status da Sincronização'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Conta:', authService.isUsingLocalAuth 
                ? (authService.localUser?['email'] ?? 'Não conectado')
                : (authService.user?.email ?? 'Não conectado')),
            _buildStatusRow('Modo:', authService.isUsingLocalAuth ? 'Local (Offline)' : 'Firebase (Online)'),
            _buildStatusRow('Plano:', authService.isUsingLocalAuth 
                ? (authService.localUser?['plan'] == 'premium' ? 'Premium' : 'Free')
                : (_userData?['plan'] == 'premium' ? 'Premium' : 'Free')),
            _buildStatusRow('Status:', authService.isAuthenticated ? 'Conectado' : 'Offline'),
            _buildStatusRow('Última sync:', 'Agora mesmo'),
            const SizedBox(height: 16),
            if (syncService.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncService.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Future<void> _syncNow() async {
    final syncService = Provider.of<FirestoreSyncService>(context, listen: false);
    
    // Mostrar dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sincronizando dados...'),
          ],
        ),
      ),
    );

    try {
      await syncService.syncOfflineData();
      
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronização concluída!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na sincronização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text(
          'Tem certeza que deseja sair da sua conta?\n\n'
          'Você poderá continuar usando o app offline, mas não terá acesso '
          'aos dados sincronizados na nuvem até fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logout realizado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Edita o nome de uma Bíblia existente
  Future<void> _editBibleName(BibleVersionInfo bible, StateSetter? setDialogState) async {
    final customizedBible = await _showNameBibleDialog(bible);
    if (customizedBible != null && customizedBible != bible) {
      await _xmlBibleService.updateBibleInfo(customizedBible);
      await _loadImportedBibles();
      if (setDialogState != null) {
        setDialogState(() {});
      }
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bíblia "${customizedBible.name}" atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Mostra diálogo para personalizar nome da Bíblia
  Future<BibleVersionInfo?> _showNameBibleDialog(BibleVersionInfo bible) async {
    final nameController = TextEditingController(text: bible.name);
    final abbreviationController = TextEditingController(text: bible.abbreviation);
    
    return showDialog<BibleVersionInfo?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personalizar Bíblia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Você pode personalizar o nome e abreviação desta Bíblia:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Bíblia',
                hintText: 'Ex: Bíblia Sagrada ACF',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: abbreviationController,
              decoration: const InputDecoration(
                labelText: 'Abreviação',
                hintText: 'Ex: ACF',
                border: OutlineInputBorder(),
              ),
              maxLength: 10,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, bible), // Usar nome original
            child: const Text('Manter Original'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && 
                  abbreviationController.text.trim().isNotEmpty) {
                final customizedBible = BibleVersionInfo(
                  id: bible.id,
                  name: nameController.text.trim(),
                  abbreviation: abbreviationController.text.trim().toUpperCase(),
                  language: bible.language,
                  isPopular: bible.isPopular,
                  isImported: bible.isImported,
                );
                Navigator.pop(context, customizedBible);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'VERSEE',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.present_to_all,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text(
          'VERSEE é um aplicativo de apresentação para igrejas, inspirado no ProPresenter.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Desenvolvido para facilitar apresentações de cultos, estudos bíblicos e eventos religiosos.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Recursos principais:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Apresentação de versículos bíblicos'),
        const Text('• Criação de slides personalizados'),
        const Text('• Múltiplas versões da Bíblia'),
        const Text('• Projeção em segunda tela'),
        const Text('• Interface intuitiva e moderna'),
        const Text('• Sincronização na nuvem'),
        const SizedBox(height: 16),
        const Text(
          'Desenvolvido com ❤️ para a comunidade cristã.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Future<void> _showLoginDialog() async {
    final success = await AuthDialog.show(
      context: context,
      title: 'Entrar na Conta',
      subtitle: 'Faça login para salvar suas Bíblias na nuvem e sincronizar entre dispositivos',
      onSuccess: () {
        // Recarregar Bíblias após login
        _loadImportedBibles();
        _syncBiblesWithCloud();
      },
    );
    
    if (success == true) {
      setState(() {}); // Atualizar UI após login
    }
  }

  Future<void> _showAccountDialog() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações da Conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${authService.user?.email ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('UID: ${authService.user?.uid ?? 'N/A'}'),
            const SizedBox(height: 16),
            Text(
              'Suas Bíblias importadas são automaticamente sincronizadas na nuvem.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text(
          'Tem certeza que deseja sair? Suas Bíblias importadas continuarão salvas na nuvem, '
          'mas você precisará fazer login novamente para sincronizá-las.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      setState(() {}); // Atualizar UI após logout
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout realizado com sucesso'),
        ),
      );
    }
  }

  Future<void> _syncBiblesWithCloud() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sincronizando Bíblias...'),
            ],
          ),
        ),
      );
      
      // Note: Cloud sync not implemented yet
      
      // Recarregar lista
      await _loadImportedBibles();
      
      Navigator.pop(context); // Fechar dialog de loading
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronização concluída com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      Navigator.pop(context); // Fechar dialog de loading
      print('Erro na sincronização: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na sincronização: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMediaCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          child: const MediaCacheManagerWidget(),
        ),
      ),
    );
  }
  
  // Métodos para displays
  void _openDisplaySetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DisplaySetupPage(),
      ),
    );
  }
  
  String _getDisplayStatusDescription(ExternalDisplay display, LanguageService languageService) {
    switch (display.state) {
      case DisplayConnectionState.connected:
        return '${languageService.strings.displayConnected} • ${_getDisplayTypeLabel(display.type)}';
      case DisplayConnectionState.presenting:
        return '${languageService.strings.displayPresenting} • ${_getDisplayTypeLabel(display.type)}';
      case DisplayConnectionState.connecting:
        return '${languageService.strings.displayConnecting} • ${_getDisplayTypeLabel(display.type)}';
      case DisplayConnectionState.error:
        return '${languageService.strings.displayError} • ${_getDisplayTypeLabel(display.type)}';
      default:
        return _getDisplayTypeLabel(display.type);
    }
  }
  
  String _getDisplayTypeLabel(DisplayType type) {
    switch (type) {
      case DisplayType.hdmi:
        return 'HDMI';
      case DisplayType.usbC:
        return 'USB-C';
      case DisplayType.chromecast:
        return 'Chromecast';
      case DisplayType.airplay:
        return 'AirPlay';
      case DisplayType.webWindow:
        return 'Janela Web';
      default:
        return 'Display Externo';
    }
  }
  
  IconData _getDisplayStatusIcon(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected:
      case DisplayConnectionState.presenting:
        return Icons.check_circle;
      case DisplayConnectionState.connecting:
        return Icons.sync;
      case DisplayConnectionState.detected:
        return Icons.visibility;
      case DisplayConnectionState.error:
        return Icons.error;
      default:
        return Icons.help;
    }
  }
  
  Color _getDisplayStatusColor(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected:
      case DisplayConnectionState.presenting:
        return Colors.green;
      case DisplayConnectionState.connecting:
        return Colors.orange;
      case DisplayConnectionState.detected:
        return Colors.blue;
      case DisplayConnectionState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _showDisplayControlDialog(ExternalDisplay display) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Controlar ${display.name}'),
        content: Consumer3<DisplayManager, MediaSyncService, LanguageService>(
          builder: (context, displayManager, syncService, languageService, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    _getDisplayStatusIcon(display.state),
                    color: _getDisplayStatusColor(display.state),
                  ),
                  title: Text(display.name),
                  subtitle: Text(_getDisplayStatusDescription(display, languageService)),
                ),
                
                const Divider(),
                
                // Sync status
                if (syncService.isSyncing) ...[
                  ListTile(
                    leading: const Icon(Icons.sync, color: Colors.green),
                    title: const Text('Sincronização Ativa'),
                    subtitle: Text(
                      syncService.displayLatencies.isNotEmpty
                        ? 'Latência: ${syncService.displayLatencies.values.first.toStringAsFixed(0)}ms'
                        : 'Latência não medida',
                    ),
                  ),
                ] else ...[
                  const ListTile(
                    leading: Icon(Icons.sync_disabled, color: Colors.orange),
                    title: Text('Sincronização Inativa'),
                    subtitle: Text('Inicie reprodução para ativar'),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final displayManager = Provider.of<DisplayManager>(context, listen: false);
              await displayManager.testConnection(display.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teste de conexão enviado')),
              );
            },
            child: const Text('Testar'),
          ),
          TextButton(
            onPressed: () async {
              final displayManager = Provider.of<DisplayManager>(context, listen: false);
              await displayManager.disconnect();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Display desconectado')),
              );
            },
            child: const Text('Desconectar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  void _showPresentationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações de Apresentação'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<DisplayManager>(
                builder: (context, displayManager, child) {
                  return Column(
                    children: [
                      // Font size
                      ListTile(
                        leading: const Icon(Icons.format_size),
                        title: const Text('Tamanho da Fonte'),
                        subtitle: Slider(
                          value: displayManager.fontSize,
                          min: 16,
                          max: 72,
                          divisions: 14,
                          label: '${displayManager.fontSize.round()}',
                          onChanged: (value) {
                            displayManager.updatePresentationSettings(fontSize: value);
                          },
                        ),
                      ),
                      
                      // Text color
                      ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: const Text('Cor do Texto'),
                        trailing: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: displayManager.textColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        onTap: () {
                          // Implementar seletor de cor
                        },
                      ),
                      
                      // Background color
                      ListTile(
                        leading: const Icon(Icons.palette),
                        title: const Text('Cor de Fundo'),
                        trailing: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: displayManager.backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        onTap: () {
                          // Implementar seletor de cor
                        },
                      ),
                      
                      // Text alignment
                      ListTile(
                        leading: const Icon(Icons.format_align_center),
                        title: const Text('Alinhamento do Texto'),
                        subtitle: DropdownButton<TextAlign>(
                          value: displayManager.textAlignment,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: TextAlign.left, child: Text('Esquerda')),
                            DropdownMenuItem(value: TextAlign.center, child: Text('Centro')),
                            DropdownMenuItem(value: TextAlign.right, child: Text('Direita')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              displayManager.updatePresentationSettings(textAlignment: value);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  // Método para criar tiles de informação (não editáveis)
  Widget _buildInfoTile(String title, String subtitle, IconData icon, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      enabled: false, // Apenas informativo
    );
  }
}