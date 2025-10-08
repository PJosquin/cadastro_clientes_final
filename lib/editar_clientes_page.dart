import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_cliente_detalhe_page.dart';

class EditarClientesPage extends StatefulWidget {
  const EditarClientesPage({super.key});

  @override
  State<EditarClientesPage> createState() => _EditarClientesPageState();
}

class _EditarClientesPageState extends State<EditarClientesPage> {
  final TextEditingController _pesquisaController = TextEditingController();
  List<QueryDocumentSnapshot> _resultados = [];
  bool _carregando = false;

  Future<void> _buscarClientes() async {
    final texto = _pesquisaController.text.trim().toLowerCase();
    if (texto.isEmpty) return;

    setState(() => _carregando = true);

    final snapshot = await FirebaseFirestore.instance.collection('clientes').get();

    final filtrados = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nome = (data['nome'] ?? '').toString().toLowerCase();
      final telefone = (data['telefone'] ?? '').toString().toLowerCase();
      final cpf = (data['cpf'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();

      return nome.contains(texto) ||
          telefone.contains(texto) ||
          cpf.contains(texto) ||
          email.contains(texto);
    }).toList();

    setState(() {
      _resultados = filtrados;
      _carregando = false;
    });
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
              controller: _pesquisaController,
              decoration: InputDecoration(
                labelText: 'Pesquisar por nome, CPF, telefone ou e-mail',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarClientes,
                ),
                border: const OutlineInputBorder(),
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
                    final cliente = _resultados[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(cliente['nome'] ?? ''),
                        subtitle: Text(
                          'CPF: ${cliente['cpf'] ?? ''}\nTelefone: ${cliente['telefone'] ?? ''}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarClienteDetalhePage(
                                clienteId: _resultados[index].id,
                                dadosCliente: cliente,
                              ),
                            ),
                          );
                        },
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
