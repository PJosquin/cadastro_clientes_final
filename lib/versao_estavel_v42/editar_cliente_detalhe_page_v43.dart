import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarClienteDetalhePage extends StatefulWidget {
  final String clienteId;

  const EditarClienteDetalhePage({Key? key, required this.clienteId})
      : super(key: key);

  @override
  State<EditarClienteDetalhePage> createState() =>
      _EditarClienteDetalhePageState();
}

class _EditarClienteDetalhePageState extends State<EditarClienteDetalhePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _carregando = true;
  Map<String, dynamic>? _dadosOriginais;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final doc = await FirebaseFirestore.instance
        .collection('clientes')
        .doc(widget.clienteId)
        .get();

    if (doc.exists) {
      _dadosOriginais = doc.data();
      for (var entry in _dadosOriginais!.entries) {
        _controllers[entry.key] = TextEditingController(
          text: entry.value?.toString() ?? '',
        );
      }
    }

    setState(() {
      _carregando = false;
    });
  }

  Future<void> _salvarAlteracoes() async {
    if (_dadosOriginais == null) return;

    Map<String, dynamic> novosDados = {};
    for (var key in _controllers.keys) {
      novosDados[key] = _controllers[key]!.text.trim();
    }

    // preserva dataCadastro e atualiza dataEdicao
    novosDados['dataCadastro'] = _dadosOriginais!['dataCadastro'];
    novosDados['dataEdicao'] = DateTime.now().toIso8601String();

    await FirebaseFirestore.instance
        .collection('clientes')
        .doc(widget.clienteId)
        .set(novosDados, SetOptions(merge: false));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente atualizado com sucesso!')),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dadosOriginais == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Cliente'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: Text('Cliente não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._controllers.entries.map((entry) {
                final readOnly = entry.key == 'dataCadastro';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    controller: entry.value,
                    readOnly: readOnly,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                      filled: readOnly,
                      fillColor:
                          readOnly ? Colors.grey.shade200 : Colors.transparent,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _salvarAlteracoes,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
