/**
 * Script para inserir dados de teste no Supabase
 * Uso: node scripts/insert-test-data.js
 */

const { createClient } = require('@supabase/supabase-js');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('❌ Missing Supabase credentials in .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey);

const TEST_FILIALS = [
  { filial_cnpj: '84943067001393', codigo_ec: '4566760', razao_social: 'MINUSA FILIAL CURITIBA' },
  { filial_cnpj: '84943067001475', codigo_ec: '4566761', razao_social: 'MINUSA FILIAL SAO PAULO' },
  { filial_cnpj: '84943067001556', codigo_ec: '4566762', razao_social: 'MINUSA FILIAL BRASILIA' },
];

const TEST_TRANSACOES = [
  { filial_cnpj: '84943067001393', nsu: '000001419', codigo_ec: '4566760', autorizacao: 'ABC123', data_venda: '2026-04-25', hora_venda: '10:30:00', valor_venda: 1000.00, bandeira: 'Visa', status: 'pendente', hash_transacao: 'hash1' },
  { filial_cnpj: '84943067001393', nsu: '000001420', codigo_ec: '4566760', autorizacao: 'ABC124', data_venda: '2026-04-25', hora_venda: '11:15:00', valor_venda: 500.50, bandeira: 'Mastercard', status: 'pendente', hash_transacao: 'hash2' },
  { filial_cnpj: '84943067001393', nsu: '000001421', codigo_ec: '4566760', autorizacao: 'ABC125', data_venda: '2026-04-24', hora_venda: '14:45:00', valor_venda: 2500.00, bandeira: 'Elo', status: 'pendente', hash_transacao: 'hash3' },
  { filial_cnpj: '84943067001475', nsu: '000001422', codigo_ec: '4566761', autorizacao: 'ABC126', data_venda: '2026-04-25', hora_venda: '09:30:00', valor_venda: 1200.00, bandeira: 'Visa', status: 'pendente', hash_transacao: 'hash4' },
  { filial_cnpj: '84943067001475', nsu: '000001423', codigo_ec: '4566761', autorizacao: 'ABC127', data_venda: '2026-04-25', hora_venda: '12:00:00', valor_venda: 750.00, bandeira: 'Mastercard', status: 'pendente', hash_transacao: 'hash5' },
  { filial_cnpj: '84943067001556', nsu: '000001424', codigo_ec: '4566762', autorizacao: 'ABC128', data_venda: '2026-04-23', hora_venda: '15:20:00', valor_venda: 3000.00, bandeira: 'Visa', status: 'pendente', hash_transacao: 'hash6' },
  { filial_cnpj: '84943067001556', nsu: '000001425', codigo_ec: '4566762', autorizacao: 'ABC129', data_venda: '2026-04-25', hora_venda: '13:45:00', valor_venda: 1500.00, bandeira: 'Elo', status: 'pendente', hash_transacao: 'hash7' },
  { filial_cnpj: '84943067001393', nsu: '000001426', codigo_ec: '4566760', autorizacao: 'ABC130', data_venda: '2026-04-25', hora_venda: '16:30:00', valor_venda: 800.00, bandeira: 'Mastercard', status: 'pendente', hash_transacao: 'hash8' },
  { filial_cnpj: '84943067001475', nsu: '000001427', codigo_ec: '4566761', autorizacao: 'ABC131', data_venda: '2026-04-24', hora_venda: '11:00:00', valor_venda: 2200.00, bandeira: 'Visa', status: 'pendente', hash_transacao: 'hash9' },
  { filial_cnpj: '84943067001556', nsu: '000001428', codigo_ec: '4566762', autorizacao: 'ABC132', data_venda: '2026-04-25', hora_venda: '17:15:00', valor_venda: 950.00, bandeira: 'Elo', status: 'pendente', hash_transacao: 'hash10' },
];

const TEST_TITULOS = [
  { filial_cnpj: '84943067001393', numero_nf: 'NF001', numero_titulo: '001', especie: 'NF', serie: '001', numero: '001234', parcela: 'a1', valor_bruto: 1000.00, valor_liquido: 1000.00, data_emissao: '2026-04-20', data_vencimento: '2026-04-28', status: 'aberto' },
  { filial_cnpj: '84943067001393', numero_nf: 'NF002', numero_titulo: '002', especie: 'NF', serie: '001', numero: '001235', parcela: 'a1', valor_bruto: 500.50, valor_liquido: 500.50, data_emissao: '2026-04-20', data_vencimento: '2026-04-28', status: 'aberto' },
  { filial_cnpj: '84943067001393', numero_nf: 'NF003', numero_titulo: '003', especie: 'NF', serie: '001', numero: '001236', parcela: 'a1', valor_bruto: 2500.00, valor_liquido: 2500.00, data_emissao: '2026-04-19', data_vencimento: '2026-05-10', status: 'aberto' },
  { filial_cnpj: '84943067001475', numero_nf: 'NF004', numero_titulo: '004', especie: 'NF', serie: '001', numero: '001237', parcela: 'a1', valor_bruto: 1200.00, valor_liquido: 1200.00, data_emissao: '2026-04-21', data_vencimento: '2026-04-28', status: 'aberto' },
  { filial_cnpj: '84943067001475', numero_nf: 'NF005', numero_titulo: '005', especie: 'NF', serie: '001', numero: '001238', parcela: 'a1', valor_bruto: 750.00, valor_liquido: 750.00, data_emissao: '2026-04-22', data_vencimento: '2026-05-05', status: 'aberto' },
  { filial_cnpj: '84943067001556', numero_nf: 'NF006', numero_titulo: '006', especie: 'NF', serie: '001', numero: '001239', parcela: 'a1', valor_bruto: 3000.00, valor_liquido: 3000.00, data_emissao: '2026-04-18', data_vencimento: '2026-05-15', status: 'aberto' },
  { filial_cnpj: '84943067001556', numero_nf: 'NF007', numero_titulo: '007', especie: 'NF', serie: '001', numero: '001240', parcela: 'a1', valor_bruto: 1500.00, valor_liquido: 1500.00, data_emissao: '2026-04-20', data_vencimento: '2026-04-28', status: 'aberto' },
  { filial_cnpj: '84943067001393', numero_nf: 'NF008', numero_titulo: '008', especie: 'NF', serie: '001', numero: '001241', parcela: 'a1', valor_bruto: 800.00, valor_liquido: 800.00, data_emissao: '2026-04-23', data_vencimento: '2026-05-01', status: 'aberto' },
  { filial_cnpj: '84943067001475', numero_nf: 'NF009', numero_titulo: '009', especie: 'NF', serie: '001', numero: '001242', parcela: 'a1', valor_bruto: 2200.00, valor_liquido: 2200.00, data_emissao: '2026-04-17', data_vencimento: '2026-05-12', status: 'aberto' },
  { filial_cnpj: '84943067001556', numero_nf: 'NF010', numero_titulo: '010', especie: 'NF', serie: '001', numero: '001243', parcela: 'a1', valor_bruto: 950.00, valor_liquido: 950.00, data_emissao: '2026-04-24', data_vencimento: '2026-04-30', status: 'aberto' },
];

async function insertTestData() {
  try {
    console.log('🌱 Iniciando inserção de dados de teste...\n');

    // 1. Filiais
    console.log('▸ Inserindo filiais...');
    const { data: filiaisData, error: filiaisError } = await supabase
      .from('filiais')
      .insert(TEST_FILIALS)
      .select();

    if (filiaisError) {
      console.warn(`  ⚠ Filiais: ${filiaisError.message}`);
    } else {
      console.log(`  ✅ ${filiaisData.length} filiais inseridas`);
    }

    // 2. Transacoes GETNET
    console.log('\n▸ Inserindo transações GETNET...');
    const { data: transData, error: transError } = await supabase
      .from('transacoes_getnet')
      .insert(TEST_TRANSACOES)
      .select();

    if (transError) {
      console.warn(`  ⚠ Transações: ${transError.message}`);
    } else {
      console.log(`  ✅ ${transData.length} transações inseridas`);
    }

    // 3. Titulos TOTVS
    console.log('\n▸ Inserindo títulos TOTVS...');
    const { data: titulosData, error: titulosError } = await supabase
      .from('titulos_totvs')
      .insert(TEST_TITULOS)
      .select();

    if (titulosError) {
      console.warn(`  ⚠ Títulos: ${titulosError.message}`);
    } else {
      console.log(`  ✅ ${titulosData.length} títulos inseridos`);
    }

    // 4. Map users to filials
    console.log('\n▸ Mapeando usuários às filiais...');

    try {
      const { data: { users }, error: usersError } = await supabase.auth.admin.listUsers();

      if (usersError) {
        console.warn(`  ⚠ Erro ao buscar usuários: ${usersError.message}`);
      } else {
        console.log(`  ✅ ${users.length} usuários encontrados`);

        // Map operador
        const operador = users.find(u => u.email === 'operador@test.com');
        if (operador) {
          await supabase
            .from('user_filiais')
            .upsert([
              { user_id: operador.id, filial_cnpj: '84943067001393', perfil: 'operador' },
            ], { onConflict: 'user_id,filial_cnpj' });
          console.log(`  ✅ Operador mapeado para CURITIBA`);
        }

        // Map supervisor
        const supervisor = users.find(u => u.email === 'supervisor@test.com');
        if (supervisor) {
          await supabase
            .from('user_filiais')
            .upsert([
              { user_id: supervisor.id, filial_cnpj: '84943067001393', perfil: 'supervisor' },
            ], { onConflict: 'user_id,filial_cnpj' });
          console.log(`  ✅ Supervisor mapeado para CURITIBA`);
        }

        // Map admin
        const admin = users.find(u => u.email === 'admin@test.com');
        if (admin) {
          await supabase
            .from('user_filiais')
            .upsert([
              { user_id: admin.id, filial_cnpj: '84943067001393', perfil: 'admin' },
            ], { onConflict: 'user_id,filial_cnpj' });
          console.log(`  ✅ Admin mapeado para CURITIBA`);
        }
      }
    } catch (err) {
      console.warn(`  ⚠ Erro ao mapear usuários: ${err.message}`);
    }

    console.log('\n🎉 Inserção de dados completa!');
    console.log('\n📝 Próximos passos:');
    console.log('  1. Abra http://localhost:3400/login');
    console.log('  2. Faça login com: operador@test.com / Senha123!');
    console.log('  3. Vá para /operador/lancamento');
    console.log('  4. Digite NSU: 000001419');
    console.log('  5. Deve encontrar a transação! ✅');

  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

insertTestData();
