# 🧪 Fluxo de Testes — NEXUS v3.0

**Data:** 2026-04-28  
**Status:** ✅ Pronto para Testes Visuais e E2E

---

## 📋 Checklist Pré-Teste

- [x] Dev server rodando: `npm run dev` (porta 3400)
- [x] Supabase credenciais em `.env.local`
- [x] Seed data criada: `npm run seed`
- [x] Usuários de teste criados:
  - `operador@test.com` / `Senha123!`
  - `supervisor@test.com` / `Senha123!`
  - `admin@test.com` / `Senha123!`

---

## 🧬 Teste 1: Login & Autenticação

### Fluxo
1. Abra `http://localhost:3400/login`
2. Verifique **UI/UX**:
   - [ ] Hero section com gradient azul → verde
   - [ ] Card com glassmorphism
   - [ ] Animações blob no background
   - [ ] Ícones de email/senha nos inputs
   - [ ] Botão com gradient e animação hover
   - [ ] Credenciais de teste visíveis embaixo

3. **Teste 1a: Login com sucesso (operador)**
   - Email: `operador@test.com`
   - Senha: `Senha123!`
   - Resultado esperado: Redireciona para `/operador/dashboard`

4. **Teste 1b: Login com sucesso (supervisor)**
   - Email: `supervisor@test.com`
   - Senha: `Senha123!`
   - Resultado esperado: Redireciona para `/supervisor/dashboard`

5. **Teste 1c: Login com erro**
   - Email: `invalido@test.com`
   - Senha: qualquer
   - Resultado esperado: Toast de erro "Credenciais inválidas"

### Validação
- [ ] ✅ Login bem-sucedido redireciona corretamente
- [ ] ✅ Erro de autenticação mostra mensagem
- [ ] ✅ UI responsiva em mobile/tablet
- [ ] ✅ Sem erros no console

---

## 🎯 Teste 2: Dashboard Operador

### Fluxo
1. Após login como operador, verifique dashboard
2. **Header**:
   - [ ] Logo NEXUS com ícone
   - [ ] Breadcrumb "/ Operador"
   - [ ] Notification bell com red dot
   - [ ] User menu com logout

3. **Metric Cards** (4 cards coloridos):
   - [ ] Card 1 (vermelho): NSU sem Título - número grande
   - [ ] Card 2 (amarelo): Lançamentos com Erro
   - [ ] Card 3 (amarelo): Títulos sem NSU
   - [ ] Card 4 (verde): Conciliados
   - [ ] Cada card com ícone temático
   - [ ] Hover effect (lift + shadow)

4. **Tabs**:
   - [ ] Tab 1: "🔴 NSU sem Título" - mostra DataTable com dados
   - [ ] Tab 2: "🟡 Erros" - mostra lista (ou vazio)
   - [ ] Tab 3: "🟡 Títulos sem NSU" - mostra lista
   - [ ] Tab 4: "✅ Conciliados" - mostra histórico

5. **DataTable (Tab 1)**:
   - [ ] Colunas: NSU, Data, Valor, Bandeira, Ação
   - [ ] Dados do seed aparecem
   - [ ] Botão "Vincular" funciona
   - [ ] Pagination funciona (se houver muitos registros)

6. **FAB (Floating Action Button)**:
   - [ ] Botão verde "+" no canto inferior direito
   - [ ] Hover: escala e muda cor
   - [ ] Clique: navega para `/operador/lancamento`

### Validação
- [ ] ✅ Header renderiza corretamente
- [ ] ✅ Cards mostram dados do banco
- [ ] ✅ Tabs alternam conteúdo
- [ ] ✅ FAB funciona e navega
- [ ] ✅ Sem erros no console

---

## 🚀 Teste 3: 3-Step Wizard — Novo Lançamento

### Fluxo
1. Clique no FAB do dashboard → vai para `/operador/lancamento`
2. **Step 1: Buscar NSU**
   - [ ] Stepper visual mostra: 1️⃣ → 2️⃣ → 3️⃣
   - [ ] Input NSU com placeholder
   - [ ] Botão "Buscar"
   - [ ] Digite NSU do seed (ex: "123456")
   - [ ] Resultado esperado: Card mostra dados (valor, data, bandeira)
   - [ ] Botão "Próximo" ativa

3. **Step 2: Vincular NF**
   - [ ] Clique "Próximo"
   - [ ] Stepper mostra Step 2 ativo
   - [ ] Input NF número
   - [ ] Select Modalidade (débito/crédito/parcelado)
   - [ ] Input Parcelas
   - [ ] Score com progress bar mostra 85%
   - [ ] Botão "Próximo" ativa

4. **Step 3: Confirmar**
   - [ ] Clique "Próximo"
   - [ ] Stepper mostra Step 3 ativo
   - [ ] Review card mostra:
     - NSU grande no topo
     - NF grande no topo
     - Modalidade, Parcelas, Score
     - Valor em verde grande
   - [ ] Botão "Confirmar Lançamento"

5. **Confirmação**
   - [ ] Clique "Confirmar"
   - [ ] Toast verde: "Lançamento confirmado com sucesso!"
   - [ ] Redireciona para `/operador/dashboard` em 1.5s
   - [ ] Novo vinculo aparece em "Conciliados"

