// lib/editar_cliente_detalhe_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'historico_vendas_page.dart'; // ✅ IMPORTADO para abrir o histórico

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

  List<String> _todasMarcas = [];
  List<String> _marcasSelecionadas = [];

  @override
  void initState() {
    super.initState();

    final d = widget.dadosCliente;

    cpfController = MaskedTextController(
      mask: '000.000.000-00',
      text: (d['cpf'] ?? '').toString(),
    );
    nomeController = TextEditingController(text: (d['nome'] ?? '').toString());
    emailController = TextEditingController(text: (d['email'] ?? '').toString());
    telefoneController = MaskedTextController(
      mask: '(00) 00000-0000',
      text: (d['telefone'] ?? '').toString(),
    );
    aniversarioController = MaskedTextController(
      mask: '00/00/0000',
      text: (d['aniversario'] ?? '').toString(),
    );
    produtoController = TextEditingController(text: (d['produto'] ?? '').toString());
    observacoesController = TextEditingController(text: (d['observacoes'] ?? '').toString());

    // marcas selecionadas (novo array) com compat ao campo antigo 'marca'
    if (d['marcas'] is List) {
      _marcasSelecionadas = (d['marcas'] as List)
          .map((e) => (e ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet() // 🔧 sem duplicatas
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); // 🔧 ordenado
    } else if ((d['marca'] ?? '').toString().trim().isNotEmpty) {
      _marcasSelecionadas = [(d['marca'] as String).trim()];
    } else {
      _marcasSelecionadas = [];
    }

    _carregarMarcas();
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

  Future<void> _carregarMarcas() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('marcas')
          .orderBy('nome')
          .get();

      final lista = snap.docs
          .map((d) => (d.data()['nome']?.toString() ?? '').trim())
          .where((s) => s.isNotEmpty)
          .toList();

      setState(() {
        // 🔧 Inclui também as marcas já salvas no cliente (mesmo que não existam mais na coleção)
        final conjunto = <String>{...lista, ..._marcasSelecionadas};
        _todasMarcas = conjunto.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    } catch (_) {/* silencioso */}
  }

  void _abrirSeletorMarcas() {
    final selecionadasTemp = Set<String>.from(_marcasSelecionadas);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione uma ou mais marcas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: _todasMarcas.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _todasMarcas.length,
                          itemBuilder: (c, i) {
                            final m = _todasMarcas[i];
                            final marcado = selecionadasTemp.contains(m);
                            return CheckboxListTile(
                              value: marcado,
                              title: Text(m),
                              onChanged: (v) {
                                if (v == true) {
                                  selecionadasTemp.add(m);
                                } else {
                                  selecionadasTemp.remove(m);
                                }
                                (ctx as Element).markNeedsBuild();
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _marcasSelecionadas = selecionadasTemp
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toSet()
                                .toList()
                              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _campoMultiMarcas() {
    final hasSel = _marcasSelecionadas.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Marcas (opcional)', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _abrirSeletorMarcas,
          child: InputDecorator(
            isFocused: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecione uma ou mais marcas',
            ),
            child: hasSel
                ? Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: _marcasSelecionadas
                        .map((m) => Chip(
                              label: Text(m),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onDeleted: () {
                                setState(() {
                                  _marcasSelecionadas.remove(m);
                                });
                              },
                            ))
                        .toList(),
                  )
                : const Text('Selecione uma ou mais marcas'),
          ),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final nomeCru = nomeController.text.trim();
    final nome = _capitalizarNome(nomeCru);
    nomeController.text = nome;

    // 🔧 Normaliza lista antes de salvar
    final marcasLimpas = _marcasSelecionadas
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final data = <String, dynamic>{
      'cpf': cpfController.text.trim(),
      'nome': nome,
      'email': emailController.text.trim(),
      'telefone': telefoneController.text.trim(),
      'aniversario': aniversarioController.text.trim(),
      'produto': produtoController.text.trim(),
      'observacoes': observacoesController.text.trim(),
      // compat legado + multi
      'marca': marcasLimpas.isNotEmpty ? marcasLimpas.first : '',
      'marcas': marcasLimpas,
    };

    try {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .update(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente atualizado com sucesso!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
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
              // CPF
              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),

              // Nome
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

              // Multi-marcas
              _campoMultiMarcas(),

              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // 🔵 Botão Histórico de Vendas (secundário)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico de Vendas'),
                  onPressed: () {
                    final nomeAtual = (nomeController.text.trim().isNotEmpty)
                        ? nomeController.text.trim()
                        : (widget.dadosCliente['nome'] ?? '').toString();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoricoVendasPage(
                          clienteId: widget.clienteId,
                          nomeCliente: _capitalizarNome(nomeAtual),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar alterações'),
                  onPressed: _salvar,
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
