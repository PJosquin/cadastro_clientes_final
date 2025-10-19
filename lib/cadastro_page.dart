import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'widgets/brand_multi_select_field.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({Key? key}) : super(key: key);

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final cpfController = MaskedTextController(mask: '000.000.000-00');
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = MaskedTextController(mask: '(00) 00000-0000');
  final aniversarioController = MaskedTextController(mask: '00/00/0000');
  final produtoController = TextEditingController();
  final observacoesController = TextEditingController();

  // Lista de múltiplas marcas selecionadas
  List<String> _marcasSelecionadas = [];

  final DateTime dataCadastro = DateTime.now();

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('clientes').add({
        'cpf': cpfController.text.trim(),
        'nome': nomeController.text.trim(),
        'email': emailController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'aniversario': aniversarioController.text.trim(),
        'produto': produtoController.text.trim(),
        'marcas': _marcasSelecionadas,
        'observacoes': observacoesController.text.trim(),
        'dataCadastro': dataCadastro,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo com sucesso!')),
      );

      _formKey.currentState!.reset();
      cpfController.updateText('');
      telefoneController.updateText('');
      aniversarioController.updateText('');
      nomeController.clear();
      emailController.clear();
      produtoController.clear();
      observacoesController.clear();
      setState(() => _marcasSelecionadas = []);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              TextFormField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe o telefone' : null,
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
              const SizedBox(height: 12),

              // Campo de múltiplas marcas
              BrandMultiSelectField(
                initialValue: _marcasSelecionadas,
                validator: (list) => (list == null || list.isEmpty)
                    ? 'Selecione ao menos uma marca'
                    : null,
                onSaved: (list) =>
                    _marcasSelecionadas = List<String>.from(list ?? []),
              ),

              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _salvarCliente,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
