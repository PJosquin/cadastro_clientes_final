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

  // Controladores
  final cpfController = MaskedTextController(mask: '000.000.000-00');
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = MaskedTextController(mask: '(00) 00000-0000');
  final aniversarioController = MaskedTextController(mask: '00/00/0000');
  final produtoController = TextEditingController();
  final observacoesController = TextEditingController();

  String? _marcaSelecionada; // dropdown (opcional)

  @override
  void dispose() {
    cpfController.dispose();
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    aniversarioController.dispose();
    produtoController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  // 🔠 Capitaliza cada palavra
  String _capitalizarNome(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + (p.length > 1 ? p.substring(1).toLowerCase() : ''))
        .toList();
    return partes.join(' ');
  }

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final cpf = cpfController.text.trim();
    final nomeCru = nomeController.text.trim();

    // ✅ NOVO: capitaliza e atualiza o campo visível
    final nome = _capitalizarNome(nomeCru);
    nomeController.text = nome;

    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final aniversario = aniversarioController.text.trim();
    final produto = produtoController.text.trim();
    final observacoes = observacoesController.text.trim();
    final marca = _marcaSelecionada ?? ''; // opcional

    try {
      await FirebaseFirestore.instance.collection('clientes').add({
        'cpf': cpf,
        'nome': nome, // ✅ salvo capitalizado
        'email': email,
        'telefone': telefone,
        'aniversario': aniversario,
        'produto': produto,
        'marca': marca,
        'observacoes': observacoes,
        'dataCadastro': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo com sucesso!')),
      );

      // Limpa os campos
      _formKey.currentState!.reset();
      cpfController.updateText('');
      telefoneController.updateText('');
      aniversarioController.updateText('');
      nomeController.clear();
      emailController.clear();
      produtoController.clear();
      observacoesController.clear();
      setState(() => _marcaSelecionada = null);
    } catch (e) {
      if (!mounted) return;
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
              // CPF (opcional)
              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),

              // Nome (obrigatório)
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),

              // E-mail
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),

              // Telefone (opcional)
              TextFormField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),

              // Data de aniversário
              TextFormField(
                controller: aniversarioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Data de Aniversário'),
              ),

              // Produto desejado
              TextFormField(
                controller: produtoController,
                decoration: const InputDecoration(labelText: 'Produto desejado'),
              ),

              const SizedBox(height: 8),

              // 🔽 Dropdown de Marcas (opcional, carrega do Firestore)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('marcas')
                    .orderBy('nome')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final itens = snapshot.hasData
                      ? snapshot.data!.docs
                          .map((d) => (d.data() as Map<String, dynamic>)['nome']?.toString() ?? '')
                          .where((s) => s.isNotEmpty)
                          .toList()
                      : <String>[];

                  return DropdownButtonFormField<String>(
                    value: (_marcaSelecionada != null && itens.contains(_marcaSelecionada))
                        ? _marcaSelecionada
                        : null,
                    items: itens
                        .map((m) => DropdownMenuItem<String>(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _marcaSelecionada = v),
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                  );
                },
              ),

              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvarCliente,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
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
