import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({Key? key}) : super(key: key);

  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final cpfController = MaskedTextController(mask: '000.000.000-00');
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = MaskedTextController(mask: '(00) 00000-0000');
  final aniversarioController = MaskedTextController(mask: '00/00/0000');
  final produtoController = TextEditingController();
  final marcaController = TextEditingController();
  final observacoesController = TextEditingController();

  Future<void> _salvarCadastro() async {
    try {
      await FirebaseFirestore.instance.collection('clientes').add({
        'cpf': cpfController.text,
        'nome': nomeController.text,
        'nomeLower': nomeController.text.toLowerCase(),
        'email': emailController.text,
        'telefone': telefoneController.text,
        'aniversario': aniversarioController.text,
        'produto': produtoController.text,
        'marca': marcaController.text,
        'observacoes': observacoesController.text,
        'dataCadastro': FieldValue.serverTimestamp(), // automático no Firebase
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastro salvo com sucesso!")),
      );

      cpfController.clear();
      nomeController.clear();
      emailController.clear();
      telefoneController.clear();
      aniversarioController.clear();
      produtoController.clear();
      marcaController.clear();
      observacoesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro de Clientes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: cpfController, decoration: const InputDecoration(labelText: "CPF")),
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "E-mail")),
            TextField(controller: telefoneController, decoration: const InputDecoration(labelText: "Telefone")),
            TextField(controller: aniversarioController, decoration: const InputDecoration(labelText: "Data de Aniversário")),
            TextField(controller: produtoController, decoration: const InputDecoration(labelText: "Produto desejado")),
            StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('marcas').snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    var marcas = snapshot.data!.docs.map((doc) => doc['nome'].toString()).toList();

    return DropdownButtonFormField<String>(
      value: marcaController.text.isNotEmpty ? marcaController.text : null,
      decoration: const InputDecoration(labelText: 'Marca'),
      items: marcas.map((marca) {
        return DropdownMenuItem(
          value: marca,
          child: Text(marca),
        );
      }).toList(),
      onChanged: (valor) {
        setState(() {
          marcaController.text = valor ?? '';
        });
      },
    );
  },
),

            TextField(controller: observacoesController, decoration: const InputDecoration(labelText: "Observações")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarCadastro,
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
