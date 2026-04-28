# 🚀 Guia de Instalação — Flutter + Nexus

**Status:** Flutter não detectado no sistema  
**Solução:** Seguir os passos abaixo

---

## 📋 PASSO 1: Baixar Flutter SDK

### Windows

1. **Baixe o Flutter SDK:**
   - Acesse: https://flutter.dev/docs/get-started/install/windows
   - Baixe: `flutter_windows_3.13.0-stable.zip` (ou versão mais recente)

2. **Extraia em um local permanente:**
   ```
   C:\flutter\
   ```
   (Evite arquivos de sistema, use um diretório permanente)

3. **Atualize o PATH:**
   - Abra: `Variáveis de Ambiente` (Windows)
   - Clique em: `Variáveis de Ambiente`
   - Adicione ao PATH: `C:\flutter\bin`
   - Clique em: `OK` e reinicie o computador

---

## 📋 PASSO 2: Instalar Dependências

### Verificar Instalação

Abra um **novo PowerShell** (após reiniciar) e execute:

```powershell
flutter --version
dart --version
```

**Esperado:**
```
Flutter 3.13.0 • channel stable
Dart 3.1.0
```

### Instalar Android Studio (opcional, para mobile)

Se planeja compilar para Android:
1. Baixe: https://developer.android.com/studio
2. Instale com Android SDK
3. Configure path do Java

---

## 📋 PASSO 3: Rodar Nexus Localmente

Após instalar Flutter e reiniciar, execute:

```powershell
# 1. Navegar para projeto
cd "d:\Projetos Dev\nexus"

# 2. Instalar dependências (puxa supabase_flutter, go_router, etc)
flutter pub get

# 3. Rodar em Chrome
flutter run -d chrome
```

**Esperado:**
```
✓ Build completo
✓ Chrome abre em http://localhost:5000
✓ App exibe tela de login
```

---

## 🔧 Troubleshooting

| Problema | Solução |
|----------|---------|
| **"flutter: command not found"** | Reinicie o computador após adicionar ao PATH |
| **"Chrome not found"** | Instale Chrome: https://google.com/chrome |
| **"Supabase URL not defined"** | Edite `.env` com suas credenciais |
| **"RLS policy denying access"** | Verifique user_filiais_cnpj no Supabase |

---

## 📊 Verificação Pré-Requisitos

Execute este comando para validar tudo:

```powershell
flutter doctor
```

**Esperado:**
```
✓ Flutter (Channel stable, 3.13.0)
✓ Dart SDK version 3.1.0
✓ Android toolchain (opcional)
✓ Chrome - installed
```

---

## 🎯 Próximo Passo

Assim que Flutter estiver instalado e verificado:

```powershell
cd "d:\Projetos Dev\nexus"
flutter pub get
flutter run -d chrome
```

App abrirá em **http://localhost:5000** ✨

---

**Documentação oficial:** https://flutter.dev/docs/get-started/install  
**Data:** 2026-04-27
