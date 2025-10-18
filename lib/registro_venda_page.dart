import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'leitor_qrcode_page.dart';

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({Key? key}) : super(key: key);

  @override
  _RegistroVendaPageState createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _notaFiscalController = TextEditingController();
  final TextEditingController _pecasController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );

  String? _clienteSelecionadoId;
  String? qrCodeNotaFiscal;
  List<Map<String, dynamic>> resultadosPesquisa = [];
  bool _salvando = false;

  Future<void> _pesquisarClientes(String query) async {
    if (query.isEmpty) {
      setState(() => resultadosPesquisa = []);
      return;
    }

    final queryLower = query.toLowerCase();

    final snapshot = await FirebaseFirestore.instance.collection('clientes').get();

    final resultados = snapshot.docs.where((doc) {
      final data = doc.data();
      final nome = (data['nome'] ?? '').toString().toLowerCase();
      final cpf = (data['cpf'] ?? '').toString().toLowerCase();
      final telefone = (data['telefone'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();

      return nome.contains(queryLower) ||
          cpf.contains(queryLower) ||
          telefone.contains(queryLower) ||
          email.contains(queryLower);
    }).map((doc) => {'id': doc.id, ...doc.data()}).toList();

    setState(() {
      resultadosPesquisa = resultados;
    });
  }

  Future<void> _lerQRCode() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeitorQrCodePage()),
    );

    if (resultado != null && resultado is String) {
      setState(() {
        qrCodeNotaFiscal = resultado;
      });
    }
  }

  Future<void> _salvarVenda() async {
    if (_clienteController.text.isEmpty ||
        _valorController.text.isEmpty ||
        _pecasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
      return;
    }

    if (_clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente da lista.')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final valorDouble = double.tryParse(
              _valorController.text.replaceAll(',', '.').trim()) ??
          0.0;

      final dataSelecionada =
          DateFormat('dd/MM/yyyy').parse(_dataController.text);

      await FirebaseFirestore.instance.collection('vendas').add({
        'clienteId': _clienteSelecionadoId,
        'cliente': _clienteController.text,
        'numero_nota': _notaFiscalController.text,
        'numero_pecas': int.tryParse(_pecasController.text) ?? 0,
        'valor': valorDouble,
        'observacoes': _observacaoController.text,
        'data': dataSelecionada,
        'dataRegistro': FieldValue.serverTimestamp(),
        'qrcode': qrCodeNotaFiscal ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda registrada com sucesso!')),
      );

      _clienteController.clear();
      _notaFiscalController.clear();
      _pecasController.clear();
      _valorController.clear();
      _observacaoController.clear();
      _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      setState(() {
        qrCodeNotaFiscal = null;
        resultadosPesquisa = [];
        _clienteSelecionadoId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar venda: $e')),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _abrirNotaFiscal() async {
    if (qrCodeNotaFiscal == null || qrCodeNotaFiscal!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum QR Code salvo.')),
      );
      return;
    }

    String url = qrCodeNotaFiscal!.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Endereço inválido: $url')),
      );
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir a nota fiscal.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir nota fiscal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Venda'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Ler QR Code',
            onPressed: _lerQRCode,
          ),
        ],
      ),
      body: _salvando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _clienteController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente (nome, CPF, telefone ou e-mail)',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _pesquisarClientes,
                  ),

                  if (resultadosPesquisa.isNotEmpty)
                    Container(
                      height: 220,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: resultadosPesquisa.length,
                        itemBuilder: (context, index) {
                          final cliente = resultadosPesquisa[index];
                          final cpf = cliente['cpf'] ?? '';
                          final telefone = cliente['telefone'] ?? '';
                          final email = cliente['email'] ?? '';

                          return ListTile(
                            title: Text(cliente['nome'] ?? ''),
                            subtitle: Text(
                              [
                                if (cpf.isNotEmpty) 'CPF: $cpf',
                                if (telefone.isNotEmpty) 'Tel: $telefone',
                                if (email.isNotEmpty) 'Email: $email',
                              ].join(' • '),
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              setState(() {
                                _clienteController.text = cliente['nome'] ?? '';
                                _clienteSelecionadoId = cliente['id'];
                                resultadosPesquisa = [];
                              });
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _notaFiscalController,
                    decoration: const InputDecoration(
                      labelText: 'Número da Nota Fiscal',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 10),
                  // 🔹 Campo Data da Venda (com ícone de calendário)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dataController,
                          decoration: const InputDecoration(
                            labelText: 'Data da Venda',
                            prefixIcon: Icon(Icons.date_range),
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        tooltip: 'Selecionar Data',
                        onPressed: () async {
                          final dataSelecionada = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            locale: const Locale('pt', 'BR'),
                          );
                          if (dataSelecionada != null) {
                            _dataController.text =
                                DateFormat('dd/MM/yyyy')
                                    .format(dataSelecionada);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _pecasController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Peças',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor da Venda (R\$)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _observacaoController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  if (qrCodeNotaFiscal != null && qrCodeNotaFiscal!.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          'QR Code salvo:',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          qrCodeNotaFiscal!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _abrirNotaFiscal,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Abrir Nota Fiscal'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Venda'),
                    onPressed: _salvarVenda,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

