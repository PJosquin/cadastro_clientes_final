import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResultadoPesquisaPage extends StatelessWidget {
  final Map<String, String> filtros;

  ResultadoPesquisaPage({required this.filtros});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resultado da Pesquisa")),
      body: FutureBuilder<QuerySnapshot>(
        future: _buildQuery().get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nenhum cliente encontrado."));
          }

          final clientes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(cliente['nome'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CPF: ${cliente['cpf'] ?? ''}"),
                      Text("Telefone: ${cliente['telefone'] ?? ''}"),
                      Text("Produto: ${cliente['produto'] ?? ''}"),
                      Text("Marca: ${cliente['marca'] ?? ''}"),
                      Text("Observações: ${cliente['observacoes'] ?? ''}"),
                      if (cliente['dataCadastro'] != null)
                        Text(
                          "Cadastro: ${DateFormat('dd/MM/yyyy').format((cliente['dataCadastro'] as Timestamp).toDate())}",
                        ),
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

  /// Monta a query do Firestore com base nos filtros informados
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('clientes');

    filtros.forEach((campo, valor) {
      if (valor.isNotEmpty) {
        switch (campo) {
          case 'nome':
          case 'produto':
            query = query
                .where(campo, isGreaterThanOrEqualTo: valor.toLowerCase())
                .where(campo, isLessThanOrEqualTo: valor.toLowerCase() + '\uf8ff');
            break;

          case 'aniversario':
          case 'dataCadastro':
            try {
              final date = DateFormat('dd/MM/yyyy').parse(valor);
              final start = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
              final end = Timestamp.fromDate(
                  DateTime(date.year, date.month, date.day, 23, 59, 59));
              query = query.where(campo, isGreaterThanOrEqualTo: start, isLessThanOrEqualTo: end);
            } catch (e) {
              print("Erro ao converter data: $e");
            }
            break;

          default:
            query = query.where(campo, isEqualTo: valor);
        }
      }
    });

    return query;
  }
}
