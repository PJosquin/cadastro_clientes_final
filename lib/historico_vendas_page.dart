import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoricoVendasPage extends StatelessWidget {
  final String clienteId;
  final String nomeCliente;

  const HistoricoVendasPage({
    Key? key,
    required this.clienteId,
    required this.nomeCliente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
 print('🟢 Cliente ID recebido: $clienteId | Nome: $nomeCliente');
    return Scaffold(
      appBar: AppBar(title: Text('Histórico de Vendas - $nomeCliente')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendas')
            .where('clienteId', isEqualTo: clienteId)
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

          return ListView.builder(
            itemCount: vendas.length,
            itemBuilder: (context, index) {
              final data = vendas[index].data() as Map<String, dynamic>;
              final valor = data['valor'] ?? 0;
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
