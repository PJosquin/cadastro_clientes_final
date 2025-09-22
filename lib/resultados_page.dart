import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResultadosPage extends StatelessWidget {
  final String cpf;
  final String nome;
  final String email;
  final String telefone;
  final String aniversario;
  final String produto;
  final String marca;
  final String obs;
  final String cadastro;

  ResultadosPage({
    required this.cpf,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.aniversario,
    required this.produto,
    required this.marca,
    required this.obs,
    required this.cadastro,
  });

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('clientes');

    if (cpf.isNotEmpty) query = query.where("cpf", isEqualTo: cpf);
    if (nome.isNotEmpty) query = query.where("nome", isEqualTo: nome);
    if (email.isNotEmpty) query = query.where("email", isEqualTo: email);
    if (telefone.isNotEmpty) query = query.where("telefone", isEqualTo: telefone);
    if (aniversario.isNotEmpty) query = query.where("aniversario", isEqualTo: aniversario);
    if (produto.isNotEmpty) query = query.where("produto", isEqualTo: produto);
    if (marca.isNotEmpty) query = query.where("marca", isEqualTo: marca);
    if (obs.isNotEmpty) query = query.where("observacoes", isEqualTo: obs);
    if (cadastro.isNotEmpty) query = query.where("dataCadastro", isEqualTo: cadastro);

    return query;
  }

  String formatDate(String date) {
    try {
      final parsed = DateFormat("dd/MM/yyyy").parse(date);
      return DateFormat("dd/MM/yyyy").format(parsed);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resultados da Pesquisa")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return Center(child: Text("Nenhum cliente encontrado."));

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['nome'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CPF: ${data['cpf'] ?? ''}"),
                      Text("Telefone: ${data['telefone'] ?? ''}"),
                      Text("Data Nasc.: ${formatDate(data['aniversario'] ?? '')}"),
                      Text("Produto: ${data['produto'] ?? ''}"),
                      Text("Marca: ${data['marca'] ?? ''}"),
                      Text("Cadastro: ${formatDate(data['dataCadastro'] ?? '')}"),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
