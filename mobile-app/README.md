# Nexus Verificador: PWA para Leitura de Comprovantes

**Projeto Satélite para o Nexus**  
**Status:** Planejamento (Fase 5 do roadmap)  
**Timeline:** Semanas 6-8

---

## 📱 Visão Geral

**Nexus Verificador** é uma aplicação Progressive Web App (PWA) que permite operadores capturar comprovantes de cartão de crédito via câmera, extrair dados automaticamente (OCR) e validar contra o banco de dados Nexus em tempo real.

### Problema Resolvido

- ❌ Operador precisa digitar manualmente: NSU, Autorização, Valor, Data
- ✅ Fotografa cupom → OCR extrai automaticamente → Valida em segundos

### Benefícios

1. **Velocidade:** OCR em tempo real (< 2 segundos por foto)
2. **Acurácia:** Machine learning reduz erros de digitação
3. **Rastreabilidade:** Cada validação é auditada com foto
4. **Offline:** Funciona sem internet (modo degradado)
5. **Multiplataforma:** iOS, Android, Web (uma base de código)

---

## 🎯 Escopo Detalhado

### Fase 1: MVP - Extração OCR

#### Funcionalidade 1.1: Captura de Imagem

```
┌─────────────────────────────────────────┐
│ Nexus Verificador                       │
├─────────────────────────────────────────┤
│                                         │
│       [📷 Fotografar Cupom]             │
│       [📤 Escolher da Galeria]          │
│                                         │
└─────────────────────────────────────────┘
```

**Implementação:**
- Usar `navigator.mediaDevices.getDisplayMedia()` (web)
- Fallback para `<input type="file">` (mobile)
- Salvar frame em Canvas para processamento

**Requisitos:**
- Mínimo 2MP de resolução
- Suporte para JPEG, PNG
- Compressão automática se > 5MB

#### Funcionalidade 1.2: OCR com TensorFlow.js

```
Cupom (imagem)
     ↓
[TensorFlow.js OCR] ← Tesseract.js (on-device)
     ↓
┌──────────────────────────────────┐
│ Dados Extraídos (JSON):          │
│ {                                │
│   "nsu": "123456",               │
│   "autorizacao": "ABC123",       │
│   "valor": "1000.00",            │
│   "data": "15/04/2026",          │
│   "hora": "14:30:45",            │
│   "ultimos_4_digitos": "4567",   │
│   "bandeira": "Visa",            │
│   "confidence": 0.96             │
│ }                                │
└──────────────────────────────────┘
```

**Tecnologia: Tesseract.js**
- OCR open-source (sem servidor)
- Executa no navegador (privacy-first)
- Suporta português

**Implementação:**
```javascript
import Tesseract from 'tesseract.js';

const { data: { text } } = await Tesseract.recognize(
  imageSrc,
  'por'  // Português
);

// Parse text para extrair campos
const nsu = extrairNSU(text);
const autorizacao = extrairAutorizacao(text);
// ... etc
```

**Confidence Score:**
- Tesseract retorna confidence per linha
- Se < 80%: marcar campo em AMARELO (usuário edita)
- Se < 50%: marcar em VERMELHO (usuário obrigado a editar)
- Se >= 90%: verde (auto-accept)

#### Funcionalidade 1.3: Validação de Campos

```
┌──────────────────────────────────────────┐
│ Revisão de Extração                      │
├──────────────────────────────────────────┤
│                                          │
│ NSU: [123456] ✅                         │
│ Autorização: [ABC123] ✅                 │
│ Valor: [1000.00] ✅                      │
│ Data: [15/04/2026] ✅                    │
│ Hora: [14:30:45] ✅                      │
│ Últimos 4: [4567] ⚠️ (confidence 75%)   │
│ Bandeira: [Visa] ✅                      │
│                                          │
│ [Editar]     [Cancelar]   [Submeter]     │
└──────────────────────────────────────────┘
```

**Validações Locais:**
- NSU: 6-12 dígitos
- Autorização: 4-6 alphanumericos
- Valor: número positivo
- Data: formato válido
- Hora: HH:MM:SS
- Bandeira: whitelist {Visa, Mastercard, Elo, Diners, AMEX}

**UI:**
- Campo ✅ verde: válido e confiante
- Campo ⚠️ amarelo: válido mas baixa confiança (OCR)
- Campo ❌ vermelho: inválido (usuário deve editar)

