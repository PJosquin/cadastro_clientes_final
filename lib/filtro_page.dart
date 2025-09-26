import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'resultado_pesquisa_page.dart';

class FiltroPage extends StatefulWidget {
  const FiltroPage({Key? key}) : super(key: key);

  @override
  _FiltroPageState createState() => _FiltroPageState();
}

class _FiltroPageState extends State<FiltroPage> {
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController aniversarioController = TextEditingController();
  final TextEditingController produtoController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  final TextEditingController dataCadastroController = TextEditingController();

  String? marcaSelecionada;
  List<String> marcas = [];

  // Máscaras
  final cpfFormatter = MaskTextInputFormatter(mask: "###.###.###-##");
  final telefoneFormatter = MaskTextInputFormatter(mask: "(##) #####-####");
  final dataFormatter = MaskTextInputFormatter(mask: "##/##/####");

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  Future<void> _carregarMarcas() async {
    final snapshot = await FirebaseFirestore.instance.collection('clientes').get();
    final lista = snapshot.docs
        .map((doc) => doc['marca']?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      marcas = lista;
    });
  }

  void _pesquisar() {
    final filtros = {
      "cpf": cpfController.text.trim(),
      "nome": nomeController.text.trim(),
      "email": emailController.text.trim(),
      "telefone": telefoneController.text.trim(),
      "aniversario": aniversarioController.text.trim(),
      "produto": produtoController.text.trim(),
      "marca": marcaSelecionada ?? "",
      "observacoes": observacoesController.text.trim(),
      "dataCadastro": dataCadastroController.text.trim(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoPesquisaPage(filtros: filtros),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filtro de Clientes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: cpfController,
                decoration: const InputDecoration(labelText: "CPF"),
                keyboardType: TextInputType.number,
                inputFormatters: [cpfFormatter],
              ),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
              ),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: "Telefone"),
                keyboardType: TextInputType.phone,
                inputFormatters: [telefoneFormatter],
              ),
              TextField(
                controller: aniversarioController,
                decoration: const InputDecoration(labelText: "Aniversário"),
                keyboardType: TextInputType.number,
                inputFormatters: [dataFormatter],
              ),
              TextField(
                controller: produtoController,
                decoration: const InputDecoration(labelText: "Produto Desejado"),
              ),
              DropdownButtonFormField<String>(
                value: marcaSelecionada,
                items: marcas
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    marcaSelecionada = value;
                  });
                },
                decoration: const InputDecoration(labelText: "Marca"),
              ),
              TextField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: "Observações"),
              ),
              TextField(
                controller: dataCadastroController,
                decoration: const InputDecoration(labelText: "Data de Cadastro"),
                keyboardType: TextInputType.number,
                inputFormatters: [dataFormatter],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pesquisar,
                child: const Text("Pesquisar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
