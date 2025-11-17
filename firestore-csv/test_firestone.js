const admin = require('firebase-admin');

// AJUSTE o caminho da chave JSON:
const serviceAccount = require('C:/keys/firebase-sa.json';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  console.log('Iniciando teste Firestore...');
  try {
    const snap = await db.collection('clientes').limit(5).get();
    console.log(`OK! Consegui ler a coleção 'clientes'. Qtd docs lidos: ${snap.size}`);
    snap.forEach(doc => {
      console.log(' - doc id:', doc.id);
    });
  } catch (e) {
    console.error('ERRO ao acessar Firestore:', e);
  } finally {
    process.exit(0);
  }
})();
