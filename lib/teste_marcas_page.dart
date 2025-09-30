import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TesteMarcasPage extends StatefulWidget {
  const TesteMarcasPage({super.key});

  @override
  State<TesteMarcasPage> createState() => _TesteMarcasPageState();
}

class _TesteMarcasPageState extends State<TesteMarcasPage> {
  final TextEditingController marcaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste Dropdown Marcas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('marcas').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var marcas = snapshot.data!.docs
                .map((doc) => doc['nome'].toString())
                .toList();

            return DropdownButtonFormField<String>(
              value: marcaController.text.isNotEmpty ? marcaController.text : null,
              items: marcas.map((marca) {
                return DropdownMenuItem<String>(
                  value: marca,
                  child: Text(marca),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  marcaController.text = value ?? '';
                });
              },
              decoration: const InputDecoration(labelText: 'Marca'),
            );
          },
        ),
      ),
    );
  }
}
