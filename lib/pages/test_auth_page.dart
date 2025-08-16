
import 'package:flutter/material.dart';
import 'package:versee/services/auth_service.dart';

class TestAuthPage extends StatelessWidget {
  const TestAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste de Cadastro')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final email = 'teste${DateTime.now().millisecondsSinceEpoch}@teste.com';
            final password = '123456';
            final authService = AuthService();

            print('🚀 Tentando registrar novo usuário...');
            final result = await authService.registerWithEmailAndPassword(
              email: email,
              password: password,
              displayName: 'Usuário Teste',
            );

            print(result
                ? '✅ Cadastro completo com sucesso!'
                : '❌ Cadastro falhou. Veja logs acima.');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result
                    ? '✅ Cadastro de teste OK'
                    : '❌ Falha no cadastro de teste'),
                backgroundColor: result ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text('Testar cadastro'),
        ),
      ),
    );
  }
}
