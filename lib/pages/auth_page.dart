import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/auth_service.dart';


/// Página de autenticação (Login/Registro)
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers para os campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return Column(
              children: [
                // Status do Firebase
                if (!authService.isFirebaseConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.orange.withValues(alpha: 0.2),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Problemas de conexão com Firebase detectados',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo do VERSEE
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Título
                          Text(
                            'VERSEE',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Apresentador de mídia para igrejas',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[400],
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Tabs Login/Registro
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[400],
                              tabs: const [
                                Tab(text: 'Entrar'),
                                Tab(text: 'Registrar'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Formulário
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLoginForm(authService),
                                _buildRegisterForm(authService),
                              ],
                            ),
                          ),

                          // Mensagem de erro
                          if (authService.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[900]?.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authService.errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Modo offline
                          TextButton(
                            onPressed: _continueOffline,
                            child: Text(
                              'Continuar sem sincronização',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthService authService) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu email';
              }
              if (!value.contains('@')) {
                return 'Por favor, insira um email válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Senha
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira sua senha';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Botão de login
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authService.isLoading ? null : _login,
              child: authService.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 16),

          // Esqueci a senha
          TextButton(
            onPressed: _forgotPassword,
            child: const Text('Esqueci minha senha'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthService authService) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nome
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu nome';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu email';
              }
              if (!value.contains('@')) {
                return 'Por favor, insira um email válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Senha
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira uma senha';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirmar senha
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, confirme sua senha';
              }
              if (value != _passwordController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Botão de registro
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authService.isLoading ? null : _register,
              child: authService.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Criar conta'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    await authService.signInWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    await authService.registerWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira seu email primeiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final success = await authService.resetPassword(_emailController.text);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de recuperação enviado!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _continueOffline() {
    Navigator.of(context).pushReplacementNamed('/main');
  }
}

