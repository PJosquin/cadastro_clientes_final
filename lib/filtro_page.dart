import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'resultado_pesquisa_page.dart';

class FiltroPage extends StatefulWidget {
  @override
  _FiltroPageState createState() => _FiltroPageState();
}

class _FiltroPageState extends State<FiltroPage> {
  final cpfController = TextEditingController();
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final aniversarioController = TextEditingController();
  final produtoController = TextEditingController();
  final marcaController = TextEditingController();
  final observacoesController = TextEditingController();
  final dataCadastroController = TextEditingController();

  // Máscaras
  final cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');
  final telefoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
  final dataMask = MaskTextInputFormatter(mask: '##/##/####');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Filtro de Clientes")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cpfController,
              inputFormatters: [cpfMask],
              decoration: InputDecoration(labelText: "CPF"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: "Nome (parcial)"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "E-mail"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: telefoneController,
              inputFormatters: [telefoneMask],
              decoration: InputDecoration(labelText: "Telefone"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: aniversarioController,
              inputFormatters: [dataMask],
              decoration: InputDecoration(labelText: "Data de Aniversário"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: produtoController,
              decoration: InputDecoration(labelText: "Produto Desejado (parcial)"),
            ),
            TextField(
              controller: marcaController,
              decoration: InputDecoration(labelText: "Marca"),
            ),
            TextField(
              controller: observacoesController,
              decoration: InputDecoration(labelText: "Observações"),
            ),
            TextField(
              controller: dataCadastroController,
              inputFormatters: [dataMask],
              decoration: InputDecoration(labelText: "Data de Cadastro"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultadoPesquisaPage(
                      cpf: cpfController.text.trim(),
                      nome: nomeController.text.trim(),
                      email: emailController.text.trim(),
                      telefone: telefoneController.text.trim(),
                      aniversario: aniversarioController.text.trim(),
                      produto: produtoController.text.trim(),
                      marca: marcaController.text.trim(),
                      observacoes: observacoesController.text.trim(),
                      dataCadastro: dataCadastroController.text.trim(),
                    ),
                  ),
                );
              },
              child: Text("Pesquisar"),
            ),
          ],
        ),
      ),
    );
  }
}
