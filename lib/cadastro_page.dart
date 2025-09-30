import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({Key? key}) : super(key: key);

  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final cpfController = MaskedTextController(mask: '000.000.000-00');
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = MaskedTextController(mask: '(00) 00000-0000');
  final aniversarioController = MaskedTextController(mask: '00/00/0000');
  final produtoController = TextEditingController();
  final marcaController = TextEditingController();
  final observacoesController = TextEditingController();

  // data de cadastro gerada automaticamente
  final DateTime dataCadastro = DateTime.now();

  Future<void> _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('clientes').add({
          'cpf': cpfController.text,
          'nome': nomeController.text,
          'email': emailController.text,
          'telefone': telefoneController.text,
          'aniversario': aniversarioController.text,
          'produto': produtoController.text,
          'marca': marcaController.text,
          'observacoes': observacoesController.text,
          'dataCadastro': Timestamp.fromDate(dataCadastro),
          'nomeLower': nomeController.text.toLowerCase(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente salvo com sucesso!')),
        );

        _formKey.currentState!.reset();
        cpfController.updateText('');
        telefoneController.updateText('');
        aniversarioController.updateText('');
        marcaController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o CPF';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o e-mail';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o telefone';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: aniversarioController,
                decoration:
                    const InputDecoration(labelText: 'Data de Aniversário'),
              ),
              TextFormField(
                controller: produtoController,
                decoration:
                    const InputDecoration(labelText: 'Produto desejado'),
              ),
              // 🔽 Dropdown dinâmico de marcas
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('marcas')
                    .orderBy('nome')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var marcas = snapshot.data!.docs
                      .map((doc) => doc['nome'].toString())
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: marcaController.text.isNotEmpty
                        ? marcaController.text
                        : null,
                    items: marcas.map((marca) {
                      return DropdownMenuItem<String>(
                        value: marca,
                        child: Text(marca),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        marcaController.text = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Marca'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione uma marca';
                      }
                      return null;
                    },
                  );
                },
              ),
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarCliente,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
