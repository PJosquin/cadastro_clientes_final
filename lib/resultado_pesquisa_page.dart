import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResultadoPesquisaPage extends StatelessWidget {
  final String cpf;
  final String nome;
  final String email;
  final String telefone;
  final String aniversario;
  final String produto;
  final String marca;
  final String observacoes;
  final String dataCadastro;

  ResultadoPesquisaPage({
    this.cpf = "",
    this.nome = "",
    this.email = "",
    this.telefone = "",
    this.aniversario = "",
    this.produto = "",
    this.marca = "",
    this.observacoes = "",
    this.dataCadastro = "",
  });

  // Função para formatar datas
  String formatDate(dynamic date) {
    if (date == null) return "";
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    } else if (date is String && date.isNotEmpty) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
      } catch (_) {
        return date;
      }
    }
    return "";
  }

  // Normaliza strings para comparação
  String normalize(String input) {
    return input.toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resultado da Pesquisa")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('clientes').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nenhum cliente encontrado."));
          }

          var clientes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Comparações exatas (com máscara aplicada no cadastro)
            if (cpf.isNotEmpty && data['cpf'] != cpf) return false;
            if (telefone.isNotEmpty && data['telefone'] != telefone) return false;
            if (email.isNotEmpty && normalize(data['email'] ?? "") != normalize(email)) return false;
            if (aniversario.isNotEmpty && data['aniversario'] != aniversario) return false;
            if (marca.isNotEmpty && normalize(data['marca'] ?? "") != normalize(marca)) return false;
            if (observacoes.isNotEmpty &&
                !normalize(data['observacoes'] ?? "").contains(normalize(observacoes))) return false;

            // Busca parcial para nome e produto
            if (nome.isNotEmpty &&
                !normalize(data['nome'] ?? "").contains(normalize(nome))) return false;

            if (produto.isNotEmpty &&
                !normalize(data['produto'] ?? "").contains(normalize(produto))) return false;

            // Comparação de data de cadastro (se string formatada dd/MM/yyyy)
            if (dataCadastro.isNotEmpty) {
              String formatted = formatDate(data['dataCadastro']);
              if (formatted != dataCadastro) return false;
            }

            return true;
          }).toList();

          if (clientes.isEmpty) {
            return Center(child: Text("Nenhum cliente encontrado com os filtros aplicados."));
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(cliente['nome'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cliente['cpf'] != null) Text("CPF: ${cliente['cpf']}"),
                      if (cliente['telefone'] != null) Text("Telefone: ${cliente['telefone']}"),
                      if (cliente['email'] != null) Text("Email: ${cliente['email']}"),
                      if (cliente['produto'] != null) Text("Produto: ${cliente['produto']}"),
                      if (cliente['marca'] != null) Text("Marca: ${cliente['marca']}"),
                      if (cliente['observacoes'] != null) Text("Obs: ${cliente['observacoes']}"),
                      if (cliente['aniversario'] != null)
                        Text("Aniversário: ${cliente['aniversario']}"),
                      if (cliente['dataCadastro'] != null)
                        Text("Cadastro: ${formatDate(cliente['dataCadastro'])}"),
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
