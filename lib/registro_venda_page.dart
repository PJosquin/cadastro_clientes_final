import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({Key? key}) : super(key: key);

  @override
  State<RegistroVendaPage> createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final _formKey = GlobalKey<FormState>();
  final valorController = TextEditingController();
  final pecasController = TextEditingController();
  final notaController = TextEditingController();
  final observacoesController = TextEditingController();
  final buscaController = TextEditingController();

 Map<String, dynamic>? clienteSelecionado;
  List<QueryDocumentSnapshot> resultados = [];

  Future<void> _buscarClientes(String texto) async {
  if (texto.trim().isEmpty) {
    setState(() => resultados = []);
    return;
  }

  final snap = await FirebaseFirestore.instance.collection('clientes').get();
  final query = texto.toLowerCase().replaceAll(RegExp(r'[^0-9a-z@]'), '');

  setState(() {
    resultados = snap.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final nome = (data['nome'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final cpf = (data['cpf'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
      final telefone = (data['telefone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');

      // busca parcial e ignorando maiúsculas/minúsculas
      return nome.contains(query) ||
          email.contains(query) ||
          cpf.contains(query) ||
          telefone.contains(query);
    }).toList();
  });
}


  Future<void> _salvarVenda() async {
    if (clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente antes de salvar.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
      final pecas = int.tryParse(pecasController.text) ?? 0;
      final nota = notaController.text.trim();
      final obs = observacoesController.text.trim();

     await FirebaseFirestore.instance.collection('vendas').add({
  'clienteId': clienteSelecionado?['id'] ?? '',
  'nome': clienteSelecionado?['nome'] ?? '',
  'cpf': clienteSelecionado?['cpf'] ?? '',
  'telefone': clienteSelecionado?['telefone'] ?? '',
  'email': clienteSelecionado?['email'] ?? '',
  'valor': valor,
  'numero_pecas': pecas,
  'numero_nota': nota,
  'observacoes': obs,
  'data': Timestamp.now(), // ✅ Importante: grava como tipo Timestamp
});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda salva com sucesso!')),
      );

      valorController.clear();
      pecasController.clear();
      notaController.clear();
      observacoesController.clear();
      buscaController.clear();
      setState(() {
        clienteSelecionado = null;
        resultados = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venda')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Buscar Cliente:'),
              TextField(
                controller: buscaController,
                decoration: const InputDecoration(
                  hintText: 'Nome, CPF, telefone ou e-mail',
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: _buscarClientes,
              ),
              const SizedBox(height: 8),
              if (resultados.isNotEmpty)
                ...resultados.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['nome'] ?? ''),
                    subtitle: Text('${data['cpf'] ?? ''} • ${data['telefone'] ?? ''}'),
                    onTap: () {
                      setState(() {
                        clienteSelecionado = {...data, 'id': doc.id};
                        resultados = [];
                        buscaController.text = data['nome'] ?? '';
                      });
                    },
                  );
                }),
              if (clienteSelecionado != null)
                Card(
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(clienteSelecionado!['nome'] ?? ''),
                    subtitle: Text(
                        '${clienteSelecionado!['cpf']} • ${clienteSelecionado!['telefone']}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor da Venda (R\$)',
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pecasController,
                decoration: const InputDecoration(labelText: 'Número de Peças'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Informe o número de peças' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notaController,
                decoration: const InputDecoration(labelText: 'Número da Nota Fiscal'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarVenda,
                child: const Text('Salvar Venda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

