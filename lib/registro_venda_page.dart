import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // para escanear QRCode

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({super.key});

  @override
  _RegistroVendaPageState createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  String? _clienteSelecionadoId;
  String? _clienteSelecionadoNome;
  String? _qrcodeLido;

  @override
  void dispose() {
    _buscaController.dispose();
    _produtoController.dispose();
    _notaController.dispose();
    _valorController.dispose();
    super.dispose();
  }

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
      return nome.contains(termoLower) ||
          normalize(cpf).contains(termoNormalizado) ||
          normalize(telefone).contains(termoNormalizado);
    }).toList();
  }

  Future<void> _registrarVenda() async {
    if (_clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um cliente antes de registrar.")),
      );
      return;
    }

    final produto = _produtoController.text.trim();
    final numeroNota = _notaController.text.trim();
    final valor = double.tryParse(_valorController.text.trim()) ?? 0;
    final qrcode = _qrcodeLido?.trim() ?? '';

    if (produto.isEmpty || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o produto e o valor corretamente.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('vendas').add({
      'cliente': _clienteSelecionadoNome,
      'clienteId': _clienteSelecionadoId,
      'produto': produto,
      'numero_nota': numeroNota, // ✅ nome igual ao Firestore
      'qrcode': qrcode,          // ✅ opcional, se escanear QRCode
      'valor': valor,
      'data': Timestamp.now(),
      'dataRegistro': Timestamp.now(),
      'numero_pecas': 1,
      'observacoes': '',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Venda registrada com sucesso!")),
    );

    _produtoController.clear();
    _notaController.clear();
    _valorController.clear();
    setState(() {
      _clienteSelecionadoId = null;
      _clienteSelecionadoNome = null;
      _qrcodeLido = null;
    });
  }

  Future<void> _lerNotaFiscal() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Escanear Nota Fiscal (QR Code)"),
        content: SizedBox(
          height: 300,
          width: 300,
          child: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final valor = barcodes.first.rawValue ?? "";
                if (valor.isNotEmpty) {
                  setState(() {
                    _qrcodeLido = valor; // ✅ grava apenas no campo qrcode
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("QR Code escaneado e salvo!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Venda")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: "Buscar cliente (nome, CPF ou telefone)",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (valor) => setState(() {}),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _buscarClientes(_buscaController.text),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final clientes = snapshot.data!;
                if (clientes.isEmpty) return const Text("Nenhum cliente encontrado.");

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
            const SizedBox(height: 20),
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
                    onPressed: () => setState(() {
                      _clienteSelecionadoId = null;
                      _clienteSelecionadoNome = null;
                    }),
                  ),
                ),
              ),
            TextField(
              controller: _produtoController,
              decoration: const InputDecoration(labelText: "Produto"),
            ),
            TextField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: "Número da Nota Fiscal (opcional)",
              ),
            ),
            TextField(
              controller: _valorController,
              decoration: const InputDecoration(labelText: "Valor"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 10),

            // ✅ Botão novo para escanear QR Code
            ElevatedButton.icon(
              onPressed: _lerNotaFiscal,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Escanear Nota Fiscal (QR Code)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _qrcodeLido == null
                    ? Colors.blue.shade100
                    : Colors.blue.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            // ✅ Mostra o QRCode lido abaixo do botão (se existir)
            if (_qrcodeLido != null && _qrcodeLido!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.link, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _qrcodeLido!,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // ✅ Botão original para salvar
            ElevatedButton.icon(
              onPressed: _registrarVenda,
              icon: const Icon(Icons.check),
              label: const Text("Registrar Venda"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
