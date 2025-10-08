import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_cliente_detalhe_page.dart';

class EditarClientesPage extends StatefulWidget {
  const EditarClientesPage({Key? key}) : super(key: key);

  @override
  State<EditarClientesPage> createState() => _EditarClientesPageState();
}

class _EditarClientesPageState extends State<EditarClientesPage> {
  final TextEditingController _filtroController = TextEditingController();
  List<QueryDocumentSnapshot> _resultados = [];
  bool _carregando = false;

  /// Função para normalizar o texto (remove acentos, pontuação, espaços, maiúsculas)
  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // remove tudo que não é letra ou número
  }

  Future<void> _buscarClientes() async {
    setState(() => _carregando = true);

    final query = _normalizar(_filtroController.text.trim());

    if (query.isEmpty) {
      setState(() {
        _resultados = [];
        _carregando = false;
      });
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('clientes').get();

      final resultadosFiltrados = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        String nome = _normalizar(data['nome'] ?? '');
        String telefone = _normalizar(data['telefone'] ?? '');
        String cpf = _normalizar(data['cpf'] ?? '');
        String email = _normalizar(data['email'] ?? '');

        return nome.contains(query) ||
            telefone.contains(query) ||
            cpf.contains(query) ||
            email.contains(query);
      }).toList();

      setState(() {
        _resultados = resultadosFiltrados;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar clientes: $e')),
      );
    }
  }

  void _abrirEdicao(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final clienteId = doc.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarClienteDetalhePage(
          clienteId: clienteId,
          dadosCliente: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Clientes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _filtroController,
              decoration: InputDecoration(
                labelText: 'Buscar por nome, CPF, telefone ou e-mail',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarClientes,
                ),
              ),
              onSubmitted: (_) => _buscarClientes(),
            ),
            const SizedBox(height: 16),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (_resultados.isEmpty)
              const Text('Nenhum cliente encontrado.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final data = _resultados[index].data() as Map<String, dynamic>;
                    final nome = data['nome'] ?? '';
                    final telefone = data['telefone'] ?? '';
                    final email = data['email'] ?? '';
                    final cpf = data['cpf'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(nome),
                        subtitle: Text(
                          '📞 $telefone\n📧 $email\n🆔 $cpf',
                          style: const TextStyle(height: 1.4),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.edit, color: Colors.blue),
                        onTap: () => _abrirEdicao(_resultados[index]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
