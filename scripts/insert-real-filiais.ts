import { createClient } from '@supabase/supabase-js';
import XLSX from 'xlsx';
import * as path from 'path';
import * as fs from 'fs';
import * as dotenv from 'dotenv';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load env
dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('❌ Credenciais Supabase não encontradas em .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey);

interface ExcelRow {
  [key: string]: string | number;
}

interface Filial {
  filial_cnpj: string;
  codigo_ec: string;
  razao_social: string;
}

// Generate random NSU (9 digits)
function generateNSU(): string {
  return String(Math.floor(Math.random() * 999999999)).padStart(9, '0');
}

// Generate random authorization code
function generateAuth(): string {
  return `AUTH${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
}

// Generate random value between min and max
function randomValue(min: number, max: number): number {
  return Math.round((Math.random() * (max - min) + min) * 100) / 100;
}

// Generate random date in last 30 days
function randomDate(): string {
  const now = new Date();
  const days = Math.floor(Math.random() * 30);
  const date = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
  return date.toISOString().split('T')[0];
}

// Generate random time
function randomTime(): string {
  const h = String(Math.floor(Math.random() * 24)).padStart(2, '0');
  const m = String(Math.floor(Math.random() * 60)).padStart(2, '0');
  const s = String(Math.floor(Math.random() * 60)).padStart(2, '0');
  return `${h}:${m}:${s}`;
}

// Generate random card brand
function randomBandeira(): string {
  return ['Visa', 'Mastercard', 'Elo', 'American Express'][Math.floor(Math.random() * 4)];
}

async function insertRealFiliais() {
  try {
    console.log('\n🌱 Iniciando inserção de dados reais das filiais...\n');

    // Find Excel file
    const excelFileName = '@CNPJ-GERENTES-GETNET.xlsx';
    const excelPath = path.resolve(__dirname, '../', excelFileName);

    if (!fs.existsSync(excelPath)) {
      console.error(`❌ Arquivo não encontrado: ${excelPath}`);
      console.error(`📁 Arquivos disponíveis em ${path.resolve(__dirname, '../')}:`);
      const files = fs.readdirSync(path.resolve(__dirname, '../'));
      files.filter(f => f.endsWith('.xlsx')).forEach(f => console.error(`   - ${f}`));
      process.exit(1);
    }

    // Read Excel file
    console.log(`📖 Lendo arquivo: ${excelFileName}`);
    const workbook = XLSX.readFile(excelPath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const rawData = XLSX.utils.sheet_to_json<ExcelRow>(worksheet);

    console.log(`  ✅ ${rawData.length} linhas lidas da planilha\n`);

    // Parse filiais from Excel
    const filiais: Filial[] = [];
    for (let i = 0; i < rawData.length; i++) {
      const row = rawData[i];

      // Extract CNPJ parts
      const cnpjPart1 = String(row['CNPJ'] || '').trim(); // '00-', '01-', etc
      const cnpjPart2 = String(row['84.943.067/'] || '').trim(); // '0019-89', etc

      // Extract other fields
      const getnetCode = String(row['GETNET'] || '').trim();
      const filialName = String(row['FILIAL'] || '').trim();
      const estado = String(row['__EMPTY'] || '').trim();
      const gerente = String(row['GERENTES'] || '').trim();

      // Skip header rows or invalid data
      if (!getnetCode || getnetCode === 'GETNET' || !filialName) continue;

      // Reconstruct CNPJ: 84943067 + filial sequence + branch code
      // Format: 84.943.067/0001-89 -> 84943067001389
      const filialSeq = cnpjPart1.replace('-', '').padStart(4, '0'); // '00-' -> '0000', '01-' -> '0100', etc
      const branchCode = cnpjPart2.replace('-', '').padStart(5, '0'); // '0019-89' -> '001989'
      const cnpj = `84943067${filialSeq}${branchCode}`.substring(0, 14).padEnd(14, '0');

      const razaoSocial = `MINUSA FILIAL ${filialName.toUpperCase()} - ${gerente}`;

      filiais.push({
        filial_cnpj: cnpj,
        codigo_ec: getnetCode,
        razao_social: razaoSocial,
      });
    }

    console.log(`📊 Filiais extraídas do Excel: ${filiais.length}\n`);

    let totalFiliais = 0;
    let totalTransacoes = 0;
    let totalTitulos = 0;

    // Process each filial
    for (let i = 0; i < filiais.length; i++) {
      const filial = filiais[i];

      // 1. Insert filial
      const { error: filialError } = await supabase
        .from('filiais')
        .upsert([filial], { onConflict: 'filial_cnpj' });

      if (!filialError) {
        totalFiliais++;
        console.log(`[${i + 1}/${filiais.length}] ✅ ${filial.razao_social}`);
      } else {
        console.log(`[${i + 1}/${filiais.length}] ⚠️ ${filial.razao_social} - ${filialError.message}`);
        continue;
      }

      // 2. Generate transactions (5-10 per filial)
      const transCount = Math.floor(Math.random() * 6) + 5;
      const transactions = [];

      for (let j = 0; j < transCount; j++) {
        transactions.push({
          filial_cnpj: filial.filial_cnpj,
          nsu: generateNSU(),
          codigo_ec: filial.codigo_ec,
          autorizacao: generateAuth(),
          data_venda: randomDate(),
          hora_venda: randomTime(),
          valor_venda: randomValue(50, 5000),
          bandeira: randomBandeira(),
          status: 'pendente',
          hash_transacao: `hash_${Math.random().toString(36).substring(2, 15)}`,
        });
      }

      const { error: transError } = await supabase
        .from('transacoes_getnet')
        .insert(transactions);

      if (!transError) {
        totalTransacoes += transCount;
      }

      // 3. Generate invoices (5-10 per filial)
      const invoiceCount = Math.floor(Math.random() * 6) + 5;
      const invoices = [];

      for (let j = 0; j < invoiceCount; j++) {
        const issueDate = randomDate();
        const dueDate = new Date(new Date(issueDate).getTime() + Math.floor(Math.random() * 30) * 24 * 60 * 60 * 1000)
          .toISOString()
          .split('T')[0];

        const valor = randomValue(100, 10000);
        const clienteCode = String(Math.floor(Math.random() * 99999)).padStart(5, '0');
        const clienteNames = ['Cliente A', 'Cliente B', 'Cliente C', 'Fornecedor X', 'Fornecedor Y', 'Empresa Z'];
        const clienteName = clienteNames[Math.floor(Math.random() * clienteNames.length)];

        invoices.push({
          filial_cnpj: filial.filial_cnpj,
          numero_nf: `NF${String(totalTitulos + j + 1).padStart(6, '0')}`,
          numero_titulo: `TIT${String(totalTitulos + j + 1).padStart(6, '0')}`,
          data_emissao: issueDate,
          data_vencimento: dueDate,
          valor_bruto: valor,
          valor_liquido: valor,
          cliente_codigo: clienteCode,
          cliente_nome: clienteName,
        });
      }

      const { error: invoiceError } = await supabase
        .from('titulos_totvs')
        .insert(invoices);

      if (!invoiceError) {
        totalTitulos += invoiceCount;
      }

      console.log(`         ├─ 📦 ${transCount} transações | 📋 ${invoiceCount} títulos`);
    }

    console.log('\n' + '='.repeat(60));

    // Map users to filials
    console.log('🔐 Mapeando usuários às filiais...\n');

    const { data: { users }, error: usersError } = await supabase.auth.admin.listUsers();

    if (!usersError && users) {
      const operador = users.find(u => u.email === 'operador@test.com');
      const supervisor = users.find(u => u.email === 'supervisor@test.com');
      const admin = users.find(u => u.email === 'admin@test.com');

      // Map operador to first filial (SC)
      if (operador && filiais.length > 0) {
        const { error } = await supabase
          .from('user_filiais')
          .upsert([
            {
              user_id: operador.id,
              filial_cnpj: filiais[0].filial_cnpj,
              perfil: 'operador',
            },
          ], { onConflict: 'user_id,filial_cnpj' });

        if (!error) {
          console.log(`  ✅ operador@test.com → ${filiais[0].razao_social}`);
        }
      }

      // Map supervisor to all filiais
      if (supervisor) {
        for (const filial of filiais) {
          await supabase
            .from('user_filiais')
            .upsert([
              {
                user_id: supervisor.id,
                filial_cnpj: filial.filial_cnpj,
                perfil: 'supervisor',
              },
            ], { onConflict: 'user_id,filial_cnpj' });
        }
        console.log(`  ✅ supervisor@test.com → todas as ${filiais.length} filiais`);
      }

      // Map admin to all filiais
      if (admin) {
        for (const filial of filiais) {
          await supabase
            .from('user_filiais')
            .upsert([
              {
                user_id: admin.id,
                filial_cnpj: filial.filial_cnpj,
                perfil: 'admin',
              },
            ], { onConflict: 'user_id,filial_cnpj' });
        }
        console.log(`  ✅ admin@test.com → todas as ${filiais.length} filiais`);
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('\n✨ INSERÇÃO DE DADOS REAIS CONCLUÍDA!\n');
    console.log('📊 RESUMO:');
    console.log(`   ✅ ${totalFiliais} filiais inseridas`);
    console.log(`   ✅ ${totalTransacoes} transações geradas`);
    console.log(`   ✅ ${totalTitulos} títulos gerados`);
    console.log('\n🎯 PRÓXIMOS PASSOS:');
    console.log('   1. npm run dev');
    console.log('   2. Abra http://localhost:3400/login');
    console.log('   3. Login: operador@test.com / Senha123!');
    console.log('   4. Acesse /operador/lancamento para testar');
    console.log('\n');

  } catch (error) {
    console.error('\n❌ ERRO:', error instanceof Error ? error.message : error);
    console.error('\n');
    process.exit(1);
  }
}

insertRealFiliais();
