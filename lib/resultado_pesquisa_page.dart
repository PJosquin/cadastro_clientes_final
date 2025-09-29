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
  List<Map<String, dynamic>> resultados = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _pesquisar();
  }

  Future<void> _pesquisar() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('clientes').get();

      final docs = snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();

      final filtros = widget.filtros;
      final nomeFiltro = filtros['nome']?.toLowerCase() ?? "";

      final filtrados = docs.where((doc) {
        final nome = (doc['nomeLower'] ?? "").toString();
        final cpf = (doc['cpf'] ?? "").toString();
        final email = (doc['email'] ?? "").toString();
        final telefone = (doc['telefone'] ?? "").toString();
        final produto = (doc['produto'] ?? "").toString();
        final marca = (doc['marca'] ?? "").toString();
        final observacoes = (doc['observacoes'] ?? "").toString();

        final nomeOk =
            nomeFiltro.isEmpty || nome.contains(nomeFiltro); // parcial e insensitive
        final cpfOk =
            filtros['cpf']!.isEmpty || cpf.contains(filtros['cpf']!);
        final emailOk =
            filtros['email']!.isEmpty || email.contains(filtros['email']!);
        final telefoneOk = filtros['telefone']!.isEmpty ||
            telefone.contains(filtros['telefone']!);
        final produtoOk =
            filtros['produto']!.isEmpty || produto.contains(filtros['produto']!);
        final marcaOk =
            filtros['marca']!.isEmpty || marca.contains(filtros['marca']!);
        final obsOk = filtros['observacoes']!.isEmpty ||
            observacoes.contains(filtros['observacoes']!);

        return nomeOk && cpfOk && emailOk && telefoneOk && produtoOk && marcaOk && obsOk;
      }).toList();

      setState(() {
        resultados = filtrados;
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro na pesquisa: $e")),
      );
    }
  }

  String _formatarData(dynamic data) {
    if (data == null || data.toString().isEmpty) return "";
    try {
      if (data is Timestamp) {
        return DateFormat("dd/MM/yyyy").format(data.toDate());
      } else if (data is String) {
        return data;
      }
    } catch (_) {}
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resultados da Pesquisa")),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : resultados.isEmpty
              ? const Center(child: Text("Nenhum cliente encontrado."))
              : ListView.builder(
                  itemCount: resultados.length,
                  itemBuilder: (context, index) {
                    final cliente = resultados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(cliente['nome'] ?? "Sem nome"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CPF: ${cliente['cpf'] ?? ''}"),
                            Text("E-mail: ${cliente['email'] ?? ''}"),
                            Text("Telefone: ${cliente['telefone'] ?? ''}"),
                            Text("Aniversário: ${cliente['aniversario'] ?? ''}"),
                            Text("Produto: ${cliente['produto'] ?? ''}"),
                            Text("Marca: ${cliente['marca'] ?? ''}"),
                            Text("Observações: ${cliente['observacoes'] ?? ''}"),
                            Text("Data Cadastro: ${_formatarData(cliente['dataCadastro'])}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
