import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CadastroPage extends StatefulWidget {
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final cpfFormatter = MaskTextInputFormatter(mask: "###.###.###-##");
  final phoneFormatter = MaskTextInputFormatter(mask: "(##) #####-####");
  final dateFormatter = MaskTextInputFormatter(mask: "##/##/####");

  final _cpfController = TextEditingController();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _aniversarioController = TextEditingController();
  final _produtoController = TextEditingController();
  final _observacoesController = TextEditingController();

  String? _marcaSelecionada;
  List<String> _marcas = [];

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  Future<void> _carregarMarcas() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("marcas").get();
    setState(() {
      _marcas =
          snapshot.docs.map((doc) => doc["nome"]?.toString() ?? "").toList();
    });
  }

  void _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection("clientes").add({
        "cpf": _cpfController.text,
        "nome": _nomeController.text,
        "email": _emailController.text,
        "telefone": _telefoneController.text,
        "aniversario": _aniversarioController.text,
        "produto": _produtoController.text,
        "marca": _marcaSelecionada ?? "",
        "observacoes": _observacoesController.text,
        "dataCadastro":
            DateFormat("dd/MM/yyyy").format(DateTime.now()), // data formatada
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cliente cadastrado com sucesso!")),
      );

      _formKey.currentState!.reset();
      _cpfController.clear();
      _nomeController.clear();
      _emailController.clear();
      _telefoneController.clear();
      _aniversarioController.clear();
      _produtoController.clear();
      _observacoesController.clear();
      setState(() => _marcaSelecionada = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro de Cliente")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _cpfController,
                decoration: InputDecoration(labelText: "CPF"),
                inputFormatters: [cpfFormatter],
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? "Informe o CPF" : null,
              ),
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: "Nome"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Informe o nome" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "E-mail"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: "Telefone"),
                inputFormatters: [phoneFormatter],
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _aniversarioController,
                decoration: InputDecoration(labelText: "Data de Aniversário"),
                inputFormatters: [dateFormatter],
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _produtoController,
                decoration: InputDecoration(labelText: "Produto Desejado"),
              ),
              DropdownButtonFormField<String>(
                value: _marcaSelecionada,
                items: _marcas
                    .map((marca) =>
                        DropdownMenuItem(value: marca, child: Text(marca)))
                    .toList(),
                onChanged: (value) => setState(() => _marcaSelecionada = value),
                decoration: InputDecoration(labelText: "Marca"),
              ),
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(labelText: "Observações"),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarCliente,
                child: Text("Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
