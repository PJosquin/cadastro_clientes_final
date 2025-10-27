import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool _mostrarBotaoWhatsApp = false;

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final cliente = {
      'cpf': cpfController.text.trim(),
      'nome': nomeController.text.trim(),
      'email': emailController.text.trim(),
      'telefone': telefoneController.text.trim(),
      'aniversario': aniversarioController.text.trim(),
      'produto': produtoController.text.trim(),
      'marcas': [marcaController.text.trim()],
      'observacoes': observacoesController.text.trim(),
      'dataCadastro': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('clientes').add(cliente);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cliente salvo com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      _mostrarBotaoWhatsApp = true;
    });
  }

  void _enviarWhatsApp() async {
    final telefone = telefoneController.text
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (telefone.isEmpty) return;

    final mensagem = Uri.encodeComponent(
      'Olá! Queremos agradecer de coração pela sua compra. '
      'Ficamos muito felizes em ter você como cliente!\n\n'
      'Este é o nosso contato oficial. Anote aí! '
      'Estamos à disposição para qualquer dúvida ou suporte que precisar.',
    );

    final url = Uri.parse('https://wa.me/55$telefone?text=$mensagem');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }

  @override
  void dispose() {
    cpfController.dispose();
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    aniversarioController.dispose();
    produtoController.dispose();
    marcaController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Cliente'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: aniversarioController,
                decoration: const InputDecoration(labelText: 'Data de Aniversário'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: produtoController,
                decoration: const InputDecoration(labelText: 'Produto'),
              ),
              TextFormField(
                controller: marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Salvar Cliente',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              if (_mostrarBotaoWhatsApp)
                ElevatedButton.icon(
                  onPressed: _enviarWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    "Enviar mensagem via WhatsApp",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


