import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultadoPesquisaPage extends StatefulWidget {
  final Map<String, String> filtros;

  const ResultadoPesquisaPage({Key? key, required this.filtros}) : super(key: key);

  @override
  _ResultadoPesquisaPageState createState() => _ResultadoPesquisaPageState();
}

class _ResultadoPesquisaPageState extends State<ResultadoPesquisaPage> {
  List<DocumentSnapshot> clientes = [];
  bool carregando = true;
  final TextEditingController _mensagemController =
      TextEditingController(text: "Olá, tudo bem?");

  @override
  void initState() {
    super.initState();
    _pesquisar();
  }

  Future<void> _pesquisar() async {
    setState(() => carregando = true);

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('clientes').get();

      List<DocumentSnapshot> resultados = querySnapshot.docs;

      // 🔹 Aplica filtros simples por texto (sem diferenciar maiúsculas/minúsculas)
      resultados = resultados.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        bool match = true;

        widget.filtros.forEach((chave, valor) {
          if (valor.trim().isEmpty) return;
          final campo = (data[chave] ?? '').toString().toLowerCase();
          if (!campo.contains(valor.toLowerCase())) match = false;
        });

        return match;
      }).toList();

      // 🔹 Ordena alfabeticamente por nome
      resultados.sort((a, b) {
        final nomeA = (a['nome'] ?? '').toString().toLowerCase();
        final nomeB = (b['nome'] ?? '').toString().toLowerCase();
        return nomeA.compareTo(nomeB);
      });

      setState(() {
        clientes = resultados;
        carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao pesquisar clientes: $e');
      setState(() => carregando = false);
    }
  }

  String _formatarCampo(String? valor) {
    return (valor == null || valor.isEmpty) ? '-' : valor;
  }

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final data = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(data);
  }

  Future<void> _abrirWhatsApp(String numero, String mensagem) async {
    final telefoneLimpo = numero.replaceAll(RegExp(r'[^0-9]'), '');
    if (telefoneLimpo.isEmpty) return;

    final mensagemEncoded =
        Uri.encodeComponent(mensagem.isEmpty ? "Olá, tudo bem?" : mensagem);
    final url = Uri.parse("https://wa.me/55$telefoneLimpo?text=$mensagemEncoded");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Pesquisa'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _mensagemController,
              decoration: InputDecoration(
                labelText: 'Mensagem padrão para WhatsApp',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : clientes.isEmpty
                    ? const Center(child: Text('Nenhum cliente encontrado.'))
                    : ListView.builder(
                        itemCount: clientes.length,
                        itemBuilder: (context, index) {
                          var cliente =
                              clientes[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(_formatarCampo(cliente['nome'])),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📞 ${_formatarCampo(cliente['telefone'])}'),
                                  Text('✉️ ${_formatarCampo(cliente['email'])}'),
                                  Text('🆔 ${_formatarCampo(cliente['cpf'])}'),
                                  if (cliente['dataCadastro'] != null)
                                    Text(
                                        '📅 ${_formatarData(cliente['dataCadastro'])}'),
                                  if (cliente['marca'] != null)
                                    Text('🏷️ ${_formatarCampo(cliente['marca'])}'),
                                  if (cliente['produto'] != null)
                                    Text('📦 ${_formatarCampo(cliente['produto'])}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.chat, color: Colors.green),
                                tooltip: 'Enviar mensagem no WhatsApp',
                                onPressed: () {
                                  final telefone = cliente['telefone'] ?? '';
                                  if (telefone.isNotEmpty) {
                                    _abrirWhatsApp(
                                      telefone,
                                      _mensagemController.text,
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
    );
  }
}
