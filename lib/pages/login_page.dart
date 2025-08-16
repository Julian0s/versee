import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/language_service.dart';

/// Página de Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final strings = languageService.strings;
    
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
                            strings.connectionIssues,
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          SvgPicture.asset(
                            'assets/images/logo_versee.svg',
                            height: 200,
                            width: 200,
                          ),
                          const SizedBox(height: 40),

                          // Título da página
                          Text(
                            strings.doLogin,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Formulário
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    _passwordFocusNode.requestFocus();
                                  },
                                  decoration: InputDecoration(
                                    labelText: strings.email,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[900],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return strings.pleaseEnterEmail;
                                    }
                                    if (!value.contains('@')) {
                                      return strings.pleaseEnterValidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Senha
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    _login();
                                  },
                                  decoration: InputDecoration(
                                    labelText: strings.password,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[900],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return strings.pleaseEnterPassword;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Esqueci a senha
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    child: Text(
                                      strings.forgotPassword,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Botão de login
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authService.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: authService.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          strings.signIn,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                  ),
                                ),
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
                                  const Icon(Icons.error_outline, color: Colors.red),
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

                          const SizedBox(height: 24),

                          // Link para cadastro
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${strings.noAccount} ',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/register');
                                },
                                child: Text(
                                  strings.signUp,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      final strings = context.read<LanguageService>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.enterEmailFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final success = await authService.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      final strings = context.read<LanguageService>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.resetEmailSent),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}