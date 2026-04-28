/**
 * NEXUS Seed Script
 * Insere dados de teste para desenvolvimento
 *
 * Uso: npm run seed
 * Requer: .env.local com credenciais Supabase
 */

const { createClient } = require('@supabase/supabase-js');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Missing Supabase credentials in .env.local');
  console.error('NEXT_PUBLIC_SUPABASE_URL:', supabaseUrl ? 'set' : 'MISSING');
  console.error('SUPABASE_SERVICE_ROLE_KEY:', serviceRoleKey ? 'set' : 'MISSING');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey);

const TEST_FILIALS = [
  { cnpj: '12345678901234', razao_social: 'Filial Matriz', uf: 'SP' },
  { cnpj: '87654321098765', razao_social: 'Filial Interior', uf: 'MG' },
  { cnpj: '11111111111111', razao_social: 'Filial Sul', uf: 'RS' },
];

const TEST_TRANSACOES = [
  {
    filial_cnpj: '12345678901234',
    nsu: '123456',
    data_solicitacao: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    data_venda: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    valor_bruto: 1500.00,
    valor_taxa: 75.00,
    valor_liquido: 1425.00,
    bandeira: 'MASTERCARD',
    tipo: 'credito_a_vista',
    parcelas: 1,
    cnpj_cliente: '98765432100000',
    nome_cliente: 'Cliente A - SP',
    status_transacao: 'processado',
  },
  {
    filial_cnpj: '12345678901234',
    nsu: '234567',
    data_solicitacao: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    data_venda: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    valor_bruto: 2500.00,
    valor_taxa: 125.00,
    valor_liquido: 2375.00,
    bandeira: 'VISA',
    tipo: 'credito_parcelado',
    parcelas: 3,
    cnpj_cliente: '11111111100000',
    nome_cliente: 'Cliente B - SP',
    status_transacao: 'processado',
  },
  {
    filial_cnpj: '87654321098765',
    nsu: '345678',
    data_solicitacao: new Date().toISOString(),
    data_venda: new Date().toISOString(),
    valor_bruto: 800.00,
    valor_taxa: 40.00,
    valor_liquido: 760.00,
    bandeira: 'ELO',
    tipo: 'credito_a_vista',
    parcelas: 1,
    cnpj_cliente: '22222222200000',
    nome_cliente: 'Cliente C - MG',
    status_transacao: 'pendente',
  },
];

const TEST_TITULOS = [
  {
    filial_cnpj: '12345678901234',
    numero_nf: 'NF-001',
    especie: 'NF',
    serie: '1',
    numero: '001',
    parcela: 1,
    data_emissao: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
    data_vencimento: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000).toISOString(),
    valor_bruto: 1500.00,
    desconto: 0,
    acrescimo: 0,
    valor_liquido: 1500.00,
    cnpj_cliente: '98765432100000',
    nome_cliente: 'Cliente A - SP',
    status_titulo: 'aberto',
  },
  {
    filial_cnpj: '12345678901234',
    numero_nf: 'NF-002',
    especie: 'NF',
    serie: '1',
    numero: '002',
    parcela: 1,
    data_emissao: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
    data_vencimento: new Date(Date.now() + 23 * 24 * 60 * 60 * 1000).toISOString(),
    valor_bruto: 2500.00,
    desconto: 0,
    acrescimo: 0,
    valor_liquido: 2500.00,
    cnpj_cliente: '11111111100000',
    nome_cliente: 'Cliente B - SP',
    status_titulo: 'aberto',
  },
  {
    filial_cnpj: '87654321098765',
    numero_nf: 'NF-003',
    especie: 'NF',
    serie: '1',
    numero: '003',
    parcela: 1,
    data_emissao: new Date().toISOString(),
    data_vencimento: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    valor_bruto: 800.00,
    desconto: 0,
    acrescimo: 0,
    valor_liquido: 800.00,
    cnpj_cliente: '22222222200000',
    nome_cliente: 'Cliente C - MG',
    status_titulo: 'aberto',
  },
];

async function seed() {
  console.log('🌱 NEXUS Seed Script iniciado...\n');

  try {
    // 1. Filiais
    console.log('▸ Inserindo filiais...');
    const { error: filiaisError } = await supabase
      .from('filiais')
      .insert(TEST_FILIALS)
      .select();

    if (filiaisError) {
      console.warn(`  ⚠ Filiais: ${filiaisError.message}`);
    } else {
      console.log(`  ✓ ${TEST_FILIALS.length} filiais inseridas`);
    }

    // 2. Transações GETNET
    console.log('▸ Inserindo transações GETNET...');
    const { data: transacoesList, error: transacoesError } = await supabase
      .from('transacoes_getnet')
      .insert(TEST_TRANSACOES)
      .select();

    if (transacoesError) {
      console.warn(`  ⚠ Transações: ${transacoesError.message}`);
    } else {
      console.log(`  ✓ ${TEST_TRANSACOES.length} transações inseridas`);
    }

    // 3. Títulos TOTVS
    console.log('▸ Inserindo títulos TOTVS...');
    const { data: titulosList, error: titulosError } = await supabase
      .from('titulos_totvs')
      .insert(TEST_TITULOS)
      .select();

    if (titulosError) {
      console.warn(`  ⚠ Títulos: ${titulosError.message}`);
    } else {
      console.log(`  ✓ ${TEST_TITULOS.length} títulos inseridos`);
    }

    // 4. Usuários de teste
    console.log('▸ Preparando usuários de teste...');

    const testUsers = [
      { email: 'operador@test.com', password: 'Senha123!', role: 'operador_filial' },
      { email: 'supervisor@test.com', password: 'Senha123!', role: 'supervisor' },
      { email: 'admin@test.com', password: 'Senha123!', role: 'admin' },
    ];

    for (const user of testUsers) {
      try {
        // Criar usuário no Auth
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: user.email,
          password: user.password,
          email_confirm: true,
        });

        if (authError) {
          console.warn(`  ⚠ ${user.email}: ${authError.message}`);
          continue;
        }

        if (authData.user) {
          // Criar entrada na tabela user_filiais
          const { error: userError } = await supabase
            .from('user_filiais')
            .insert({
              user_id: authData.user.id,
              perfil: user.role,
              filial_cnpj: '12345678901234',
            })
            .select();

          if (userError) {
            console.warn(`  ⚠ ${user.email} (filial): ${userError.message}`);
          } else {
            console.log(`  ✓ ${user.email} criado (${user.role})`);
          }
        }
      } catch (e) {
        console.warn(`  ⚠ Erro ao criar ${user.email}: ${e.message}`);
      }
    }

    console.log('\n🎉 Seed completado com sucesso!');
    console.log('\n📝 Próximos passos:');
    console.log('  1. Execute: npm run dev');
    console.log('  2. Abra: http://localhost:3400');
    console.log('  3. Faça login com um dos usuários de teste');
    console.log('  4. Veja dados de teste no Dashboard');

    process.exit(0);
  } catch (error) {
    console.error('❌ Erro durante seed:', error);
    process.exit(1);
  }
}

// Verificar variáveis de ambiente
if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ Variáveis de ambiente não configuradas!');
  console.error('Certifique-se de que .env.local contém:');
  console.error('  - NEXT_PUBLIC_SUPABASE_URL');
  console.error('  - SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

// Executar seed
seed();
