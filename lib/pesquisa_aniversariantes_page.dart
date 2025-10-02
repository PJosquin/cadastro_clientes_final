import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PesquisaAniversariantesPage extends StatefulWidget {
  const PesquisaAniversariantesPage({super.key});

  @override
  State<PesquisaAniversariantesPage> createState() =>
      _PesquisaAniversariantesPageState();
}

class _PesquisaAniversariantesPageState
    extends State<PesquisaAniversariantesPage> {
  final TextEditingController _mesController = TextEditingController();
  List<DocumentSnapshot> clientes = [];
  bool carregando = false;

  /// Função para abrir WhatsApp com mensagem
  Future<void> _abrirWhatsApp(String telefone, String nome) async {
    final Uri url = Uri.parse(
      "https://wa.me/$telefone?text=Olá $nome, tudo de bom no seu aniversário!",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o WhatsApp")),
      );
    }
  }

  Future<void> _pesquisar() async {
    setState(() {
      carregando = true;
      clientes = [];
    });

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('clientes').get();

    List<DocumentSnapshot> resultados = querySnapshot.docs;

    // Normalizar filtro
    String mesFiltro = _mesController.text.trim().toLowerCase();

    Map<String, int> meses = {
      'janeiro': 1,
      'fevereiro': 2,
      'março': 3,
      'marco': 3, // sem acento
      'abril': 4,
      'maio': 5,
      'junho': 6,
      'julho': 7,
      'agosto': 8,
      'setembro': 9,
      'outubro': 10,
      'novembro': 11,
      'dezembro': 12,
    };

    int? mesNumero;
    if (meses.containsKey(mesFiltro)) {
      mesNumero = meses[mesFiltro];
    } else {
      mesNumero = int.tryParse(mesFiltro); // aceita "9" ou "09"
    }

    if (mesNumero != null) {
      resultados = resultados.where((doc) {
        final aniversarioStr = (doc['aniversario'] ?? '').toString();
        try {
          final aniversario = DateFormat('dd/MM/yyyy').parse(aniversarioStr);
          return aniversario.month == mesNumero;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    setState(() {
      clientes = resultados;
      carregando = false;
    });
  }

  String _formatarCampo(String? valor) {
    return (valor == null || valor.isEmpty) ? '-' : valor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesquisa de Aniversariantes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mesController,
              decoration: const InputDecoration(
                labelText: "Digite o mês (ex: Setembro ou 09)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pesquisar,
              child: const Text("Pesquisar"),
            ),
            const SizedBox(height: 20),
            carregando
                ? const CircularProgressIndicator()
                : Expanded(
                    child: clientes.isEmpty
                        ? const Text("Nenhum aniversariante encontrado.")
                        : ListView.builder(
                            itemCount: clientes.length,
                            itemBuilder: (context, index) {
                              var cliente = clientes[index].data()
                                  as Map<String, dynamic>;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                child: ListTile(
                                  title: Text(_formatarCampo(cliente['nome'])),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Aniversário: ${_formatarCampo(cliente['aniversario'])}"),
                                      Text(
                                          "Telefone: ${_formatarCampo(cliente['telefone'])}"),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.message,
                                        color: Colors.green),
                                    onPressed: () {
                                      if (cliente['telefone'] != null &&
                                          cliente['telefone']
                                              .toString()
                                              .isNotEmpty) {
                                        _abrirWhatsApp(
                                          cliente['telefone'].toString(),
                                          cliente['nome'] ?? '',
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
