import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ ADICIONE ESTA LINHA

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

          // 🔹 Cálculo do somatório
          double totalValor = 0;
          int totalPecas = 0;

          for (var doc in vendas) {
            final data = doc.data() as Map<String, dynamic>;
            totalValor += (data['valor'] ?? 0).toDouble();
            totalPecas += ((data['numero_pecas'] ?? 0) as num).toInt();
          }

          return Column(
            children: [
              // 🔹 Faixa azul com totais
              Container(
                width: double.infinity,
                color: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '💰 TOTAL DE VENDAS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vendas registradas: ${vendas.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Total de peças: $totalPecas',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Valor total: R\$ ${totalValor.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Lista de vendas
              Expanded(
                child: ListView.builder(
                  itemCount: vendas.length,
                  itemBuilder: (context, index) {
                    final data = vendas[index].data() as Map<String, dynamic>;
                    final valor = (data['valor'] ?? 0).toDouble();
                    final pecas = (data['numero_pecas'] ?? 0).toInt();
                    final nota = data['numero_nota'] ?? '';
                    final obs = data['observacoes'] ?? '';
                    final dataVenda = (data['data'] as Timestamp).toDate();
                    final dataFormatada =
                        DateFormat('dd/MM/yyyy HH:mm').format(dataVenda);

 return Card(
  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
  child: ListTile(
    leading: const Icon(Icons.shopping_bag, color: Colors.blue),
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'R\$ ${valor.toStringAsFixed(2)} - $pecas peça(s)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if ((data['qrcode'] ?? '').toString().isNotEmpty)
          IconButton(
            tooltip: 'Abrir Nota Fiscal',
            icon: const Icon(Icons.link, color: Colors.blueAccent),
            onPressed: () async {
              var url = (data['qrcode'] ?? '').toString().trim();
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'https://' + url;
              }

              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Endereço inválido: $url')),
                );
              }
            },
          ),
      ],
    ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
