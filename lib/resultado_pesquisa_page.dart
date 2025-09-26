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
  late Future<List<Map<String, dynamic>>> _futureResultados;

  @override
  void initState() {
    super.initState();
    _futureResultados = _buscarResultados();
  }

  Future<List<Map<String, dynamic>>> _buscarResultados() async {
    try {
      Query query = FirebaseFirestore.instance.collection('clientes');

      widget.filtros.forEach((campo, valor) {
        if (valor.isNotEmpty) {
          query = query.where(campo, isEqualTo: valor);
        }
      });

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print(">>> ERRO Firestore no _buscarResultados: $e");
      rethrow;
    }
  }

  Future<void> _enviarWhatsApp(String telefone, String mensagem) async {
    final Uri url = Uri.parse("https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados da Pesquisa')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureResultados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(">>> ERRO no FutureBuilder: ${snapshot.error}");
            return Center(
              child: Text(
                "Erro: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum cliente encontrado."));
          }

          final resultados = snapshot.data!;
          return ListView.builder(
            itemCount: resultados.length,
            itemBuilder: (context, index) {
              final cliente = resultados[index];

              final telefone = cliente['telefone'] ?? '';
              final cpf = cliente['cpf'] ?? '';
              final dataCadastro = cliente['dataCadastro'];
              final dataFormatada = (dataCadastro != null && dataCadastro is Timestamp)
                  ? DateFormat('dd/MM/yyyy').format(dataCadastro.toDate())
                  : '';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(cliente['nome'] ?? 'Sem nome'),
                  subtitle: Text(
                    "CPF: $cpf\nTelefone: $telefone\nData Cadastro: $dataFormatada",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: () {
                      if (telefone.isNotEmpty) {
                        _enviarWhatsApp(telefone, "Olá ${cliente['nome']}, tudo bem?");
                      }
                    },
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
