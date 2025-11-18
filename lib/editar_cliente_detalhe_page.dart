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
  State<EditarClienteDetalhePage> createState() =>
      _EditarClienteDetalhePageState();
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

  // 🔹 Cashback acumulado
  double _cashbackAcumulado = 0.0;

  // 🔐 Senha de administrador (troque para o que você quiser)
  static const String _adminSenha = '1234';

  @override
  void initState() {
    super.initState();

    final d = widget.dadosCliente;

    cpfController = MaskedTextController(
      mask: '000.000.000-00',
      text: (d['cpf'] ?? '').toString(),
    );
    nomeController =
        TextEditingController(text: (d['nome'] ?? '').toString());
    emailController =
        TextEditingController(text: (d['email'] ?? '').toString());
    telefoneController = MaskedTextController(
      mask: '(00) 00000-0000',
      text: (d['telefone'] ?? '').toString(),
    );
    aniversarioController = MaskedTextController(
      mask: '00/00/0000',
      text: (d['aniversario'] ?? '').toString(),
    );
    produtoController =
        TextEditingController(text: (d['produto'] ?? '').toString());
    observacoesController =
        TextEditingController(text: (d['observacoes'] ?? '').toString());

    // marcas selecionadas (novo array) com compat ao campo antigo 'marca'
    if (d['marcas'] is List) {
      _marcasSelecionadas = (d['marcas'] as List)
          .map((e) => (e ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } else if ((d['marca'] ?? '').toString().trim().isNotEmpty) {
      _marcasSelecionadas = [(d['marca'] as String).trim()];
    } else {
      _marcasSelecionadas = [];
    }

    // valor inicial (se vier algo no dadosCliente)
    final cb = d['cashback_acumulado'];
    if (cb is num) {
      _cashbackAcumulado = cb.toDouble();
    } else if (cb is String) {
      _cashbackAcumulado = double.tryParse(cb.replaceAll(',', '.')) ?? 0.0;
    } else {
      _cashbackAcumulado = 0.0;
    }

    _carregarMarcas();
    _carregarDadosDoFirestore(); // 🔴 recarrega e trata expiração
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
        final conjunto = <String>{...lista, ..._marcasSelecionadas};
        _todasMarcas = conjunto.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    } catch (_) {/* silencioso */}
  }

  // 🔴 Sempre pega o documento COMPLETO direto do Firestore e trata expiração de cashback
  Future<void> _carregarDadosDoFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .get();

      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      // Cashback atual
      double cb = 0.0;
      final campoCb = data['cashback_acumulado'];
      if (campoCb is num) {
        cb = campoCb.toDouble();
      } else if (campoCb is String) {
        cb = double.tryParse(campoCb.replaceAll(',', '.')) ?? 0.0;
      }

      // Data da última atualização
      Timestamp? tsUlt;
      final rawUlt = data['cashback_ultima_atualizacao'];
      if (rawUlt is Timestamp) {
        tsUlt = rawUlt;
      }

      final agora = DateTime.now();
      final limite = agora.subtract(const Duration(days: 180)); // ~6 meses

      bool expirou = false;

      if (tsUlt != null && cb > 0) {
        final dtUlt = tsUlt.toDate();
        if (dtUlt.isBefore(limite)) {
          // 🔴 Cashback vencido: zera no banco e registra expiração
          await FirebaseFirestore.instance
              .collection('clientes')
              .doc(widget.clienteId)
              .set({
            'cashback_acumulado': 0.0,
            'cashback_ultima_atualizacao': Timestamp.now(),
            'cashback_expirado_valor': cb,
            'cashback_expirado_ultima_vez': Timestamp.now(),
          }, SetOptions(merge: true));

          cb = 0.0;
          expirou = true;
        }
      }

      // Marcas (a partir dos dados mais recentes)
      List<String> novasMarcasSel;
      if (data['marcas'] is List) {
        novasMarcasSel = (data['marcas'] as List)
            .map((e) => (e ?? '').toString().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      } else if ((data['marca'] ?? '').toString().trim().isNotEmpty) {
        novasMarcasSel = [(data['marca'] as String).trim()];
      } else {
        novasMarcasSel = [];
      }

      if (!mounted) return;
      setState(() {
        _cashbackAcumulado = cb;

        cpfController.text = (data['cpf'] ?? '').toString();
        nomeController.text = (data['nome'] ?? '').toString();
        emailController.text = (data['email'] ?? '').toString();
        telefoneController.text = (data['telefone'] ?? '').toString();
        aniversarioController.text =
            (data['aniversario'] ?? '').toString();
        produtoController.text =
            (data['produto'] ?? '').toString();
        observacoesController.text =
            (data['observacoes'] ?? '').toString();

        _marcasSelecionadas = novasMarcasSel;
      });

      if (expirou && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O cashback desse cliente venceu (mais de 6 meses sem uso). Saldo zerado.',
            ),
          ),
        );
      }
    } catch (_) {
      // se der erro, mantém o valor atual
    }
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
              left: 16,
              right: 16,
              top: 8,
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
                            final marcado =
                                selecionadasTemp.contains(m);
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
                              ..sort((a, b) => a
                                  .toLowerCase()
                                  .compareTo(b.toLowerCase()));
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
                        .map(
                          (m) => Chip(
                            label: Text(m),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () {
                              setState(() {
                                _marcasSelecionadas.remove(m);
                              });
                            },
                          ),
                        )
                        .toList(),
                  )
                : const Text('Selecione uma ou mais marcas'),
          ),
        ),
      ],
    );
  }

  // 🔹 Diálogo para ajuste manual de cashback
  void _ajustarCashbackDialog() {
    final controller = TextEditingController(
      text: _cashbackAcumulado.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustar cashback'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Novo valor de cashback (R\$)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final txt = controller.text.replaceAll(',', '.');
              final novoValor = double.tryParse(txt) ?? 0.0;

              try {
                await FirebaseFirestore.instance
                    .collection('clientes')
                    .doc(widget.clienteId)
                    .update({
                  'cashback_acumulado': novoValor,
                  'cashback_ultima_atualizacao': Timestamp.now(),
                });

                // Depois de atualizar o banco, recarrega TODOS os dados
                await _carregarDadosDoFirestore();

                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Erro ao atualizar cashback: $e'),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // 🔐 Pede senha de administrador e retorna true/false
  Future<bool?> _pedirSenhaAdmin() async {
    final controller = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Senha de administrador'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Digite a senha',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final ok = controller.text == _adminSenha;
              Navigator.pop(context, ok);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // 🔧 Menu com opções avançadas (ajustar cashback / deletar cliente)
  Future<void> _abrirMenuAdminProtegido() async {
    final senhaOk = await _pedirSenhaAdmin();
    if (senhaOk != true) {
      if (senhaOk == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha incorreta')),
        );
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Ajustar cashback'),
              onTap: () {
                Navigator.pop(ctx);
                _ajustarCashbackDialog();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Deletar cliente',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarExcluirCliente();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExcluirCliente() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar cliente'),
        content: const Text(
          'Tem certeza que deseja deletar este cliente? '
          'Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cliente deletado com sucesso')),
      );

      Navigator.pop(context, true); // volta para a lista
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao deletar cliente: $e')),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final nomeCru = nomeController.text.trim();
    final nome = _capitalizarNome(nomeCru);
    nomeController.text = nome;

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
      'marca': marcasLimpas.isNotEmpty ? marcasLimpas.first : '',
      'marcas': marcasLimpas,
      // não mexemos em cashback aqui
    };

    try {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cliente atualizado com sucesso!')),
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
        .map(
          (p) => p[0].toUpperCase() +
              (p.length > 1
                  ? p.substring(1).toLowerCase()
                  : ''),
        )
        .toList();
    return partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Opções avançadas',
            onPressed: _abrirMenuAdminProtegido,
          ),
        ],
      ),
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
                decoration:
                    const InputDecoration(labelText: 'CPF'),
              ),

              // Nome
              TextFormField(
                controller: nomeController,
                decoration:
                    const InputDecoration(labelText: 'Nome'),
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
                decoration:
                    const InputDecoration(labelText: 'E-mail'),
              ),

              // Telefone
              TextFormField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Telefone'),
              ),

              // Data de aniversário
              TextFormField(
                controller: aniversarioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Data de Aniversário'),
              ),

              // Produto desejado
              TextFormField(
                controller: produtoController,
                decoration: const InputDecoration(
                    labelText: 'Produto desejado'),
              ),

              const SizedBox(height: 8),

              // Multi-marcas
              _campoMultiMarcas(),

              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: observacoesController,
                decoration:
                    const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // 🔹 Card de Cashback acumulado (somente visualização)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cashback acumulado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'R\$ ${_cashbackAcumulado.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔵 Botão Histórico de Vendas (secundário)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label:
                      const Text('Histórico de Vendas'),
                  onPressed: () {
                    final nomeAtual =
                        (nomeController.text.trim().isNotEmpty)
                            ? nomeController.text.trim()
                            : (widget.dadosCliente['nome'] ?? '')
                                .toString();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoricoVendasPage(
                          clienteId: widget.clienteId,
                          nomeCliente:
                              _capitalizarNome(nomeAtual),
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
                  label:
                      const Text('Salvar alterações'),
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(48),
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
