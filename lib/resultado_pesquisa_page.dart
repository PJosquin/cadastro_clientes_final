import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultadoPesquisaPage extends StatefulWidget {
  final Map<String, String> filtros;

  const ResultadoPesquisaPage({Key? key, required this.filtros})
      : super(key: key);

  @override
  _ResultadoPesquisaPageState createState() => _ResultadoPesquisaPageState();
}

class _ResultadoPesquisaPageState extends State<ResultadoPesquisaPage> {
  List<QueryDocumentSnapshot> _resultados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarResultados();
  }

  Future<void> _buscarResultados() async {
    try {
      Query query = FirebaseFirestore.instance.collection('clientes');

      // filtros diretos (CPF, telefone, email, produto, marca etc.)
      widget.filtros.forEach((campo, valor) {
        if (valor.isNotEmpty &&
            campo != 'nome' &&
            campo != 'aniversario' &&
            campo != 'dataCadastro') {
          query = query.where(campo, isEqualTo: valor);
        }
      });

      final snapshot = await query.get();

      // aplica filtros especiais localmente
      List<QueryDocumentSnapshot> docs = snapshot.docs;

      // filtro de nome (substring, case-insensitive)
      if (widget.filtros['nome'] != null &&
          widget.filtros['nome']!.trim().isNotEmpty) {
        final filtroNome = widget.filtros['nome']!.toLowerCase();
        docs = docs.where((doc) {
          final nome = (doc['nome'] ?? '').toString().toLowerCase();
          return nome.contains(filtroNome);
        }).toList();
      }

      // filtro de aniversário (string exata dd/MM/yyyy)
      if (widget.filtros['aniversario'] != null &&
          widget.filtros['aniversario']!.trim().isNotEmpty) {
        docs = docs.where((doc) {
          final aniversario = (doc['aniversario'] ?? '').toString().trim();
          return aniversario == widget.filtros['aniversario']!.trim();
        }).toList();
      }

      // filtro de data de cadastro (timestamp convertido em string dd/MM/yyyy)
      if (widget.filtros['dataCadastro'] != null &&
          widget.filtros['dataCadastro']!.trim().isNotEmpty) {
        docs = docs.where((doc) {
          final ts = doc['dataCadastro'];
          if (ts is Timestamp) {
            final dataFormatada =
                DateFormat('dd/MM/yyyy').format(ts.toDate());
            return dataFormatada == widget.filtros['dataCadastro']!.trim();
          }
          return false;
        }).toList();
      }

      setState(() {
        _resultados = docs;
        _carregando = false;
      });
    } catch (e) {
      print("Erro na busca: $e");
      setState(() {
        _resultados = [];
        _carregando = false;
      });
    }
  }

  Future<void> _enviarWhatsApp(String telefone, String mensagem) async {
    final Uri url = Uri.parse(
        "https://wa.me/55$telefone?text=${Uri.encodeComponent(mensagem)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Não foi possível abrir o WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da Pesquisa')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _resultados.isEmpty
              ? const Center(child: Text("Nenhum cliente encontrado."))
              : ListView.builder(
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final doc = _resultados[index];
                    final nome = doc['nome'] ?? '';
                    final telefone = doc['telefone'] ?? '';
                    final produto = doc['produto'] ?? '';
                    final marca = doc['marca'] ?? '';
                    final dataCadastro = (doc['dataCadastro'] is Timestamp)
                        ? DateFormat('dd/MM/yyyy')
                            .format((doc['dataCadastro'] as Timestamp).toDate())
                        : (doc['dataCadastro'] ?? '');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(nome),
                        subtitle: Text(
                            "Telefone: $telefone\nProduto: $produto\nMarca: $marca\nCadastro: $dataCadastro"),
                        trailing: IconButton(
                          icon: const Icon(Icons.send, color: Colors.green),
                          onPressed: () {
                            _enviarWhatsApp(
                                telefone,
                                "Olá $nome, estamos entrando em contato sobre $produto da marca $marca.");
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
