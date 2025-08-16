import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive Firebase error handling service
/// Provides user-friendly error messages in Portuguese for VERSEE
class FirebaseErrorService {
  /// Handle Firebase Auth errors
  static String handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        // Registration errors
        case 'email-already-in-use':
          return 'Este email já está sendo usado por outra conta.';
        case 'weak-password':
          return 'A senha deve ter pelo menos 6 caracteres.';
        case 'invalid-email':
          return 'Por favor, insira um email válido.';

        // Login errors
        case 'user-not-found':
          return 'Não encontramos uma conta com este email.';
        case 'wrong-password':
          return 'Senha incorreta. Tente novamente.';
        case 'user-disabled':
          return 'Esta conta foi desabilitada. Entre em contato com o suporte.';
        case 'invalid-credential':
          return 'Email ou senha incorretos.';

        // Security errors
        case 'too-many-requests':
          return 'Muitas tentativas de login. Tente novamente em alguns minutos.';
        case 'operation-not-allowed':
          return 'Esta operação não está disponível no momento.';
        case 'requires-recent-login':
          return 'Para sua segurança, faça login novamente para continuar.';

        // Network errors
        case 'network-request-failed':
          return 'Erro de conexão. Verifique sua internet e tente novamente.';

        // Password reset errors
        case 'invalid-action-code':
          return 'Link de redefinição inválido ou expirado.';
        case 'expired-action-code':
          return 'Link de redefinição expirado. Solicite um novo.';

        default:
          debugPrint('Unhandled Auth Error: ${error.code} - ${error.message}');
          return 'Erro de autenticação: ${error.message ?? 'Tente novamente'}';
      }
    }
    
    debugPrint('Unknown Auth Error: $error');
    return 'Erro inesperado. Tente novamente.';
  }

  /// Handle Firestore errors
  static String handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        // Permission errors
        case 'permission-denied':
          return 'Acesso negado. Verifique suas permissões.';
        case 'unauthenticated':
          return 'Faça login para continuar.';

        // Network errors
        case 'unavailable':
          return 'Serviço temporariamente indisponível. Tente novamente.';
        case 'deadline-exceeded':
          return 'Tempo limite excedido. Verifique sua conexão.';
        case 'cancelled':
          return 'Operação cancelada.';

        // Data errors
        case 'not-found':
          return 'Documento não encontrado.';
        case 'already-exists':
          return 'Este item já existe.';
        case 'failed-precondition':
          return 'Operação não pode ser executada no estado atual.';
        case 'aborted':
          return 'Operação cancelada devido a conflito.';

        // Quota errors
        case 'resource-exhausted':
          return 'Limite de uso atingido. Tente novamente mais tarde.';

        // Invalid argument errors
        case 'invalid-argument':
          return 'Dados inválidos fornecidos.';
        case 'out-of-range':
          return 'Valor fora do intervalo permitido.';

        default:
          debugPrint('Unhandled Firestore Error: ${error.code} - ${error.message}');
          return 'Erro no banco de dados: ${error.message ?? 'Tente novamente'}';
      }
    }
    
    debugPrint('Unknown Firestore Error: $error');
    return 'Erro inesperado no banco de dados.';
  }

  /// Handle Firebase Storage errors
  static String handleStorageError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        // Permission errors
        case 'storage/unauthorized':
          return 'Sem permissão para acessar este arquivo.';
        case 'storage/unauthenticated':
          return 'Faça login para fazer upload de arquivos.';

        // File errors
        case 'storage/object-not-found':
          return 'Arquivo não encontrado.';
        case 'storage/bucket-not-found':
          return 'Local de armazenamento não encontrado.';

        // Quota errors
        case 'storage/quota-exceeded':
          return 'Cota de armazenamento excedida.';
        case 'storage/project-not-found':
          return 'Projeto Firebase não encontrado.';

        // Upload errors
        case 'storage/invalid-format':
          return 'Formato de arquivo não suportado.';
        case 'storage/invalid-event-name':
          return 'Nome de evento inválido.';

        // Network errors
        case 'storage/retry-limit-exceeded':
          return 'Limite de tentativas excedido. Tente novamente.';
        case 'storage/invalid-url':
          return 'URL de download inválida.';

        default:
          debugPrint('Unhandled Storage Error: ${error.code} - ${error.message}');
          return 'Erro de armazenamento: ${error.message ?? 'Tente novamente'}';
      }
    }
    
    debugPrint('Unknown Storage Error: $error');
    return 'Erro inesperado no armazenamento.';
  }

  /// Handle general Firebase errors
  static String handleGeneralError(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore') {
        return handleFirestoreError(error);
      } else if (error.plugin == 'firebase_storage') {
        return handleStorageError(error);
      }
    }
    
    // Handle common network errors
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
    
    if (errorMessage.contains('timeout')) {
      return 'Tempo limite excedido. Tente novamente.';
    }
    
    debugPrint('Unhandled General Error: $error');
    return 'Erro inesperado. Tente novamente em alguns instantes.';
  }

  /// Get user-friendly error message for any Firebase error
  static String getErrorMessage(dynamic error) {
    try {
      return handleGeneralError(error);
    } catch (e) {
      debugPrint('Error handling error: $e');
      return 'Erro inesperado. Tente novamente.';
    }
  }

  /// Check if error is a network-related error
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'network-request-failed' ||
             error.code == 'unavailable' ||
             error.code == 'deadline-exceeded';
    }
    
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('network') ||
           errorMessage.contains('connection') ||
           errorMessage.contains('timeout');
  }

  /// Check if error is a permission-related error
  static bool isPermissionError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
             error.code == 'unauthenticated' ||
             error.code == 'storage/unauthorized' ||
             error.code == 'storage/unauthenticated';
    }
    return false;
  }

  /// Check if error is recoverable (user can retry)
  static bool isRecoverableError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded' ||
             error.code == 'network-request-failed' ||
             error.code == 'storage/retry-limit-exceeded';
    }
    return isNetworkError(error);
  }

  /// Log error with context for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = getErrorMessage(error);
    debugPrint('🔥 Firebase Error in $context: $errorMessage');
    if (error is FirebaseException) {
      debugPrint('   Code: ${error.code}');
      debugPrint('   Plugin: ${error.plugin}');
      debugPrint('   Message: ${error.message}');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('   Stack trace: $stackTrace');
    }
  }
}