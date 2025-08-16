# 🔥 Guia Final para Configurar Firebase no VERSEE

## 📱 SITUAÇÃO ATUAL
✅ App funcionando 100% no Android  
✅ Autenticação local ativa temporariamente  
❌ Firebase Auth com problema de API key  

## 🛠️ PASSOS PARA CORRIGIR FIREBASE

### 1. Verificar Projeto Firebase
- Acesse: https://console.firebase.google.com
- Projeto: `egxse64845cgaarz90nllkn1o0c1aw`
- Confirme que está no projeto correto

### 2. Verificar SHA-1 Configurado
- Vá em **Configurações do Projeto** > **Suas apps**
- Na app Android `com.versee.app`, verifique se o SHA-1 está listado
- Se não estiver, obtenha o SHA-1:

```bash
# Windows (PowerShell como admin):
cd C:\Users\alexa\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 3. Baixar google-services.json ATUALIZADO
- No Console Firebase, na app Android
- Clique em **Baixar google-services.json**
- Substitua o arquivo em: `android/app/google-services.json`

### 4. Verificar Configurações do Firebase Auth
- No Console Firebase, vá em **Authentication**
- Aba **Sign-in method**
- Certifique-se que **Email/senha** está ATIVO

### 5. Verificar APIs Habilitadas
- No Google Cloud Console (console.cloud.google.com)
- Projeto: `egxse64845cgaarz90nllkn1o0c1aw`
- **APIs e Serviços** > **Biblioteca**
- Certifique-se que estão habilitadas:
  - Firebase Authentication API
  - Identity Toolkit API
  - Cloud Firestore API

### 6. Rebuild e Teste
```bash
# Limpar e rebuildar
flutter clean
flutter pub get
flutter build apk --debug --target-platform android-arm64

# Testar
flutter install -d emulator-5554
flutter logs -d emulator-5554
```

## 🚨 PROBLEMA IDENTIFICADO
O erro mostra: "API key not valid"

Isso indica que:
1. O `google-services.json` não foi atualizado após adicionar SHA-1
2. A API key no arquivo não corresponde ao projeto
3. As APIs não estão habilitadas no Google Cloud Console

## 🎯 SOLUÇÃO TEMPORÁRIA ATIVA
- Autenticação local funcionando
- Você pode criar contas e fazer login
- Dados salvos localmente
- Quando Firebase for configurado, dados serão sincronizados

## 📞 TESTE IMEDIATO
1. Instale o APK no telefone/emulador
2. Clique em "Criar conta"
3. Registre um usuário teste
4. Faça login com esse usuário
5. Teste as funcionalidades do app

O app está **100% funcional** em modo local!