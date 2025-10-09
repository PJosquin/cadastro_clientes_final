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
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Vendas - $nomeCliente'),
        backgroundColor: const Color(0xFF1976D2),
      ),
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
            return const Center(
              child: Text(
                'Nenhuma venda registrada.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final vendas = snapshot.data!.docs;

          // 🔢 Calcular total de vendas e peças
          double totalVendas = 0;
          int totalPecas = 0;

          for (var doc in vendas) {
            final data = doc.data() as Map<String, dynamic>;
            totalVendas += (data['valor'] ?? 0).toDouble();
            totalPecas += (data['numero_pecas'] ?? 0) as int;
          }

          return Column(
            children: [
              // 🧮 Cabeçalho com totais
              Container(
                width: double.infinity,
                color: const Color(0xFF1976D2),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Total de Vendas: R\$ ${totalVendas.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total de Peças Vendidas: $totalPecas',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // 📋 Lista de vendas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: vendas.length,
                  itemBuilder: (context, index) {
                    final data = vendas[index].data() as Map<String, dynamic>;
                    final valor = (data['valor'] ?? 0).toDouble();
                    final pecas = data['numero_pecas'] ?? 0;
                    final nota = data['numero_nota'] ?? '';
                    final obs = data['observacoes'] ?? '';
                    final dataVenda = (data['data'] as Timestamp).toDate();
                    final dataFormatada =
                        DateFormat('dd/MM/yyyy HH:mm').format(dataVenda);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFF1976D2),
                        ),
                        title: Text(
                          'R\$ ${valor.toStringAsFixed(2)} - $pecas peça(s)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nota.isNotEmpty) Text('Nota: $nota'),
                              if (obs.isNotEmpty) Text('Obs: $obs'),
                              Text('Data: $dataFormatada'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