#### Funcionalidade 1.4: Submissão com Foto

```javascript
// Após validação, submeter:
const payload = {
  nsu: "123456",
  autorizacao: "ABC123",
  valor: 1000.00,
  data: "2026-04-15",
  hora: "14:30:45",
  ultimos_4_digitos: "4567",
  bandeira: "Visa",
  filial_id: 1,
  foto_cupom: base64_image,  // Imagem em base64
  metadata: {
    ocr_confidence: 0.96,
    timestamp: "2026-04-24T14:30:45Z",
    dispositivo: "iPhone 13"
  }
};

// POST para Supabase Storage + Metadata
const { data, error } = await supabase
  .from('comprovantes_verificados')
  .insert(payload);
```

### Fase 2: Matching em Tempo Real

#### Funcionalidade 2.1: Query Automática

Após submissão bem-sucedida:

```
NSU extraído: 123456
     ↓
Query: SELECT * FROM transacoes_getnet 
       WHERE nsu = '123456' AND filial_id = 1
     ↓
┌─ Encontrado + Conciliado ✅
│  "Este comprovante já foi validado"
│  Vinculado a: NF #001234
│  Status: Conciliado em 2026-04-20
│
├─ Encontrado + Pendente ⏳
│  "Aguardando validação do operador principal"
│  Score: 0.87 (sugestão de 1 título)
│  Ações: [Aceitar] [Rejeitar] [Editar]
│
└─ Não Encontrado ❌
   "Comprovante não encontrado"
   Motivo: NSU fora do período de ingestão?
   Ação: [Contatar Suporte]
```

#### Funcionalidade 2.2: Real-time Subscriptions

```javascript
// Subscribe a mudanças de status
supabase
  .from('conciliacao_vinculos')
  .on('*', payload => {
    if (payload.new.status === 'confirmado') {
      // Notificação push
      new Notification('✅ Comprovante Validado!');
    }
  })
  .subscribe();
```

#### Funcionalidade 2.3: Notificações Push

**Quando disparar:**
- ✅ Comprovante validado com sucesso
- ⚠️ Divergência detectada (valor discrepante)
- ❌ NSU não encontrado
- ⏰ Vencimento próximo (título)

```javascript
// Service Worker
self.registration.showNotification('Nexus', {
  body: '✅ Cupom #123456 validado!',
  icon: '/logo.png',
  tag: 'nsu-123456'
});
```

### Fase 3: Dashboard e Análise

#### Funcionalidade 3.1: Dashboard Operacional

```
┌─────────────────────────────────────────────┐
│ Nexus Verificador - Dashboard              │
├─────────────────────────────────────────────┤
│                                             │
│ Filtros:                                    │
│ [Filial: SP001 ▼]  [Status: Pendente ▼]  │
│ [Período: 15-30/04 ▼]                      │
│                                             │
│ Resumo:                                     │
│ ├─ Validados: 234 ✅                       │
│ ├─ Pendentes: 45 ⏳                        │
│ ├─ Divergências: 8 ⚠️                      │
│ └─ Não encontrados: 2 ❌                   │
│                                             │
│ Últimos Verificados:                       │
│ ├─ NSU 123456 (Visa, R$ 1.000) ✅         │
│ ├─ NSU 123457 (MC, R$ 250) ✅             │
│ ├─ NSU 123458 (Elo, R$ 500) ⚠️            │
│ └─ [Ver Mais]                              │
│                                             │
│ [Fotografar Novo] [Histórico] [Sair]       │
└─────────────────────────────────────────────┘
```

**Funcionalidades:**
- Filtro por filial (RLS automático)
- Filtro por status (pendente, validado, divergência)
- Filtro por período de data
- Busca por NSU ou Autorização
- Ordenação (data, valor, status)

#### Funcionalidade 3.2: Detalhe de Transação

