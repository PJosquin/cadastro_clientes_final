import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // Marcas
  List<String> _todasMarcas = [];
  List<String> _marcasSelecionadas = [];

  @override
  void initState() {
    super.initState();
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

  // ---- Utilitários ----
  String _capitalizarNome(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + (p.length > 1 ? p.substring(1).toLowerCase() : ''))
        .toList();
    return partes.join(' ');
  }

  String _somenteDigitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _abrirWhatsApp(String telefoneE164, String texto) async {
    final uri = Uri.parse('https://wa.me/$telefoneE164?text=${Uri.encodeComponent(texto)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  void _mostrarSheetWhatsapp({
    required String telefoneBr,
    required String nome,
  }) {
    final telDigits = _somenteDigitos(telefoneBr);
    if (telDigits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone vazio — não dá para enviar no WhatsApp.')),
      );
      return;
    }
    final telefoneE164 = telDigits.length >= 10 ? '55$telDigits' : telDigits;

    final controllerMensagem = TextEditingController(
      text: 'Olá, $nome! Queremos agradecer de coração pela sua compra. '
          'Ficamos muito felizes em ter você como cliente!\n\n'
          'Este é o nosso contato oficial. Anote aí! '
          'Estamos à disposição para qualquer dúvida ou suporte que precisar.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enviar mensagem no WhatsApp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controllerMensagem,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Mensagem (editável)',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp),
                    label: const Text('Enviar no WhatsApp'),
                    onPressed: () {
                      final msg = controllerMensagem.text.trim();
                      Navigator.pop(ctx);
                      _abrirWhatsApp(telefoneE164, msg.isEmpty ? 'Olá!' : msg);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        _todasMarcas = lista;
      });
    } catch (_) {/* segue sem travar */}
  }

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final cpf = cpfController.text.trim();
    final nomeCru = nomeController.text.trim();
    final nome = _capitalizarNome(nomeCru);
    nomeController.text = nome;

    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final aniversario = aniversarioController.text.trim();
    final produto = produtoController.text.trim();
    final observacoes = observacoesController.text.trim();

    // Compat: 'marca' = primeira marca (ou vazio); 'marcas' = array completo
    final marcaCompat = _marcasSelecionadas.isNotEmpty ? _marcasSelecionadas.first : '';

    try {
      await FirebaseFirestore.instance.collection('clientes').add({
        'cpf': cpf,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'aniversario': aniversario,
        'produto': produto,
        'marca': marcaCompat,            // <= compat com telas antigas
        'marcas': _marcasSelecionadas,   // <= novo campo multi
        'observacoes': observacoes,
        'dataCadastro': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente salvo com sucesso!'),
          duration: Duration(seconds: 2),
        ),
      );

      _mostrarSheetWhatsapp(
        telefoneBr: telefone,
        nome: nome,
      );

      // Limpar
      _formKey.currentState!.reset();
      cpfController.updateText('');
      telefoneController.updateText('');
      aniversarioController.updateText('');
      nomeController.clear();
      emailController.clear();
      produtoController.clear();
      observacoesController.clear();
      setState(() {
        _marcasSelecionadas = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  // ---- UI multi-marcas (sem mexer no restante do layout) ----
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
                                // força rebuild do bottom-sheet
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
                            _marcasSelecionadas = selecionadasTemp.toList()..sort();
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

              // >>> Multi-marcas (opcional) — substitui o dropdown, mantendo compat na gravação
              _campoMultiMarcas(),

              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Botão Salvar (largura total)
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
