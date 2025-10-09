import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'cadastro_page.dart';
import 'lista_clientes.dart';
import 'filtro_page.dart';
import 'pesquisa_aniversariantes_page.dart';
import 'editar_clientes_page.dart'; // página de edição
import 'registro_venda_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Clientes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  ButtonStyle get botaoPadrao => ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro de Clientes"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: botaoPadrao,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CadastroPage()),
                  );
                },
                child: const Text("Cadastrar Cliente"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: botaoPadrao,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ListaClientesPage()),
                  );
                },
                child: const Text("Lista de Clientes"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: botaoPadrao,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FiltroPage()),
                  );
                },
                child: const Text("Pesquisar com Filtros"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: botaoPadrao,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PesquisaAniversariantesPage(),
                    ),
                  );
                },
                child: const Text("Pesquisar Aniversariantes"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: botaoPadrao,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarClientesPage(),
                    ),
                  );
                },
                child: const Text("Editar Clientes"),
              ),
		const SizedBox(height: 20),
		ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1976D2),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  icon: const Icon(Icons.point_of_sale),
  label: const Text(
    "Registrar Venda",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistroVendaPage()),
    );
  },
),
            ],
          ),
        ),
      ),
    );
  }
}