```
┌─────────────────────────────────────────────┐
│ NSU 123456 - Detalhes                       │
├─────────────────────────────────────────────┤
│                                             │
│ [Foto do Cupom]                             │
│ ┌────────────────────────┐                  │
│ │                        │                  │
│ │   [Imagem do cupom]    │                  │
│ │   clicável para zoom   │                  │
│ │                        │                  │
│ └────────────────────────┘                  │
│                                             │
│ ──────────────────────────────────────────  │
│ EXTRAÇÃO OCR vs TOTVS                      │
│                                             │
│ Campo         │ OCR        │ TOTVS          │
│ ───────────────────────────────────────    │
│ NSU           │ 123456     │ ✅ Encontrado  │
│ Autorização   │ ABC123     │ ✅             │
│ Valor         │ R$ 1.000   │ R$ 1.000 ✅   │
│ Data          │ 15/04      │ 16/04 ⚠️      │
│ Bandeira      │ Visa       │ Visa ✅        │
│ Última 4      │ 4567       │ 4567 ✅        │
│                                             │
│ Status de Matching:                        │
│ Score: 0.93 (Alta Confiança)               │
│ Recomendação: ACEITAR                      │
│ Vínculo sugerido: NF #001234                │
│                                             │
│ [Aceitar]  [Rejeitar]  [Editar]            │
│                                             │
└─────────────────────────────────────────────┘
```

#### Funcionalidade 3.3: Histórico de Validações

```
Por Operador:
├─ João Silva: 1.234 validações (98% taxa sucesso)
├─ Maria Santos: 987 validações (96% taxa sucesso)
├─ Pedro Costa: 543 validações (94% taxa sucesso)
└─ Ana Oliveira: 234 validações (100% - novo)

Por Filial:
├─ SP (São Paulo): 2.345 validações
├─ RJ (Rio): 1.234 validações
└─ MG (Minas): 987 validações

Por Bandeira:
├─ Visa: 1.567 (51%)
├─ Mastercard: 1.234 (40%)
├─ Elo: 234 (8%)
└─ Outros: 12 (1%)

Tempo Médio de Validação: 8.5 segundos
```

---

## 🏗️ Arquitetura Técnica

### Stack

| Layer | Tecnologia |
|-------|-----------|
| Frontend | Flutter Web ou React Native Web |
| OCR | Tesseract.js (TensorFlow.js opcional) |
| Storage (Imagem) | Supabase Storage (bucket `cupons`) |
| Database | Supabase (PostgreSQL) |
| API | Supabase PostgREST |
| Auth | Supabase Auth (JWT) |
| Offline | Service Worker + IndexedDB |
| Hosting | Vercel ou Cloudflare Pages |

### Fluxo de Arquitetura

```
┌──────────────────────────────────────────────┐
│         Navegador (iOS/Android/Web)          │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │  Nexus Verificador (PWA)            │    │
│  ├─────────────────────────────────────┤    │
│  │                                     │    │
│  │  1. Camera Input                    │    │
│  │  2. Tesseract.js OCR (on-device)   │    │
│  │  3. Validação Local                 │    │
│  │  4. IndexedDB Cache (offline)       │    │
│  │                                     │    │
│  └─────────────────────────────────────┘    │
│            │                 │               │
│            ▼                 ▼               │
│     (Online)          (Offline/Cache)      │
│            │                 │               │
└────────────┼─────────────────┼───────────────┘
             │                 │
             ▼                 ▼
     ┌─────────────┐  ┌──────────────┐
     │ Supabase    │  │ IndexedDB    │
     │ PostgREST   │  │ (Device)     │
     └─────────────┘  └──────────────┘
             │                 │
             └─────────┬───────┘
                       ▼
            ┌────────────────────────┐
            │ PostgreSQL Database    │
            ├────────────────────────┤
            │ transacoes_getnet      │
            │ titulos_totvs          │
            │ comprovantes_verificados│
            │ conciliacao_vinculos   │
            └────────────────────────┘
```

### Banco de Dados: Nova Tabela

```sql
CREATE TABLE IF NOT EXISTS comprovantes_verificados (
  comprovante_id BIGSERIAL PRIMARY KEY,
  filial_id INTEGER NOT NULL REFERENCES filiais(filial_id),
  nsu VARCHAR(20) NOT NULL,
  numero_autorizacao VARCHAR(20) NOT NULL,
  valor NUMERIC(15, 2) NOT NULL,
  data_transacao DATE NOT NULL,
  hora_transacao TIME NOT NULL,
  ultimos_4_digitos VARCHAR(4) NOT NULL,
  bandeira VARCHAR(50) NOT NULL,
  
  -- OCR Data
  foto_cupom_url TEXT NOT NULL,  -- Storage URL
  ocr_confidence NUMERIC(3, 2),  -- Tesseract confidence
  
  -- Validação
  usuario_verificacao VARCHAR(100) NOT NULL,
  data_verificacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Linking
  transacao_getnet_id BIGINT REFERENCES transacoes_getnet(transacao_id),
  
  -- Metadata
  dispositivo VARCHAR(100),
  localizacao GEOGRAPHY(POINT, 4326),  -- Geolocalização
  
  UNIQUE(filial_id, nsu, numero_autorizacao, data_transacao)
);
```

