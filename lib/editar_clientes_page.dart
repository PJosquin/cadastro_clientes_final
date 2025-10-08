import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_cliente_detalhe_page.dart';

class EditarClientesPage extends StatefulWidget {
  const EditarClientesPage({Key? key}) : super(key: key);

  @override
  State<EditarClientesPage> createState() => _EditarClientesPageState();
}

class _EditarClientesPageState extends State<EditarClientesPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _resultados = [];

  Future<void> _pesquisar() async {
    String nome = _nomeController.text.trim();
    String telefone = _telefoneController.text.trim();
    String cpf = _cpfController.text.trim();
    String email = _emailController.text.trim();

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('clientes');

    // Aplica filtros cumulativos conforme preenchidos
    if (nome.isNotEmpty) {
      query = query
          .where('nome', isGreaterThanOrEqualTo: nome)
          .where('nome', isLessThanOrEqualTo: '$nome\uf8ff');
    }

    if (telefone.isNotEmpty) {
      query = query.where('telefone', isEqualTo: telefone);
    }

    if (cpf.isNotEmpty) {
      query = query.where('cpf', isEqualTo: cpf);
    }

    if (email.isNotEmpty) {
      query = query.where('email', isEqualTo: email);
    }

    final snapshot = await query.get();

    setState(() {
      _resultados = snapshot.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Clientes'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone (com DDD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cpfController,
              decoration: const InputDecoration(
                labelText: 'CPF',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Pesquisar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _pesquisar,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _resultados.isEmpty
                  ? const Center(child: Text('Nenhum cliente encontrado.'))
                  : ListView.builder(
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final cliente = _resultados[index].data();
                        final nome = cliente['nome'] ?? '';
                        final telefone = cliente['telefone'] ?? '';
                        final cpf = cliente['cpf'] ?? '';
                        final email = cliente['email'] ?? '';

                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(nome),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tel: $telefone'),
                                Text('CPF: $cpf'),
                                Text('Email: $email'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarClienteDetalhePage(
                                      clienteId: _resultados[index].id,
                                    ),
                                  ),
                                );
                              },
                            ),
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
