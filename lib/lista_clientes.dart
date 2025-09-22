import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ListaClientesPage extends StatefulWidget {
  @override
  _ListaClientesPageState createState() => _ListaClientesPageState();
}

class _ListaClientesPageState extends State<ListaClientesPage> {
  String _formatarData(dynamic data) {
    if (data == null) return "";
    if (data is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(data.toDate());
    }
    if (data is String && data.isNotEmpty) {
      try {
        final parsed = DateFormat("dd/MM/yyyy").parse(data);
        return DateFormat("dd/MM/yyyy").format(parsed);
      } catch (_) {
        return data;
      }
    }
    return "";
  }

  String _formatarCpf(String? cpf) {
    if (cpf == null) return "";
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), "");
    if (numeros.length != 11) return cpf;
    return "${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9)}";
  }

  String _formatarTelefone(String? tel) {
    if (tel == null) return "";
    final numeros = tel.replaceAll(RegExp(r'[^0-9]'), "");
    if (numeros.length == 11) {
      return "(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}";
    } else if (numeros.length == 10) {
      return "(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}";
    }
    return tel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lista de Clientes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text("Nenhum cliente cadastrado."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final cpf = _formatarCpf(data["cpf"]);
              final telefone = _formatarTelefone(data["telefone"]);
              final aniversario = _formatarData(data["aniversario"]);
              final dataCadastro = _formatarData(data["dataCadastro"]);

              return Card(
                child: ListTile(
                  title: Text(data["nome"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cpf.isNotEmpty) Text("CPF: $cpf"),
                      if (telefone.isNotEmpty) Text("Telefone: $telefone"),
                      if (aniversario.isNotEmpty) Text("Aniversário: $aniversario"),
                      if (dataCadastro.isNotEmpty) Text("Cadastrado em: $dataCadastro"),
                      if ((data["produto"] ?? "").isNotEmpty) Text("Produto: ${data["produto"]}"),
                      if ((data["marca"] ?? "").isNotEmpty) Text("Marca: ${data["marca"]}"),
                      if ((data["observacoes"] ?? "").isNotEmpty) Text("Obs: ${data["observacoes"]}"),
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
