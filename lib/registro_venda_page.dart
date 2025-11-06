import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  bool _salvando = false;

  @override
  void dispose() {
    _buscaController.dispose();
    _valorController.dispose();
    _pecasController.dispose();
    _notaController.dispose();
    _observacoesController.dispose();
    _qrcodeController.dispose();
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

  Future<void> _salvarVenda() async {
    if (_clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um cliente antes de registrar.")),
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

      await FirebaseFirestore.instance.collection('vendas').add({
        'clienteId': _clienteSelecionadoId,
        'clienteNome': _clienteSelecionadoNome,
        'data': Timestamp.now(),
        'valor': valor, // double
        'numero_pecas': pecas, // compatível com histórico
        'numero_nota': _notaController.text.trim(), // compatível com histórico
        'observacoes': _observacoesController.text.trim(),
        'qrcode': _qrcodeController.text.trim(), // preenchido pelo scanner
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
                        setState(() {
                          _clienteSelecionadoId = doc.id;
                          _clienteSelecionadoNome = nome;
                          _buscaController.text = nome;
                        });
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
                  subtitle: const Text("Cliente selecionado"),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _clienteSelecionadoId = null;
                        _clienteSelecionadoNome = null;
                        _buscaController.clear();
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
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Informe o valor'
                        : null,
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
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text(
                        'Escanear Nota Fiscal (QR Code)',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _QrCodeScannerPage(),
                          ),
                        );
                        if (resultado != null && resultado is String) {
                          setState(() => _qrcodeController.text = resultado);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botão salvar (sem mudar layout)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Salvar Venda',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
