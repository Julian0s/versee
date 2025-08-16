import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/auth_service.dart';

class AuthDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSuccess;

  const AuthDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSuccess,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthDialog(
        title: title,
        subtitle: subtitle,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login fields
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register fields
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _registerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Column(
            children: [
              Icon(
                Icons.account_circle,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (authService.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authService.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Entrar'),
                    Tab(text: 'Criar Conta'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(context, authService),
                      _buildRegisterForm(context, authService),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: authService.isLoading ? null : () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: authService.isLoading ? null : () async {
                if (_tabController.index == 0) {
                  await _handleLogin(context, authService);
                } else {
                  await _handleRegister(context, authService);
                }
              },
              child: authService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_tabController.index == 0 ? 'Entrar' : 'Criar Conta'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthService authService) {
    return Form(
      key: _loginFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite seu email';
                }
                if (!value.contains('@')) {
                  return 'Digite um email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPasswordController,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureLoginPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite sua senha';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: authService.isLoading ? null : () async {
                  await _handleLogin(context, authService);
                },
                icon: const Icon(Icons.login),
                label: const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Implementar reset de senha
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              },
              child: const Text('Esqueci minha senha'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, AuthService authService) {
    return Form(
      key: _registerFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _registerNameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite seu nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite seu email';
                }
                if (!value.contains('@')) {
                  return 'Digite um email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerPasswordController,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegisterPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureRegisterPassword = !_obscureRegisterPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureRegisterPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite uma senha';
                }
                if (value.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerConfirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmar Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme sua senha';
                }
                if (value != _registerPasswordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: authService.isLoading ? null : () async {
                  await _handleRegister(context, authService);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Criar Conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthService authService) async {
    if (!_loginFormKey.currentState!.validate()) return;

    final success = await authService.signInWithEmailAndPassword(
      _loginEmailController.text,
      _loginPasswordController.text,
    );

    if (success && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleRegister(BuildContext context, AuthService authService) async {
    if (!_registerFormKey.currentState!.validate()) return;

    final success = await authService.registerWithEmailAndPassword(
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
      displayName: _registerNameController.text,
    );

    if (success && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    }
  }
}