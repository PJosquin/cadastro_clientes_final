import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'editar_cliente_detalhe_page.dart'; // para abrir a tela de edição
import 'admin_deletar_clientes_page.dart'; // 🔒 tela oculta de deleção por PIN

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
      // 🔹 Long-press no título abre a tela oculta de administração (PIN)
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDeletarClientesPage(),
              ),
            );
            // ao retornar, recarrega a lista (caso tenha havido deleção)
            setState(() {});
          },
          child: const Text("Lista de Clientes"),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clientes')
            .orderBy('nome', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          // logs de diagnóstico (mantidos como estavam)
          // ignore: avoid_print
          print("🔥 snapshot.connectionState: ${snapshot.connectionState}");
          // ignore: avoid_print
          print("📦 snapshot.hasData: ${snapshot.hasData}");
          // ignore: avoid_print
          print("❌ snapshot.hasError: ${snapshot.hasError}");
          if (snapshot.hasError) {
            // ignore: avoid_print
            print("Erro Firestore: ${snapshot.error}");
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Nenhum cliente cadastrado."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['id'] = docs[index].id;

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
                      if (aniversario.isNotEmpty)
                        Text("Aniversário: $aniversario"),
                      if (dataCadastro.isNotEmpty)
                        Text("Cadastrado em: $dataCadastro"),
                      if ((data["produto"] ?? "").isNotEmpty)
                        Text("Produto: ${data["produto"]}"),
                      if ((data["marca"] ?? "").isNotEmpty)
                        Text("Marca: ${data["marca"]}"),
                      if ((data["observacoes"] ?? "").isNotEmpty)
                        Text("Obs: ${data["observacoes"]}"),
                    ],
                  ),
                  // ✅ Mantido: botão Editar
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar Cliente',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarClienteDetalhePage(
                            clienteId: data['id'],   // 🔑 ID do documento
                            dadosCliente: data,      // 📦 mapa completo
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // ✅ Mantido: total fixo no rodapé
      bottomNavigationBar: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
          builder: (context, snapshot) {
            final total = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue.shade50,
              child: Text(
                "Total de clientes: $total",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
