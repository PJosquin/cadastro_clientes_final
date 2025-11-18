// lib/historico_vendas_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    final formatoData = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    final query = FirebaseFirestore.instance
        .collection('vendas')
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('data', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Vendas - $nomeCliente'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar vendas: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma venda registrada para este cliente.'),
            );
          }

          // 🔹 Calcula totais
          double totalBruto = 0.0;
          double totalLiquido = 0.0;
          double totalCashbackGerado = 0.0;
          double totalDescontoCashback = 0.0;

          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;

            final vBruto = _asDouble(data['valor']);
            final vLiq = _asDouble(data['valor_liquido']);
            final cbGerado = _asDouble(data['cashback_gerado']);
            final descCb = _asDouble(data['desconto_cashback']);

            totalBruto += vBruto;
            totalLiquido += vLiq;
            totalCashbackGerado += cbGerado;
            totalDescontoCashback += descCb;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length + 1, // +1 para o card de resumo
            itemBuilder: (context, index) {
              if (index == 0) {
                // 🔷 Card de resumo no topo
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo de Cashback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total bruto vendido: R\$ ${totalBruto.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total desconto com cashback: R\$ ${totalDescontoCashback.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total líquido recebido: R\$ ${totalLiquido.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total de cashback gerado: R\$ ${totalCashbackGerado.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // A partir daqui, são as vendas (index - 1)
              final doc = docs[index - 1];
              final data = doc.data() as Map<String, dynamic>;

              final timestamp = data['data'] as Timestamp?;
              final dt = timestamp?.toDate();
              final dataFormatada =
                  dt != null ? formatoData.format(dt) : 'Sem data';

              final numeroNota = (data['numero_nota'] ?? '').toString();
              final numeroPecas =
                  int.tryParse((data['numero_pecas'] ?? '').toString());

              final valorBruto = _asDouble(data['valor']);
              final valorLiquido = _asDouble(data['valor_liquido']);
              final descontoCashback = _asDouble(data['desconto_cashback']);
              final cashbackGerado = _asDouble(data['cashback_gerado']);
              final percentual = _asDouble(data['percentual_cashback']);

              final observacoes = (data['observacoes'] ?? '').toString();

              final bool teveUsoCashback = descontoCashback > 0.009;
              final bool teveGeracaoCashback = cashbackGerado > 0.009;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha principal: data + nota
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dataFormatada,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (numeroNota.isNotEmpty)
                            Text(
                              'NF: $numeroNota',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (numeroPecas != null && numeroPecas > 0)
                        Text(
                          'Peças: $numeroPecas',
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 8),

                      // Valores
                      Text(
                        'Valor bruto: R\$ ${valorBruto.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (teveUsoCashback)
                        Text(
                          'Desconto com cashback: R\$ ${descontoCashback.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.redAccent,
                          ),
                        ),
                      if (teveUsoCashback || valorLiquido > 0.009)
                        Text(
                          'Valor líquido: R\$ ${valorLiquido.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 6),

                      // Cashback gerado
                      if (teveGeracaoCashback)
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cashback gerado: R\$ ${cashbackGerado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                      if (percentual > 0.0001)
                        Text(
                          'Percentual de cashback: ${(percentual * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 13),
                        ),

                      if (observacoes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Obs: $observacoes',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
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

  // Helper para converter qualquer coisa em double com segurança
  static double _asDouble(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is num) return valor.toDouble();
    if (valor is String) {
      return double.tryParse(valor.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}
