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
  List<Map<String, dynamic>> clientes = [];

  @override
  void initState() {
    super.initState();
    _buscarClientes();
  }

  Future<void> _buscarClientes() async {
    Query query = FirebaseFirestore.instance.collection('clientes');

    widget.filtros.forEach((chave, valor) {
      if (valor != null && valor.toString().isNotEmpty) {
        query = query.where(chave, isEqualTo: valor);
      }
    });

    final snapshot = await query.get();
    setState(() {
      clientes = snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  }

  Future<void> enviarWhatsApp(String telefone, String mensagem) async {
    final numeroComDDI = telefone.startsWith("+55") ? telefone : "+55$telefone";
    final url = Uri.parse("https://wa.me/$numeroComDDI?text=${Uri.encodeComponent(mensagem)}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados da Pesquisa"),
      ),
      body: clientes.isEmpty
          ? const Center(child: Text("Nenhum cliente encontrado."))
          : ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente['nome'] ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text("Telefone: ${cliente['telefone'] ?? ''}"),
                        Text("Email: ${cliente['email'] ?? ''}"),
                        Text("Produto: ${cliente['produto'] ?? ''}"),
                        if ((cliente['observacoes'] ?? '').isNotEmpty)
                          Text(
                            "Obs: ${cliente['observacoes']}",
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.whatsapp,
                                  color: Colors.green),
                              onPressed: () {
                                enviarWhatsApp(cliente['telefone'] ?? '',
                                    "Olá ${cliente['nome']}, tudo bem?");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // TODO: implementar edição
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // TODO: implementar exclusão
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
