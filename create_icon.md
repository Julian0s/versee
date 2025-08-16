# Como criar o ícone do VERSEE

## Opção 1: Usar logo SVG existente
1. Converter `assets/images/logo_versee.svg` para PNG 1024x1024px
2. Salvar como `assets/images/logo_versee.png`

## Opção 2: Ícone temporário simples
Criar um ícone PNG 1024x1024 com:
- Fundo preto (#000000)
- Texto "V" branco central
- Fonte bold, grande

## Opção 3: Usar ferramenta online
1. https://icon.kitchen
2. https://appicon.co
3. https://makeappicon.com

## Comandos após ter o PNG:

```bash
# Instalar dependências
flutter pub get

# Gerar ícones para todas as plataformas
flutter pub run flutter_launcher_icons

# Build APK com novo ícone
flutter build apk --debug
```

## Tamanhos gerados automaticamente:
- Android: 48x48 até 192x192px (todas as densidades)
- iOS: 20x20 até 1024x1024px (todos os tamanhos)
- Web: 192x192, 512x512px
- Windows: 48x48px
- macOS: 16x16 até 1024x1024px