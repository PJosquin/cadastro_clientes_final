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

  @override
  void initState() {
    super.initState();
    _pesquisar();
  }

  Future<void> _pesquisar() async {
    try {
      Query query = FirebaseFirestore.instance.collection('clientes');

      // 🔹 Filtro direto para dataCadastro (Timestamp no Firestore)
      if (widget.filtros['dataCadastro'] != null &&
          widget.filtros['dataCadastro']!.isNotEmpty) {
        final dataCadastroFiltro =
            DateFormat('dd/MM/yyyy').parse(widget.filtros['dataCadastro']!);

        final inicio = DateTime(
            dataCadastroFiltro.year, dataCadastroFiltro.month, dataCadastroFiltro.day, 0, 0, 0);
        final fim = DateTime(
            dataCadastroFiltro.year, dataCadastroFiltro.month, dataCadastroFiltro.day, 23, 59, 59);

        query = query
            .where('dataCadastro', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
            .where('dataCadastro', isLessThanOrEqualTo: Timestamp.fromDate(fim));
      }

      final snapshot = await query.get();
      final todos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // 🔹 Aplicar filtros em memória (case-insensitive, substring)
      resultados = todos.where((cliente) {
        bool match = true;

        // Nome
        if (widget.filtros['nome'] != null &&
            widget.filtros['nome']!.isNotEmpty) {
          final filtro = widget.filtros['nome']!.toLowerCase();
          final nomeCliente = (cliente['nome'] ?? '').toString().toLowerCase();
          if (!nomeCliente.contains(filtro)) match = false;
        }

        // CPF
        if (widget.filtros['cpf'] != null &&
            widget.filtros['cpf']!.isNotEmpty) {
          final filtro = widget.filtros['cpf']!.replaceAll(RegExp(r'\D'), '');
          final cpfCliente =
              (cliente['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
          if (!cpfCliente.contains(filtro)) match = false;
        }

        // E-mail
        if (widget.filtros['email'] != null &&
            widget.filtros['email']!.isNotEmpty) {
          final filtro = widget.filtros['email']!.toLowerCase();
          final emailCliente =
              (cliente['email'] ?? '').toString().toLowerCase();
          if (!emailCliente.contains(filtro)) match = false;
        }

        // Data de aniversário (comparação substring para permitir dd/MM)
        if (widget.filtros['aniversario'] != null &&
            widget.filtros['aniversario']!.isNotEmpty) {
          final filtro = widget.filtros['aniversario']!;
          final aniversarioCliente =
              (cliente['aniversario'] ?? '').toString();
          if (!aniversarioCliente.contains(filtro)) match = false;
        }

        // Produto
        if (widget.filtros['produto'] != null &&
            widget.filtros['produto']!.isNotEmpty) {
          final filtro = widget.filtros['produto']!.toLowerCase();
          final produtoCliente =
              (cliente['produto'] ?? '').toString().toLowerCase();
          if (!produtoCliente.contains(filtro)) match = false;
        }

        // Observações
        if (widget.filtros['observacoes'] != null &&
            widget.filtros['observacoes']!.isNotEmpty) {
          final filtro = widget.filtros['observacoes']!.toLowerCase();
          final obsCliente =
              (cliente['observacoes'] ?? '').toString().toLowerCase();
          if (!obsCliente.contains(filtro)) match = false;
        }

        // Marca (continua exata, vindo de dropdown)
        if (widget.filtros['marca'] != null &&
            widget.filtros['marca']!.isNotEmpty) {
          final filtro = widget.filtros['marca']!;
          final marcaCliente = (cliente['marca'] ?? '').toString();
          if (marcaCliente != filtro) match = false;
        }

        return match;
      }).toList();

      setState(() {});
    } catch (e) {
      print('Erro na pesquisa: $e');
    }
  }

  String formatarData(dynamic valor) {
    if (valor is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(valor.toDate());
    }
    return valor?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resultados da Pesquisa")),
      body: resultados.isEmpty
          ? const Center(child: Text("Nenhum cliente encontrado."))
          : ListView.builder(
              itemCount: resultados.length,
              itemBuilder: (context, index) {
                final cliente = resultados[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(cliente['nome'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CPF: ${cliente['cpf'] ?? ''}"),
                        Text("E-mail: ${cliente['email'] ?? ''}"),
                        Text("Telefone: ${cliente['telefone'] ?? ''}"),
                        Text("Aniversário: ${cliente['aniversario'] ?? ''}"),
                        Text("Produto: ${cliente['produto'] ?? ''}"),
                        Text("Marca: ${cliente['marca'] ?? ''}"),
                        Text("Obs: ${cliente['observacoes'] ?? ''}"),
                        Text("Cadastro: ${formatarData(cliente['dataCadastro'])}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
