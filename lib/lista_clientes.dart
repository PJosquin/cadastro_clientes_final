import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ListaClientesPage extends StatelessWidget {
  final Query<Map<String, dynamic>>? query;
  const ListaClientesPage({super.key, this.query});

  String _fmt(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) return DateFormat('dd/MM/yyyy').format(v.toDate());
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final q = query ?? FirebaseFirestore.instance.collection('clientes');

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Clientes')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Erro ao carregar'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhum cliente encontrado.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final c = docs[i].data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(c['nome'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CPF: ${c['cpf'] ?? ''}'),
                      Text('E-mail: ${c['email'] ?? ''}'),
                      Text('Telefone: ${c['telefone'] ?? ''}'),
                      Text('Aniversário: ${_fmt(c['aniversario'])}'),
                      Text('Produto: ${c['produto'] ?? ''}'),
                      Text('Marca: ${c['marca'] ?? ''}'),
                      Text('Observações: ${c['observacoes'] ?? ''}'),
                      Text('Cadastro: ${_fmt(c['dataCadastro'])}'),
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
