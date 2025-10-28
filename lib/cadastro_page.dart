import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:url_launcher/url_launcher.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({Key? key}) : super(key: key);

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final cpfController = MaskedTextController(mask: '000.000.000-00');
  final telefoneController = MaskedTextController(mask: '(00) 00000-0000');
  final aniversarioController = MaskedTextController(mask: '00/00/0000');
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final produtoController = TextEditingController();
  final observacoesController = TextEditingController();

  String? _marcaSelecionada;
  bool _clienteSalvo = false;
  String? _telefoneSalvo;

  final TextEditingController _mensagemController = TextEditingController(
    text: 'Olá! Queremos agradecer de coração pela sua compra. '
        'Ficamos muito felizes em ter você como cliente!\n\n'
        'Este é o nosso contato oficial. Anote aí! '
        'Estamos à disposição para qualquer dúvida ou suporte que precisar.',
  );

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final cpf = cpfController.text.trim();
    final aniversario = aniversarioController.text.trim();
    final produto = produtoController.text.trim();
    final observacoes = observacoesController.text.trim();
    final marca = _marcaSelecionada ?? '';

    await FirebaseFirestore.instance.collection('clientes').add({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
      'aniversario': aniversario,
      'produto': produto,
      'observacoes': observacoes,
      'marcas': [marca],
      'dataCadastro': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Cliente salvo com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      _clienteSalvo = true;
      _telefoneSalvo = telefone;
    });

    _formKey.currentState!.reset();
    nomeController.clear();
    emailController.clear();
    telefoneController.updateText('');
    cpfController.updateText('');
    aniversarioController.updateText('');
    produtoController.clear();
    observacoesController.clear();
    _marcaSelecionada = null;
  }

  Future<void> _abrirWhatsApp() async {
    if (_telefoneSalvo == null || _telefoneSalvo!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone não informado')),
      );
      return;
    }

    final numero = _telefoneSalvo!.replaceAll(RegExp(r'[^0-9]'), '');
    final mensagem = Uri.encodeComponent(_mensagemController.text);
    final url = 'https://wa.me/55$numero?text=$mensagem';
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Cliente'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: cpfController,
                decoration: const InputDecoration(labelText: 'CPF (opcional)'),
              ),
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: (v) => v == null || v.isEmpty
                    ? 'Informe o telefone do cliente'
                    : null,
              ),
              TextFormField(
                controller: aniversarioController,
                decoration:
                    const InputDecoration(labelText: 'Data de Aniversário'),
              ),
              TextFormField(
                controller: produtoController,
                decoration: const InputDecoration(labelText: 'Produto'),
              ),
              const SizedBox(height: 10),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('marcas')
                    .orderBy('nome')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final marcas = snapshot.data!.docs
                      .map((doc) => doc['nome'].toString())
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: _marcaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Marca (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    items: marcas
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _marcaSelecionada = v;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _salvarCliente,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Cliente'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),
              if (_clienteSalvo)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _mensagemController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Mensagem para enviar no WhatsApp',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _abrirWhatsApp,
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text('Enviar pelo WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
