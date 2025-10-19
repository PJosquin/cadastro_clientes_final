import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({super.key});

  @override
  _RegistroVendaPageState createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _notaFiscalController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  String? _clienteSelecionadoId;
  String? _clienteSelecionadoNome;

  @override
  void dispose() {
    _buscaController.dispose();
    _produtoController.dispose();
    _notaFiscalController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot>> _buscarClientes(String termo) async {
    final termoLower = termo.toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('nome')
        .get();

    // 🔍 Busca flexível por nome, CPF ou telefone (com ou sem pontuação)
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

  Future<void> _registrarVenda() async {
    if (_clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um cliente antes de registrar.")),
      );
      return;
    }

    final produto = _produtoController.text.trim();
    final nota = _notaFiscalController.text.trim();
    final valor = _valorController.text.trim();

    if (produto.isEmpty || valor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o produto e o valor.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('vendas').add({
      'clienteId': _clienteSelecionadoId,
      'clienteNome': _clienteSelecionadoNome,
      'produto': produto,
      'notaFiscal': nota,
      'valor': valor,
      'data': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Venda registrada com sucesso!")),
    );

    _produtoController.clear();
    _notaFiscalController.clear();
    _valorController.clear();
    setState(() {
      _clienteSelecionadoId = null;
      _clienteSelecionadoNome = null;
    });
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
              onChanged: (valor) {
                setState(() {}); // para atualizar a lista
              },
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
                    onPressed: () {
                      setState(() {
                        _clienteSelecionadoId = null;
                        _clienteSelecionadoNome = null;
                      });
                    },
                  ),
                ),
              ),
            TextField(
              controller: _produtoController,
              decoration: const InputDecoration(labelText: "Produto"),
            ),
            TextField(
              controller: _notaFiscalController,
              decoration: const InputDecoration(labelText: "Nota Fiscal (opcional)"),
            ),
            TextField(
              controller: _valorController,
              decoration: const InputDecoration(labelText: "Valor"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
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
