import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class EditarClienteDetalhePage extends StatefulWidget {
  final String clienteId;
  final Map<String, dynamic> dadosCliente;

  const EditarClienteDetalhePage({
    Key? key,
    required this.clienteId,
    required this.dadosCliente,
  }) : super(key: key);

  @override
  State<EditarClienteDetalhePage> createState() => _EditarClienteDetalhePageState();
}

class _EditarClienteDetalhePageState extends State<EditarClienteDetalhePage> {
  late final MaskedTextController cpfController;
  late final MaskedTextController telefoneController;
  late final TextEditingController nomeController;
  late final TextEditingController emailController;
  late final TextEditingController aniversarioController;
  late final TextEditingController produtoController;
  late final TextEditingController marcaController;
  late final TextEditingController observacoesController;

  @override
  void initState() {
    super.initState();
    final dados = widget.dadosCliente;

    cpfController = MaskedTextController(mask: '000.000.000-00', text: dados['cpf'] ?? '');
    telefoneController = MaskedTextController(mask: '(00) 00000-0000', text: dados['telefone'] ?? '');
    nomeController = TextEditingController(text: dados['nome'] ?? '');
    emailController = TextEditingController(text: dados['email'] ?? '');
    aniversarioController = TextEditingController(text: dados['aniversario'] ?? '');
    produtoController = TextEditingController(text: dados['produto'] ?? '');
    marcaController = TextEditingController(text: dados['marca'] ?? '');
    observacoesController = TextEditingController(text: dados['observacoes'] ?? '');
  }

  Future<void> _salvarEdicao() async {
    try {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .update({
        'cpf': cpfController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'nome': nomeController.text.trim(),
        'email': emailController.text.trim(),
        'aniversario': aniversarioController.text.trim(),
        'produto': produtoController.text.trim(),
        'marca': marcaController.text.trim(),
        'observacoes': observacoesController.text.trim(),
        'dataEdicao': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas com sucesso!'),
          duration: Duration(seconds: 1),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: cpfController,
              decoration: const InputDecoration(labelText: 'CPF'),
            ),
            TextFormField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextFormField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            TextFormField(
              controller: aniversarioController,
              decoration: const InputDecoration(labelText: 'Data de Aniversário'),
            ),
            TextFormField(
              controller: produtoController,
              decoration: const InputDecoration(labelText: 'Produto desejado'),
            ),

            // 🔽 Dropdown dinâmico de marcas (igual ao cadastro)
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
              onPressed: _salvarEdicao,
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
