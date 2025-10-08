import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoricoVendasPage extends StatefulWidget {
  final String clienteId;
  final String nomeCliente;

  const HistoricoVendasPage({
    Key? key,
    required this.clienteId,
    required this.nomeCliente,
  }) : super(key: key);

  @override
  State<HistoricoVendasPage> createState() => _HistoricoVendasPageState();
}

class _HistoricoVendasPageState extends State<HistoricoVendasPage> {
  double totalValor = 0;
  int totalPecas = 0;

  void calcularTotais(QuerySnapshot snapshot) {
    double soma = 0;
    int pecas = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      soma += (data['valor'] ?? 0).toDouble();
      pecas += (data['numero_pecas'] ?? 0) as int;
    }
    setState(() {
      totalValor = soma;
      totalPecas = pecas;
    });
  }

  Future<void> excluirVenda(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir venda'),
        content: const Text('Tem certeza que deseja excluir esta venda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('vendas').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda excluída com sucesso.')),
      );
    }
  }

  Future<void> editarVenda(DocumentSnapshot venda) async {
    final data = venda.data() as Map<String, dynamic>;
    final TextEditingController notaController =
        TextEditingController(text: data['numero_nota'] ?? '');
    final TextEditingController obsController =
        TextEditingController(text: data['observacoes'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Venda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: notaController, decoration: const InputDecoration(labelText: 'Número da Nota')),
            const SizedBox(height: 8),
            TextField(controller: obsController, decoration: const InputDecoration(labelText: 'Observações')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('vendas').doc(venda.id).update({
                'numero_nota': notaController.text.trim(),
                'observacoes': obsController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venda atualizada com sucesso.')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histórico de Vendas - ${widget.nomeCliente}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendas')
            .where('clienteId', isEqualTo: widget.clienteId)
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma venda registrada.'));
          }

        final vendas = snapshot.data!.docs;

// Evita loop infinito de rebuilds
double soma = 0;
int pecas = 0;
for (var doc in vendas) {
  final data = doc.data() as Map<String, dynamic>;
  soma += (data['valor'] ?? 0).toDouble();
  pecas += (data['numero_pecas'] ?? 0) as int;
}
if (soma != totalValor || pecas != totalPecas) {
  totalValor = soma;
  totalPecas = pecas;
}



          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: vendas.length,
                  itemBuilder: (context, index) {
                    final doc = vendas[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final valor = (data['valor'] ?? 0).toDouble();
                    final pecas = data['numero_pecas'] ?? 0;
                    final nota = data['numero_nota'] ?? '';
                    final obs = data['observacoes'] ?? '';
                    final dataVenda = (data['data'] as Timestamp).toDate();
                    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dataVenda);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                        title: Text('R\$ ${valor.toStringAsFixed(2)} - $pecas peça(s)'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nota.isNotEmpty) Text('Nota: $nota'),
                            if (obs.isNotEmpty) Text('Obs: $obs'),
                            Text('Data: $dataFormatada'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') editarVenda(doc);
                            if (value == 'excluir') excluirVenda(doc.id);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'editar', child: Text('Editar')),
                            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rodapé com totais
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total de vendas: ${vendas.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Peças: $totalPecas', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('R\$ ${totalValor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
