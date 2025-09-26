import 'package:flutter/material.dart';
import 'resultado_pesquisa_page.dart';

class FiltroPage extends StatefulWidget {
  const FiltroPage({super.key});

  @override
  _FiltroPageState createState() => _FiltroPageState();
}

class _FiltroPageState extends State<FiltroPage> {
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController aniversarioController = TextEditingController();
  final TextEditingController produtoController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  final TextEditingController dataCadastroController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesquisar Clientes"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cpfController,
              decoration: const InputDecoration(labelText: "CPF"),
            ),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "E-mail"),
            ),
            TextField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: "Telefone"),
            ),
            TextField(
              controller: aniversarioController,
              decoration: const InputDecoration(labelText: "Data de Aniversário"),
            ),
            TextField(
              controller: produtoController,
              decoration: const InputDecoration(labelText: "Produto desejado"),
            ),
            TextField(
              controller: marcaController,
              decoration: const InputDecoration(labelText: "Marca"),
            ),
            TextField(
              controller: observacoesController,
              decoration: const InputDecoration(labelText: "Observações"),
            ),
            TextField(
              controller: dataCadastroController,
              decoration: const InputDecoration(labelText: "Data do Cadastro"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final filtros = {
                  'cpf': cpfController.text.trim(),
                  'nome': nomeController.text.trim(),
                  'email': emailController.text.trim(),
                  'telefone': telefoneController.text.trim(),
                  'aniversario': aniversarioController.text.trim(),
                  'produto': produtoController.text.trim(),
                  'marca': marcaController.text.trim(),
                  'observacoes': observacoesController.text.trim(),
                  'dataCadastro': dataCadastroController.text.trim(),
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ResultadoPesquisaPage(filtros: filtros),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }
}
