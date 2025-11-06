import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDeletarClientesPage extends StatefulWidget {
  const AdminDeletarClientesPage({Key? key}) : super(key: key);

  @override
  State<AdminDeletarClientesPage> createState() => _AdminDeletarClientesPageState();
}

class _AdminDeletarClientesPageState extends State<AdminDeletarClientesPage> {
  // 🔒 PIN local simples (pode mover para .env/segredo depois)
  static const String _pinCorreto = '2580';

  final TextEditingController _pinController = TextEditingController();
  bool _autorizado = false;

  final TextEditingController _buscaController = TextEditingController();
  final Set<String> _selecionados = {}; // guarda IDs selecionados
  bool _carregando = false;

  @override
  void dispose() {
    _pinController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _buscar(String termo) async {
    final snap = await FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('nome')
        .get();

    String normalize(String s) => s.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
    final t = normalize(termo.toLowerCase());

    return snap.docs.where((doc) {
      final d = doc.data();
      final nome = (d['nome'] ?? '').toString().toLowerCase();
      final cpf = (d['cpf'] ?? '').toString();
      final tel = (d['telefone'] ?? '').toString();

      final nomeOk = nome.contains(termo.toLowerCase());
      final cpfOk = normalize(cpf).contains(t);
      final telOk = normalize(tel).contains(t);
      return termo.isEmpty ? true : (nomeOk || cpfOk || telOk);
    }).toList();
  }

  Future<void> _confirmarDelecao() async {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um cliente.')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir ${_selecionados.length} cliente(s)? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _carregando = true);
    int ok = 0, fail = 0;

    for (final id in _selecionados) {
      try {
        await FirebaseFirestore.instance.collection('clientes').doc(id).delete();
        ok++;
      } catch (_) {
        fail++;
      }
    }

    setState(() {
      _selecionados.clear();
      _carregando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excluídos: $ok • Falhas: $fail')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_autorizado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin • Acesso restrito')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Digite o PIN de administrador',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _validarPin(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Entrar'),
                  onPressed: _validarPin,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Deletar Clientes'),
        actions: [
          if (_selecionados.isNotEmpty)
            IconButton(
              tooltip: 'Excluir selecionados',
              icon: const Icon(Icons.delete_forever),
              onPressed: _carregando ? null : _confirmarDelecao,
            ),
        ],
      ),
      body: Column(
        children: [
          // Busca
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: 'Buscar (nome, CPF, telefone)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: _buscar(_buscaController.text),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado.'));
                }

                final docs = snap.data!;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final d = doc.data();
                    final id = doc.id;
                    final nome = (d['nome'] ?? '').toString();
                    final cpf = (d['cpf'] ?? '').toString();
                    final tel = (d['telefone'] ?? '').toString();

                    final marcado = _selecionados.contains(id);

                    return Card(
                      child: CheckboxListTile(
                        value: marcado,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selecionados.add(id);
                            } else {
                              _selecionados.remove(id);
                            }
                          });
                        },
                        title: Text(nome),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cpf.isNotEmpty) Text('CPF: $cpf'),
                            if (tel.isNotEmpty) Text('Telefone: $tel'),
                          ],
                        ),
                        secondary: const Icon(Icons.person),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          // Botão excluir fixo no rodapé
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                label: Text(
                  _selecionados.isEmpty
                      ? 'Selecionar clientes para excluir'
                      : 'Excluir ${_selecionados.length} cliente(s)',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selecionados.isEmpty ? Colors.grey : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_selecionados.isEmpty || _carregando) ? null : _confirmarDelecao,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _validarPin() {
    if (_pinController.text.trim() == _pinCorreto) {
      setState(() => _autorizado = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN inválido')),
      );
    }
  }
}
