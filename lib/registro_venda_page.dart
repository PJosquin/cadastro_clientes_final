import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({Key? key}) : super(key: key);

  @override
  State<RegistroVendaPage> createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final buscaController = TextEditingController();
  final valorController = TextEditingController();
  final pecasController = TextEditingController();
  final notaController = TextEditingController();
  final obsController = TextEditingController();

  List<QueryDocumentSnapshot> resultados = [];
  Map<String, dynamic>? clienteSelecionado;
  bool carregando = false;

  Future<void> buscarClientes(String query) async {
    if (query.isEmpty) {
      setState(() => resultados = []);
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('clientes').get();

    final filtrados = snapshot.docs.where((doc) {
      final data = doc.data();
      final texto = query.toLowerCase();
      return (data['nome'] ?? '').toString().toLowerCase().contains(texto) ||
          (data['telefone'] ?? '').toString().toLowerCase().contains(texto) ||
          (data['cpf'] ?? '').toString().toLowerCase().contains(texto) ||
          (data['email'] ?? '').toString().toLowerCase().contains(texto);
    }).toList();

    setState(() => resultados = filtrados);
  }

  Future<void> registrarVenda() async {
    if (clienteSelecionado == null ||
        valorController.text.isEmpty ||
        pecasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha todos os campos obrigatórios.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('vendas').add({
        'clienteId': clienteSelecionado!['id'],
        'nome': clienteSelecionado!['nome'],
        'cpf': clienteSelecionado!['cpf'],
        'telefone': clienteSelecionado!['telefone'],
        'email': clienteSelecionado!['email'],
        'valor': double.tryParse(valorController.text) ?? 0,
        'numero_pecas': int.tryParse(pecasController.text) ?? 0,
        'numero_nota': notaController.text.trim(),
        'observacoes': obsController.text.trim(),
        'data': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venda registrada com sucesso!'),
        backgroundColor: Color(0xFF1976D2),
      ));

      setState(() {
        valorController.clear();
        pecasController.clear();
        notaController.clear();
        obsController.clear();
        buscaController.clear();
        clienteSelecionado = null;
        resultados.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao registrar venda: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venda')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: buscaController,
                decoration: InputDecoration(
                  labelText: 'Buscar cliente (nome, CPF, telefone, e-mail)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: buscarClientes,
              ),
              const SizedBox(height: 8),
              if (resultados.isNotEmpty)
                Card(
                  elevation: 3,
                  child: Column(
                    children: resultados.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['nome'] ?? ''),
                        subtitle: Text(
                            '${data['telefone'] ?? ''} | ${data['email'] ?? ''}'),
                        onTap: () {
                          setState(() {
                            clienteSelecionado = {...data, 'id': doc.id};
                            resultados = [];
                            buscaController.text = data['nome'] ?? '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor da Venda (R\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pecasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Peças',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notaController,
                decoration: const InputDecoration(
                  labelText: 'Número da Nota Fiscal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: obsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: registrarVenda,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Registrar Venda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

