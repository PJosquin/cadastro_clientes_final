// export_to_csv.js
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// >>> AJUSTE AQUI O CAMINHO DA SUA CHAVE JSON:
const serviceAccount = require('C:/Keys/firebase-sa.json');

// Coleções que você quer exportar:
// comece com apenas 'clientes' para testar
const COLECOES = ['clientes']; // depois você volta 'marcas', 'vendas'

// Separador de campos no CSV:
const SEP = ';';

console.log('Inicializando Firebase Admin...');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Converte valor do Firestore para algo mais simples.
 */
function normalizeValueRaw(v) {
  if (v === null || v === undefined) return '';
  if (v && typeof v.toDate === 'function') {
    return v.toDate().toISOString();
  }
  if (Array.isArray(v) || (typeof v === 'object' && v !== null)) {
    return JSON.stringify(v);
  }
  return v;
}

/**
 * Escapa valor para CSV.
 */
function toCsvField(v) {
  const raw = normalizeValueRaw(v);
  let s = String(raw);
  s = s.replace(/\r?\n/g, ' '); // tira quebras de linha
  s = s.replace(/"/g, '""');   // escapa aspas
  return `"${s}"`;
}

/**
 * Coleta todas as chaves possíveis.
 */
function collectAllKeys(rows) {
  const keys = new Set();
  for (const r of rows) {
    Object.keys(r).forEach(k => keys.add(k));
  }
  return Array.from(keys);
}

/**
 * Exporta uma coleção para CSV.
 */
async function exportCollectionToCsv(colName, outDir) {
  console.log(`\n→ Exportando coleção: ${colName}`);

  const colRef = db.collection(colName);

  console.log('  Buscando documentos do Firestore...');
  const snap = await colRef.get();
  console.log(`  Total de documentos em ${colName}: ${snap.size}`);

  const rows = [];

  let count = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const row = { id: doc.id };

    for (const [k, v] of Object.entries(data)) {
      row[k] = v;
    }

    rows.push(row);
    count++;

    // log a cada 100 docs para saber que está andando
    if (count % 100 === 0) {
      console.log(`  ...já li ${count} documentos de ${colName}`);
    }
  }

  if (rows.length === 0) {
    console.log(`  (sem documentos em ${colName})`);
    const emptyPath = path.join(outDir, `${colName}_vazio.csv`);
    fs.writeFileSync(emptyPath, 'id\n', 'utf8');
    console.log(`✔ CSV vazio criado: ${emptyPath}`);
    return;
  }

  console.log('  Montando cabeçalhos...');
  const headers = collectAllKeys(rows);

  const lines = [];
  lines.push(headers.map(h => toCsvField(h)).join(SEP)); // cabeçalho

  console.log('  Gerando linhas de CSV...');
  rows.forEach((r, idx) => {
    const line = headers.map(h => {
      const val = r[h] !== undefined ? r[h] : '';
      return toCsvField(val);
    }).join(SEP);
    lines.push(line);
    if ((idx + 1) % 100 === 0) {
      console.log(`  ...${idx + 1} linhas geradas`);
    }
  });

  const stamp = new Date().toISOString().slice(0, 10);
  const outDirFull = path.join(process.cwd(), `csv_export_${stamp}`);
  if (!fs.existsSync(outDirFull)) {
    fs.mkdirSync(outDirFull);
  }
  const outFile = path.join(outDirFull, `${colName}_${stamp}.csv`);

  console.log('  Salvando arquivo CSV...');
  const csvContent = '\uFEFF' + lines.join('\n');
  fs.writeFileSync(outFile, csvContent, 'utf8');
  console.log(`✔ ${colName}: ${rows.length} documento(s) -> ${outFile}`);
}

/**
 * Função principal
 */
(async () => {
  try {
    console.log('Iniciando export CSV Firestore...');
    for (const col of COLECOES) {
      await exportCollectionToCsv(col);
    }
    console.log('\n✅ Export concluído com sucesso.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Erro no export:', err);
    process.exit(1);
  }
})();
