import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/language_service.dart';

/// Página de Cadastro
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                            height: 150,
                            width: 150,
                          ),
                          const SizedBox(height: 32),

                          // Título da página
                          Text(
                            strings.createAccount,
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
                                // Nome
                                TextFormField(
                                  controller: _displayNameController,
                                  focusNode: _nameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    _emailFocusNode.requestFocus();
                                  },
                                  decoration: InputDecoration(
                                    labelText: strings.fullName,
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[900],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return strings.pleaseEnterFullName;
                                    }
                                    if (value.trim().length < 2) {
                                      return strings.nameTooShort;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

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
                                    if (value == null || value.trim().isEmpty) {
                                      return strings.pleaseEnterEmail;
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
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
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    _confirmPasswordFocusNode.requestFocus();
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
                                      return strings.pleaseEnterPasswordRegister;
                                    }
                                    if (value.length < 6) {
                                      return strings.passwordTooShort;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirmar senha
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    _register();
                                  },
                                  decoration: InputDecoration(
                                    labelText: strings.confirmPassword,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[900],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return strings.pleaseConfirmPassword;
                                    }
                                    if (value != _passwordController.text) {
                                      return strings.passwordsDoNotMatch;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Botão de cadastro
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authService.isLoading ? null : _register,
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
                                          strings.signUp,
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

                          // Link para login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${strings.alreadyHaveAccount} ',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: Text(
                                  strings.signInNow,
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    await authService.registerWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );
  }
}