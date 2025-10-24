import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final DateTime dataCadastro = DateTime.now();

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final cpf = cpfController.text.trim();
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final aniversario = aniversarioController.text.trim();
    final produto = produtoController.text.trim();
    final marca = marcaController.text.trim();
    final observacoes = observacoesController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('clientes').add({
        'cpf': cpf,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'aniversario': aniversario,
        'produto': produto,
        'marca': marca,
        'observacoes': observacoes,
        'dataCadastro': dataCadastro,
      });

      // Mostra mensagem temporária de sucesso (2 segundos)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente salvo com sucesso!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Mensagem padrão personalizável
      final mensagemController = TextEditingController(
        text:
            "Olá $nome! Queremos agradecer de coração pela sua compra. Ficamos muito felizes em ter você como cliente!\n\nEste é o nosso contato oficial. Anote aí! Estamos à disposição para qualquer dúvida ou suporte que precisar.",
      );

      // Aguarda 2 segundos e mostra o dialog para enviar WhatsApp
      await Future.delayed(const Duration(seconds: 2));

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enviar mensagem pelo WhatsApp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Você pode editar a mensagem antes de enviar:'),
              const SizedBox(height: 10),
              TextField(
                controller: mensagemController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mensagem',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                final mensagem = Uri.encodeComponent(mensagemController.text);
                final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
                final url = "https://wa.me/55$numeroLimpo?text=$mensagem";

                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível abrir o WhatsApp.'),
                    ),
                  );
                }
              },
              child: const Text('Enviar WhatsApp'),
            ),
          ],
        ),
      );

      // Limpa os campos após salvar
      _formKey.currentState!.reset();
      cpfController.updateText('');
      telefoneController.updateText('');
      aniversarioController.updateText('');
      nomeController.clear();
      emailController.clear();
      produtoController.clear();
      marcaController.clear();
      observacoesController.clear();

      setState(() {});
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
        padding: const EdgeInsets.all(16.0),
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
              ElevatedButton.icon(
                onPressed: _salvarCliente,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Salvar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