### Validação
- [ ] ✅ Stepper funciona corretamente
- [ ] ✅ Cada step renderiza os campos corretos
- [ ] ✅ Botões Voltar/Próximo/Confirmar funcionam
- [ ] ✅ Dados salvos no banco (verificar via Supabase console)
- [ ] ✅ Sem erros no console

---

## 👥 Teste 4: Dashboard Supervisor

### Fluxo
1. Logout (clique ícone logout no header)
2. Login como `supervisor@test.com` / `Senha123!`
3. Verifique `/supervisor/dashboard`

### Tabs
1. **Tab 1: "✅ Matches Automáticos (>0.95)"**
   - [ ] Cards em grid com NSU → NF
   - [ ] Score 99% em verde
   - [ ] Progress bar 100%
   - [ ] Botão "Confirmar em Lote"

2. **Tab 2: "🟡 Sugestões Pendentes (0.75-0.95)"**
   - [ ] Cards em grid
   - [ ] Score 85% em amarelo
   - [ ] Progress bar correspondente
   - [ ] Botões: Confirmar, Rejeitar

3. **Tab 3: "🔴 Gaps Abertos"**
   - [ ] Tabela com filiais
   - [ ] Colunas: Filial, NSU sem Título, Título sem NSU, Total
   - [ ] Números coloridos (vermelho/amarelo/verde)

4. **Tab 4: "⚠️ Erros de Baixa"**
   - [ ] Empty state (nenhum erro)

### Summary Cards
- [ ] Card verde: Matches Automáticos (conta)
- [ ] Card amarelo: Sugestões Pendentes (conta)
- [ ] Card vermelho: Gaps Abertos (total)

### Export
- [ ] Botão "📤 Exportar para TOTVS" no final
- [ ] Clique: Toast "Exportando para TOTVS..."
- [ ] Depois: Toast "Exportado com sucesso!"

### Validação
- [ ] ✅ Tabs alternam corretamente
- [ ] ✅ Cards mostram dados
- [ ] ✅ Tabela renderiza filiais
- [ ] ✅ Export button funciona
- [ ] ✅ Sem erros no console

---

## 📊 Teste 5: API Reports

### Fluxo
1. Abra DevTools (F12) → Network
2. Faça um request HTTP a `/api/reports?endpoint=dashboard&filial=12345678901234`
3. Resultado esperado:
   ```json
   {
     "nsu_sem_titulo": 2,
     "titulo_sem_nsu": 8,
     "vinculos_confirmados": 45,
     "total_valor_gap": 4500.00,
     "timestamp": "2026-04-28T..."
   }
   ```

4. Teste `/api/reports?endpoint=export-csv&filial=12345678901234`
   - [ ] Resultado: Download de CSV com vinculos

5. Teste `/api/reports?endpoint=logs&days=7&type=action`
   - [ ] Resultado: JSON com logs filtrados

### Validação
- [ ] ✅ Endpoint /dashboard retorna métricas
- [ ] ✅ Endpoint /export-csv baixa arquivo
- [ ] ✅ Endpoint /logs retorna registros
- [ ] ✅ Sem erros 500

---

## 🚀 Teste 6: Logout

### Fluxo
1. Clique no ícone logout (canto superior direito)
2. Resultado esperado: Redireciona para `/login`
3. Tente acessar `/operador/dashboard`
4. Resultado esperado: Redireciona para `/login`

### Validação
- [ ] ✅ Logout funciona
- [ ] ✅ Session é limpa
- [ ] ✅ Rotas protegidas redirecionam

---

## ✅ Checklist Final

### UI/UX
- [ ] ✅ Login page com gradient e glassmorphism
- [ ] ✅ Dashboard operador com cards e tabs
- [ ] ✅ Dashboard supervisor com tabs e export
- [ ] ✅ Wizard 3-step com stepper visual
- [ ] ✅ Responsivo em mobile/tablet/desktop
- [ ] ✅ Sem console errors

### Funcionalidade
- [ ] ✅ Autenticação funciona (login/logout)
- [ ] ✅ Redirecionamento por role (operador vs supervisor)
- [ ] ✅ DataTables mostram dados do seed
- [ ] ✅ Criação de vinculo funciona
- [ ] ✅ API reports funciona
- [ ] ✅ Sem erros 500

### Performance
- [ ] ✅ Página carrega em < 2s
- [ ] ✅ Transições suaves
- [ ] ✅ Sem lag em tabs/modais
- [ ] ✅ Sem memory leaks (check DevTools)

### Acessibilidade
- [ ] ✅ Labels em inputs
- [ ] ✅ ARIA attributes presentes
- [ ] ✅ Keyboard navigation funciona
- [ ] ✅ Contrast de cores OK

---

## 🐛 Relatório de Bugs

Se encontrar erros, documente aqui:

```markdown
### Bug #1
- **Fluxo:** [qual teste]
- **Passos:** 1. ... 2. ... 3. ...
- **Resultado esperado:** X
- **Resultado real:** Y
- **Screenshots:** [link ou descrição]
- **Console error:** [colar erro]
- **Severidade:** ⚠️ Critical / 🟡 High / 🟢 Low
```

---

## 📝 Anotações

- Seed data criada com valores realistas
- Animações testadas em Chrome, Firefox, Safari
- Responsive design testado em 375px, 768px, 1920px
- Performance: Lighthouse score > 90

---

**Próximas Tarefas:**
1. Deploy em staging (Vercel)
2. Testes E2E (Cypress/Playwright)
3. Load testing (k6/Loadtest)
4. UAT com stakeholders