---

## 📋 Requisitos Não-Funcionais

### Performance

- [ ] OCR < 2 segundos por foto
- [ ] Injeção de metadados < 500ms
- [ ] Query de matching < 200ms
- [ ] Carregamento inicial < 3s (primeira vez)
- [ ] Carregamento inicial < 1s (cached)

### Segurança

- [ ] Autenticação via Supabase Auth
- [ ] RLS aplicado (filial_id)
- [ ] HTTPS obrigatório
- [ ] Imagens criptografadas em trânsito
- [ ] Sem logs de dados sensíveis (NSU, Auth)

### Compatibilidade

- [ ] iOS 13+
- [ ] Android 10+
- [ ] Chrome, Safari, Firefox (versões recentes)
- [ ] Offline mode (Service Worker)

### Acessibilidade

- [ ] WCAG 2.1 AA
- [ ] Suporte a leitores de tela
- [ ] Contrast ratio >= 4.5:1
- [ ] Font size >= 14px

---

## 🧪 Testes

### Testes de OCR

```javascript
// test/ocr.test.js
describe('OCR - Extração de Dados', () => {
  
  test('extrai NSU de cupom real', async () => {
    const img = await loadImage('cupom_real_1.jpg');
    const { nsu } = await extrairDados(img);
    expect(nsu).toBe('123456');
  });
  
  test('valida confiança baixa', async () => {
    const img = await loadImage('cupom_borrado.jpg');
    const { confidence } = await extrairDados(img);
    expect(confidence).toBeLessThan(0.80);
  });
});
```

### Testes de Query

```javascript
// test/matching.test.js
describe('Matching em Tempo Real', () => {
  
  test('encontra transação por NSU', async () => {
    const result = await queryTransacao('123456');
    expect(result.status).toBe('pendente');
    expect(result.valor).toBe(1000.00);
  });
});
```

---

## 📦 Dependências (Propostas)

```json
{
  "dependencies": {
    "react-native-web": "^0.19.0",
    "tesseract.js": "^5.0.0",
    "@supabase/supabase-js": "^2.30.0",
    "react-native-camera": "^4.2.1",
    "zustand": "^4.4.0",
    "react-query": "^3.39.0"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "@testing-library/react-native": "^12.0.0",
    "typescript": "^5.0.0"
  }
}
```

---

## ✅ Checklist de Implementação

### Fase 1: OCR
- [ ] Setup inicial do projeto
- [ ] Integração Tesseract.js
- [ ] UI de captura (câmera + upload)
- [ ] Validação de campos
- [ ] Testes com 50+ cupons reais
- [ ] Tuning de OCR (português)

### Fase 2: Real-time
- [ ] Query de matching
- [ ] Real-time subscriptions
- [ ] Notificações push
- [ ] Testes de latência

### Fase 3: Dashboard
- [ ] Listagem com filtros
- [ ] Detalhe de transação
- [ ] Histórico por operador
- [ ] Métricas e KPIs

### Fase 4: Deploy
- [ ] Service Worker (offline)
- [ ] PWA manifest
- [ ] Build otimizado
- [ ] Deploy em Vercel/Cloudflare

---

## 📊 Métricas de Sucesso

| Métrica | Meta |
|---------|------|
| Acurácia OCR | >= 95% |
| Tempo de validação | < 10s |
| Taxa de rejeição | < 5% |
| Usuários ativos | 20+ |
| Validações/dia | 1.000+ |
| Uptime | 99.9% |

---

## 🔮 Futuro (Fases 4+)

1. **IA Conversacional:** ChatBot para esclarecer dúvidas
2. **Leitura de Transferências:** Estender para PIX/TED
3. **Análise Preditiva:** Alertar sobre padrões anormais
4. **Integração TOTVS:** Sync automática de títulos
5. **Mobile Native:** Apps iOS/Android nativas (opcional)

---

## 📞 Contato

- 📖 Arquitetura geral: `docs/2026-04-24-arquitetura-nexus.md`
- 🐛 Issues: Crie em `issues/`
- 💬 Design: Figma → compartilhado com equipe

---

**Nexus Verificador: Validação de Comprovantes em Tempo Real**
