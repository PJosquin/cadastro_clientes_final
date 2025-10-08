import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({Key? key}) : super(key: key);

  @override
  State<RegistroVendaPage> createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final TextEditingController buscaController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController pecasController = TextEditingController();
  final TextEditingController notaController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();

  List<QueryDocumentSnapshot> resultados = [];
  Map<String, dynamic>? clienteSelecionado;

  Future<void> buscarClientes(String termo) async {
    termo = termo.toLowerCase().trim();
    if (termo.isEmpty) {
      setState(() => resultados = []);
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('clientes').get();

    setState(() {
      resultados = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['nome'] ?? '').toString().toLowerCase().contains(termo) ||
            (data['telefone'] ?? '').toString().toLowerCase().contains(termo) ||
            (data['cpf'] ?? '').toString().toLowerCase().contains(termo) ||
            (data['email'] ?? '').toString().toLowerCase().contains(termo);
      }).toList();
    });
  }

  Future<void> salvarVenda() async {
    if (clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente antes de salvar.')),
      );
      return;
    }

    final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0;
    final pecas = int.tryParse(pecasController.text) ?? 0;
    final nota = notaController.text.trim();
    final obs = observacoesController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('vendas').add({
        'clienteId': clienteSelecionado!['id'],
        'nome': clienteSelecionado!['nome'],
        'cpf': clienteSelecionado!['cpf'],
        'telefone': clienteSelecionado!['telefone'],
        'email': clienteSelecionado!['email'],
        'valor': valor,
        'numero_pecas': pecas,
        'numero_nota': nota,
        'observacoes': obs,
        'data': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda registrada com sucesso!')),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar venda: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venda')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 🔍 Campo de busca de cliente
            TextField(
              controller: buscaController,
              decoration: const InputDecoration(
                labelText: 'Buscar cliente (nome, CPF, telefone, e-mail)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: buscarClientes,
            ),
            const SizedBox(height: 10),

            // 🔽 Lista de resultados
            ...resultados.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(data['nome'] ?? ''),
                  subtitle: Text(
                      'CPF: ${data['cpf'] ?? ''} • Tel: ${data['telefone'] ?? ''}'),
                  onTap: () {
                    setState(() {
                      clienteSelecionado = {...data, 'id': doc.id};
                      resultados = [];
                      buscaController.text = data['nome'] ?? '';
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            // 👤 Cliente selecionado
            if (clienteSelecionado != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${clienteSelecionado!['nome']}  —  CPF: ${clienteSelecionado!['cpf']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 💰 Campos da venda
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da Venda (R\$)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pecasController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Número de Peças'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notaController,
              decoration:
                  const InputDecoration(labelText: 'Número da Nota Fiscal'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar Venda'),
              onPressed: salvarVenda,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
