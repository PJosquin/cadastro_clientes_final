import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResultadoPesquisaPage extends StatefulWidget {
  final Map<String, String> filtros;

  const ResultadoPesquisaPage({Key? key, required this.filtros})
      : super(key: key);

  @override
  _ResultadoPesquisaPageState createState() => _ResultadoPesquisaPageState();
}

class _ResultadoPesquisaPageState extends State<ResultadoPesquisaPage> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('clientes');

    // 🔎 Filtro por CPF
    if (widget.filtros['cpf'] != null &&
        widget.filtros['cpf']!.isNotEmpty) {
      query = query.where('cpf', isEqualTo: widget.filtros['cpf']);
    }

    // 🔎 Filtro por nome (parcial, case insensitive)
    if (widget.filtros['nome'] != null &&
        widget.filtros['nome']!.isNotEmpty) {
      final nomeFiltro = widget.filtros['nome']!.toLowerCase();
      query = query.where('nomeLower', isGreaterThanOrEqualTo: nomeFiltro)
                   .where('nomeLower', isLessThanOrEqualTo: '$nomeFiltro\uf8ff');
    }

    // 🔎 Filtro por e-mail
    if (widget.filtros['email'] != null &&
        widget.filtros['email']!.isNotEmpty) {
      query = query.where('email', isEqualTo: widget.filtros['email']);
    }

    // 🔎 Filtro por telefone
    if (widget.filtros['telefone'] != null &&
        widget.filtros['telefone']!.isNotEmpty) {
      query = query.where('telefone', isEqualTo: widget.filtros['telefone']);
    }

    // 🔎 Filtro por aniversário (string formatada)
    if (widget.filtros['aniversario'] != null &&
        widget.filtros['aniversario']!.isNotEmpty) {
      query = query.where('aniversario', isEqualTo: widget.filtros['aniversario']);
    }

    // 🔎 Filtro por produto
    if (widget.filtros['produto'] != null &&
        widget.filtros['produto']!.isNotEmpty) {
      query = query.where('produto', isEqualTo: widget.filtros['produto']);
    }

    // 🔎 Filtro por marca
    if (widget.filtros['marca'] != null &&
        widget.filtros['marca']!.isNotEmpty) {
      query = query.where('marca', isEqualTo: widget.filtros['marca']);
    }

    // 🔎 Filtro por observações
    if (widget.filtros['observacoes'] != null &&
        widget.filtros['observacoes']!.isNotEmpty) {
      query = query.where('observacoes', isEqualTo: widget.filtros['observacoes']);
    }

    // 🔎 Filtro por data de cadastro (Timestamp → intervalo de 1 dia)
    if (widget.filtros['dataCadastro'] != null &&
        widget.filtros['dataCadastro']!.isNotEmpty) {
      try {
        final partes = widget.filtros['dataCadastro']!.split('/');
        if (partes.length == 3) {
          final dia = int.parse(partes[0]);
          final mes = int.parse(partes[1]);
          final ano = int.parse(partes[2]);

          final inicioDoDia = DateTime(ano, mes, dia, 0, 0, 0);
          final fimDoDia = DateTime(ano, mes, dia, 23, 59, 59);

          query = query
              .where('dataCadastro', isGreaterThanOrEqualTo: inicioDoDia)
              .where('dataCadastro', isLessThanOrEqualTo: fimDoDia);
        }
      } catch (e) {
        print("Erro ao converter dataCadastro: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado da Pesquisa"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Nenhum cliente encontrado."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final cliente = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(cliente['nome'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CPF: ${cliente['cpf'] ?? ''}"),
                      Text("Telefone: ${cliente['telefone'] ?? ''}"),
                      Text("E-mail: ${cliente['email'] ?? ''}"),
                      Text("Produto: ${cliente['produto'] ?? ''}"),
                      Text("Marca: ${cliente['marca'] ?? ''}"),
                      Text("Observações: ${cliente['observacoes'] ?? ''}"),
                      if (cliente['dataCadastro'] != null)
                        Text("Cadastro: ${dateFormat.format((cliente['dataCadastro'] as Timestamp).toDate())}"),
                      if (cliente['aniversario'] != null)
                        Text("Aniversário: ${cliente['aniversario']}"),
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
