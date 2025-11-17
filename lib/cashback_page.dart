// lib/cashback_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CashbackPage extends StatefulWidget {
  const CashbackPage({Key? key}) : super(key: key);

  @override
  State<CashbackPage> createState() => _CashbackPageState();
}

class _CashbackPageState extends State<CashbackPage> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final clientesRef = FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('nome');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashback dos Clientes'),
      ),
      body: Column(
        children: [
          // 🔎 Campo de busca (nome)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar cliente por nome',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filtro = v.trim().toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: clientesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // 🔍 Filtra por nome
                final filtrados = docs.where((d) {
                  final nome = (d['nome'] ?? '').toString().toLowerCase();
                  return nome.contains(_filtro);
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum cliente encontrado.'),
                  );
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final doc = filtrados[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final nome = (data['nome'] ?? '').toString();
                    final telefone = (data['telefone'] ?? '').toString();

                    double cashback = 0.0;
                    final cb = data['cashback_acumulado'];
                    if (cb is num) {
                      cashback = cb.toDouble();
                    } else if (cb is String) {
                      cashback = double.tryParse(cb.replaceAll(',', '.')) ?? 0.0;
                    }

                    final temCashback = cashback > 0;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(nome),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (telefone.isNotEmpty)
                            Text('Telefone: $telefone'),
                          Text('Cashback: R\$ ${cashback.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: temCashback
                          ? const Icon(Icons.monetization_on,
                              color: Colors.green)
                          : const Icon(Icons.money_off),
                      onTap: () {
                        // Futuro: abrir detalhes ou permitir ajustes
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Cliente: $nome — Cashback R\$ ${cashback.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
