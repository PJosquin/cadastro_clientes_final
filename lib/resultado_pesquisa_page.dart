import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultadoPesquisaPage extends StatefulWidget {
  final Map<String, dynamic> filtros;

  const ResultadoPesquisaPage({Key? key, required this.filtros})
      : super(key: key);

  @override
  _ResultadoPesquisaPageState createState() => _ResultadoPesquisaPageState();
}

class _ResultadoPesquisaPageState extends State<ResultadoPesquisaPage> {
  Future<void> _enviarMensagemWhatsApp(String telefone, String mensagem) async {
    // Remove tudo que não for número
    String numero = telefone.replaceAll(RegExp(r'\D'), '');

    // Adiciona o prefixo do Brasil se não estiver presente
    if (!numero.startsWith("55")) {
      numero = "55$numero";
    }

    final Uri url = Uri.parse(
        "https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Não foi possível abrir o WhatsApp");
    }
  }

  Future<void> _enviarParaTodos(
      List<QueryDocumentSnapshot> documentos, String mensagem) async {
    for (var doc in documentos) {
      final telefone = doc['telefone'] ?? '';
      if (telefone.isNotEmpty) {
        await _enviarMensagemWhatsApp(telefone, mensagem);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtros = widget.filtros;

    Query query = FirebaseFirestore.instance.collection('clientes');

    filtros.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        query = query.where(key, isEqualTo: value);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado da Pesquisa"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum cliente encontrado."));
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final cliente = docs[index];
                    return Card(
                      child: ListTile(
                        title: Text(cliente['nome'] ?? ''),
                        subtitle: Text(
                          "Telefone: ${cliente['telefone'] ?? ''}\n"
                          "E-mail: ${cliente['email'] ?? ''}\n"
                          "Produto: ${cliente['produto'] ?? ''}\n"
                          "Marca: ${cliente['marca'] ?? ''}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.send, color: Colors.green),
                          onPressed: () {
                            _enviarMensagemWhatsApp(
                              cliente['telefone'] ?? '',
                              "Olá ${cliente['nome']}, tudo bem? Esta é uma mensagem automática!",
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Enviar para todos"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  _enviarParaTodos(
                      docs, "Olá! Esta é uma mensagem automática.");
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
