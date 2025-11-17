// export_all_to_csv.js
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// >>> caminho da SUA chave JSON (como já usamos antes):
const serviceAccount = require('C:/Keys/firebase-sa.json');

// coleções que você quer juntar num único CSV:
const COLECOES = ['clientes', 'marcas', 'vendas'];

// separador (para Excel PT-BR é melhor ;)
const SEP = ';';

console.log('Inicializando Firebase Admin...');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

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

function toCsvField(v) {
  const raw = normalizeValueRaw(v);
  let s = String(raw);
  s = s.replace(/\r?\n/g, ' ');  // remove quebras de linha
  s = s.replace(/"/g, '""');     // escapa aspas
  return `"${s}"`;               // sempre entre aspas
}

function collectAllKeys(rows) {
  const keys = new Set(['collection', 'id']); // garantimos essas duas colunas primeiro
  for (const r of rows) {
    Object.keys(r).forEach(k => keys.add(k));
  }
  return Array.from(keys);
}

async function fetchCollectionRows(colName) {
  console.log(`\n→ Buscando documentos da coleção: ${colName}`);
  const snap = await db.collection(colName).get();
  console.log(`  Total de documentos em ${colName}: ${snap.size}`);

  const rows = [];
  let count = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const row = { collection: colName, id: doc.id };

    for (const [k, v] of Object.entries(data)) {
      row[k] = v;
    }

    rows.push(row);
    count++;
    if (count % 100 === 0) {
      console.log(`  ...já li ${count} docs de ${colName}`);
    }
  }

  return rows;
}

(async () => {
  try {
    console.log('Iniciando exportação combinada para CSV...');

    const allRows = [];

    for (const col of COLECOES) {
      const rows = await fetchCollectionRows(col);
      allRows.push(...rows);
    }

    if (allRows.length === 0) {
      console.log('Nenhum documento encontrado em nenhuma coleção.');
      process.exit(0);
    }

    console.log('\nMontando cabeçalhos globais...');
    const headers = collectAllKeys(allRows);

    const lines = [];
    lines.push(headers.map(h => toCsvField(h)).join(SEP)); // cabeçalho

    console.log('Gerando linhas do CSV único...');
    allRows.forEach((r, idx) => {
      const line = headers
        .map(h => {
          const val = r[h] !== undefined ? r[h] : '';
          return toCsvField(val);
        })
        .join(SEP);
      lines.push(line);
      if ((idx + 1) % 200 === 0) {
        console.log(`  ...${idx + 1} linhas geradas`);
      }
    });

    const stamp = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
    const outDir = path.join(process.cwd(), `csv_export_${stamp}`);
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir);
    }

    const outFile = path.join(outDir, `firestore_all_${stamp}.csv`);
    const csvContent = '\uFEFF' + lines.join('\n'); // BOM p/ Excel

    fs.writeFileSync(outFile, csvContent, 'utf8');
    console.log(`\n✅ CSV único gerado: ${outFile}`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Erro no export combinado:', err);
    process.exit(1);
  }
})();
