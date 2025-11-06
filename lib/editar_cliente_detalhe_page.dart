import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:cadastro_clientes/historico_vendas_page.dart';

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
  final _formKey = GlobalKey<FormState>();

  late final MaskedTextController cpfController;
  late final TextEditingController nomeController;
  late final TextEditingController emailController;
  late final MaskedTextController telefoneController;
  late final MaskedTextController aniversarioController;
  late final TextEditingController produtoController;
  late final TextEditingController observacoesController;

  String? _marcaSelecionada;

  @override
  void initState() {
    super.initState();
    final d = widget.dadosCliente;

    cpfController = MaskedTextController(mask: '000.000.000-00', text: (d['cpf'] ?? '').toString());
    nomeController = TextEditingController(text: (d['nome'] ?? '').toString());
    emailController = TextEditingController(text: (d['email'] ?? '').toString());
    telefoneController = MaskedTextController(mask: '(00) 00000-0000', text: (d['telefone'] ?? '').toString());
    aniversarioController = MaskedTextController(mask: '00/00/0000', text: (d['aniversario'] ?? '').toString());
    produtoController = TextEditingController(text: (d['produto'] ?? '').toString());
    observacoesController = TextEditingController(text: (d['observacoes'] ?? '').toString());

    _marcaSelecionada = (d['marca'] ?? '').toString().isNotEmpty ? (d['marca'] as String) : null;
  }

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

  String _capitalizarNome(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + (p.length > 1 ? p.substring(1).toLowerCase() : ''))
        .toList();
    return partes.join(' ');
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    final nomeCru = nomeController.text.trim();
    final nome = _capitalizarNome(nomeCru); // ✅ capitaliza ao editar

    try {
      await FirebaseFirestore.instance.collection('clientes').doc(widget.clienteId).update({
        'cpf': cpfController.text.trim(),
        'nome': nome, // ✅ salvo capitalizado
        'email': emailController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'aniversario': aniversarioController.text.trim(),
        'produto': produtoController.text.trim(),
        'marca': _marcaSelecionada ?? '',
        'observacoes': observacoesController.text.trim(),
        // 'dataCadastro' não é alterado aqui
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alterações salvas!')),
      );
      Navigator.pop(context); // volta para a lista
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
      appBar: AppBar(title: const Text('Editar Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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

              // Nome (obrigatório) — capitalizado no salvar
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

              // Telefone
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
              // Dropdown de marcas (opcional)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('marcas')
                    .orderBy('nome')
                    .snapshots(),
                builder: (context, snapshot) {
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvarAlteracoes,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar alterações'),
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
