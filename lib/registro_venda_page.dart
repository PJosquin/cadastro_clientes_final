import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/cashback_service.dart'; // 🔹 serviço de configuração de cashback

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({Key? key}) : super(key: key);

  @override
  State<RegistroVendaPage> createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  // Busca de cliente (modelo antigo, interno à tela)
  final TextEditingController _buscaController = TextEditingController();
  String? _clienteSelecionadoId;
  String? _clienteSelecionadoNome;

  // Campos da venda
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _pecasController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _qrcodeController = TextEditingController();

  // 🔹 Campo para usar cashback
  final TextEditingController _usarCashbackController = TextEditingController();
  double _cashbackDisponivel = 0.0;

  bool _salvando = false;

  // 🔹 Cashback (config)
  double? _percentualCashback; // lido do Firestore (config/cashback/percentual)
  bool _carregandoCashback = true;

  @override
  void initState() {
    super.initState();
    _carregarPercentualCashback();
  }

  Future<void> _carregarPercentualCashback() async {
    try {
      final percentual = await CashbackService.instance.getPercentualCashback();
      if (!mounted) return;
      setState(() {
        _percentualCashback = percentual;
        _carregandoCashback = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _percentualCashback = 0.05; // fallback 5%
        _carregandoCashback = false;
      });
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _valorController.dispose();
    _pecasController.dispose();
    _notaController.dispose();
    _observacoesController.dispose();
    _qrcodeController.dispose();
    _usarCashbackController.dispose();
    super.dispose();
  }

  // === Busca flexível por nome/CPF/telefone (como nas versões estáveis antigas) ===
  Future<List<QueryDocumentSnapshot>> _buscarClientes(String termo) async {
    final termoLower = termo.toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('nome')
        .get();

    String normalize(String s) =>
        s.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();

    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nome = (data['nome'] ?? '').toString().toLowerCase();
      final cpf = (data['cpf'] ?? '').toString();
      final telefone = (data['telefone'] ?? '').toString();

      final termoNormalizado = normalize(termoLower);
      final nomeMatch = nome.contains(termoLower);
      final cpfMatch = normalize(cpf).contains(termoNormalizado);
      final telMatch = normalize(telefone).contains(termoNormalizado);

      return nomeMatch || cpfMatch || telMatch;
    }).toList();
  }

  Future<void> _selecionarCliente(String id, String nome) async {
    setState(() {
      _clienteSelecionadoId = id;
      _clienteSelecionadoNome = nome;
      _buscaController.text = nome;
      _cashbackDisponivel = 0.0;
      _usarCashbackController.clear();
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(id)
          .get();

      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      double cb = 0.0;
      final campo = data['cashback_acumulado'];
      if (campo is num) {
        cb = campo.toDouble();
      } else if (campo is String) {
        cb = double.tryParse(campo.replaceAll(',', '.')) ?? 0.0;
      }

      if (!mounted) return;
      setState(() {
        _cashbackDisponivel = cb;
        // Se quiser sempre usar tudo por padrão:
        if (_cashbackDisponivel > 0) {
          _usarCashbackController.text =
              _cashbackDisponivel.toStringAsFixed(2);
        }
      });
    } catch (_) {
      // se der erro, apenas mantém cashbackDisponivel = 0.0
    }
  }

  Future<void> _salvarVenda() async {
    if (_clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Selecione um cliente antes de registrar.")),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      // Converter valor em double (aceita vírgula)
      final valor = double.tryParse(
              _valorController.text.replaceAll('.', '').replaceAll(',', '.')) ??
          0.0;
      final pecas = int.tryParse(_pecasController.text.trim()) ?? 0;

      // 🔹 Valor de cashback a usar (opcional)
      double usarCashback = 0.0;
      if (_usarCashbackController.text.trim().isNotEmpty) {
        usarCashback = double.tryParse(_usarCashbackController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '.')) ??
                0.0;
      }

      if (usarCashback < 0) usarCashback = 0.0;

      // Não deixar usar mais do que o disponível (com pequena tolerância)
      if (usarCashback > _cashbackDisponivel + 0.01) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Você tentou usar R\$ ${usarCashback.toStringAsFixed(2)}, mas o disponível é R\$ ${_cashbackDisponivel.toStringAsFixed(2)}.'),
          ),
        );
        setState(() => _salvando = false);
        return;
      }

      // 🔹 Calcula cashback GERADO por esta venda, com base no percentual
      final double percentual = _percentualCashback ?? 0.05; // fallback 5%
      final double cashbackGerado = valor * percentual;

      // 🔹 Valor líquido (o que o cliente paga após desconto de cashback)
      final double valorLiquido = valor - usarCashback;

      // 🔹 Salva a venda com campos de cashback e desconto
      await FirebaseFirestore.instance.collection('vendas').add({
        'clienteId': _clienteSelecionadoId,
        'clienteNome': _clienteSelecionadoNome,
        'data': Timestamp.now(),
        'valor': valor, // valor bruto
        'valor_liquido': valorLiquido, // após desconto de cashback
        'desconto_cashback': usarCashback,
        'numero_pecas': pecas, // compatível com histórico
        'numero_nota': _notaController.text.trim(), // compatível com histórico
        'observacoes': _observacoesController.text.trim(),
        'qrcode': _qrcodeController.text.trim(), // preenchido pelo scanner
        'cashback_gerado': cashbackGerado,
        'percentual_cashback': percentual,
      });

      // 🔹 Atualiza saldo de cashback do cliente:
      // saldo novo = saldo antigo - usado + gerado
      final double deltaCashback = cashbackGerado - usarCashback;

      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(_clienteSelecionadoId)
          .set({
        'cashback_acumulado': FieldValue.increment(deltaCashback),
        'cashback_ultima_atualizacao': Timestamp.now(),
      }, SetOptions(merge: true));

      // Atualiza o valor em memória também (para uma próxima venda na mesma tela)
      setState(() {
        _cashbackDisponivel =
            (_cashbackDisponivel - usarCashback) + cashbackGerado;
        if (_cashbackDisponivel < 0.009) {
          _cashbackDisponivel = 0.0; // evita -0.00 por arredondamento
        }
        _usarCashbackController.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venda registrada com sucesso!")),
      );

      // Limpa campos (mantém cliente selecionado)
      _valorController.clear();
      _pecasController.clear();
      _notaController.clear();
      _observacoesController.clear();
      _qrcodeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Venda")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ======= Busca de cliente (como era antes) =======
            TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: "Buscar cliente (nome, CPF ou telefone)",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _buscarClientes(_buscaController.text),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final clientes = snapshot.data!;
                if (clientes.isEmpty) {
                  return const Text("Nenhum cliente encontrado.");
                }
                return Column(
                  children: clientes.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nome = data['nome'] ?? '';
                    final cpf = data['cpf'] ?? '';
                    final telefone = data['telefone'] ?? '';
                    return ListTile(
                      title: Text(nome),
                      subtitle: Text("CPF: $cpf\nTelefone: $telefone"),
                      onTap: () {
                        _selecionarCliente(doc.id, nome);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),

            if (_clienteSelecionadoNome != null)
              Card(
                color: Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(_clienteSelecionadoNome ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Cliente selecionado"),
                      const SizedBox(height: 4),
                      Text(
                        "Cashback disponível: R\$ ${_cashbackDisponivel.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _clienteSelecionadoId = null;
                        _clienteSelecionadoNome = null;
                        _buscaController.clear();
                        _cashbackDisponivel = 0.0;
                        _usarCashbackController.clear();
                      });
                    },
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ======= Form da venda =======
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o valor' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pecasController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Peças (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notaController,
                    decoration: const InputDecoration(
                      labelText: 'Número da Nota',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Campo do QR Code + botão de escanear (logo abaixo)
                  TextFormField(
                    controller: _qrcodeController,
                    decoration: const InputDecoration(
                      labelText: 'QR Code da Nota Fiscal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // === Botão Escanear Nota Fiscal (QR Code) ===
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: Colors.white),
                      label: const Text(
                        'Escanear Nota Fiscal (QR Code)',
                        style:
                            TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _QrCodeScannerPage(),
                          ),
                        );
                        if (resultado != null && resultado is String) {
                          setState(
                              () => _qrcodeController.text = resultado);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Campo para usar cashback
                  TextFormField(
                    controller: _usarCashbackController,
                    decoration: InputDecoration(
                      labelText:
                          'Usar cashback (R\$) — disponível: ${_cashbackDisponivel.toStringAsFixed(2)}',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 20),

                  // Botão salvar (sem mudar layout)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Salvar Venda',
                        style:
                            TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _salvando ? null : _salvarVenda,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======= Tela leve de Scanner usando mobile_scanner =======
class _QrCodeScannerPage extends StatelessWidget {
  const _QrCodeScannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final codigo = barcodes.first.rawValue ?? '';
            Navigator.pop(context, codigo);
          }
        },
      ),
    );
  }
}
