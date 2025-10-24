import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _mostrarBotaoTopo = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_mostrarBotaoTopo) {
        setState(() => _mostrarBotaoTopo = true);
      } else if (_scrollController.offset <= 400 && _mostrarBotaoTopo) {
        setState(() => _mostrarBotaoTopo = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Vendas'),
        centerTitle: true,
      ),
      floatingActionButton: _mostrarBotaoTopo
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
            )
          : null,
      body: Column(
        children: [
          // 🔹 Faixa fixa com o nome do cliente
          Container(
            width: double.infinity,
            color: Colors.blue.shade100,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              widget.nomeCliente,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),

          // 🔹 Conteúdo rolável (totais + lista de vendas)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(
                    child: Text(
                      'Nenhuma venda registrada.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final vendas = snapshot.data!.docs;

                // 🔹 Cálculo do somatório
                double totalValor = 0;
                int totalPecas = 0;
                for (var doc in vendas) {
                  final data = doc.data() as Map<String, dynamic>;

                  // ✅ Conversão segura de valor e peças
                  final valor = (data['valor'] is num)
                      ? (data['valor'] as num).toDouble()
                      : double.tryParse(data['valor'].toString()) ?? 0.0;

                  final pecas = (data['numero_pecas'] is num)
                      ? (data['numero_pecas'] as num).toInt()
                      : int.tryParse(data['numero_pecas'].toString()) ?? 0;

                  totalValor += valor;
                  totalPecas += pecas;
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // 🔹 Faixa azul com totais
                      Container(
                        width: double.infinity,
                        color: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '💰 TOTAL DE VENDAS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Vendas registradas: ${vendas.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              'Total de peças: $totalPecas',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
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

                      const SizedBox(height: 10),

                      // 🔹 Lista de vendas
                      ListView.builder(
                        itemCount: vendas.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final data =
                              vendas[index].data() as Map<String, dynamic>;

                          // ✅ Conversão segura dentro do item
                          final valor = (data['valor'] is num)
                              ? (data['valor'] as num).toDouble()
                              : double.tryParse(data['valor'].toString()) ?? 0.0;

                          final pecas = (data['numero_pecas'] is num)
                              ? (data['numero_pecas'] as num).toInt()
                              : int.tryParse(data['numero_pecas'].toString()) ??
                                  0;

                          final nota = data['numero_nota'] ?? '';
                          final obs = data['observacoes'] ?? '';
                          final qrcode =
                              (data['qrcode'] ?? '').toString().trim();
                          final dataVenda =
                              (data['data'] as Timestamp).toDate();
                          final dataFormatada =
                              DateFormat('dd/MM/yyyy HH:mm').format(dataVenda);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 10),
                            child: ListTile(
                              leading: const Icon(Icons.shopping_bag,
                                  color: Colors.blue),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'R\$ ${valor.toStringAsFixed(2)} - $pecas peça(s)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (qrcode.isNotEmpty)
                                    IconButton(
                                      tooltip: 'Abrir Nota Fiscal',
                                      icon: const Icon(Icons.link,
                                          color: Colors.blueAccent),
                                      onPressed: () async {
                                        var url = qrcode;
                                        if (!url.startsWith('http://') &&
                                            !url.startsWith('https://')) {
                                          url = 'https://' + url;
                                        }
                                        final uri = Uri.tryParse(url);
                                        if (uri != null) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Endereço inválido: $url'),
                                            ),
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
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

