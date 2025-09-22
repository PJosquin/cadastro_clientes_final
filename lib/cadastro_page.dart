// lib/cadastro_page.dart
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

  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _aniversarioController = TextEditingController();
  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  var cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  var telefoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
  var aniversarioFormatter = MaskTextInputFormatter(mask: '##/##/####');

  void _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('clientes').add({
          'cpf': _cpfController.text,
          'nome': _nomeController.text,
          'nomeLower': _nomeController.text.toLowerCase(), // 🔑 campo auxiliar
          'email': _emailController.text,
          'telefone': _telefoneController.text,
          'aniversario': _aniversarioController.text,
          'produto': _produtoController.text,
          'produtoLower': _produtoController.text.toLowerCase(), // 🔑 campo auxiliar
          'marca': _marcaController.text,
          'observacoes': _observacoesController.text,
          'dataCadastro': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cliente salvo com sucesso!")),
        );

        _formKey.currentState!.reset();
        _cpfController.clear();
        _nomeController.clear();
        _emailController.clear();
        _telefoneController.clear();
        _aniversarioController.clear();
        _produtoController.clear();
        _marcaController.clear();
        _observacoesController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro de Cliente")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _cpfController,
                decoration: InputDecoration(labelText: "CPF"),
                inputFormatters: [cpfFormatter],
                validator: (value) => value == null || value.isEmpty ? "Informe o CPF" : null,
              ),
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: "Nome"),
                validator: (value) => value == null || value.isEmpty ? "Informe o nome" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "E-mail"),
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: "Telefone"),
                inputFormatters: [telefoneFormatter],
              ),
              TextFormField(
                controller: _aniversarioController,
                decoration: InputDecoration(labelText: "Data de aniversário"),
                inputFormatters: [aniversarioFormatter],
              ),
              TextFormField(
                controller: _produtoController,
                decoration: InputDecoration(labelText: "Produto desejado"),
              ),
              TextFormField(
                controller: _marcaController,
                decoration: InputDecoration(labelText: "Marca"),
              ),
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(labelText: "Observações"),
                maxLines: 2,
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
