import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'lista_clientes.dart';

class FiltroPage extends StatefulWidget {
  const FiltroPage({super.key});

  @override
  State<FiltroPage> createState() => _FiltroPageState();
}

class _FiltroPageState extends State<FiltroPage> {
  final _cpf = TextEditingController();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _aniv = TextEditingController();
  final _produto = TextEditingController();
  final _marca = TextEditingController();
  final _obs = TextEditingController();
  final _cadastro = TextEditingController();

  final _cpfFmt = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _telFmt = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _dataFmt = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  final _mesAnoFmt = MaskTextInputFormatter(mask: '##/####', filter: {"#": RegExp(r'[0-9]')});

  /// Monta a Query conforme filtros (todos opcionais)
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('clientes');

    if (_cpf.text.trim().isNotEmpty) q = q.where('cpf', isEqualTo: _cpf.text.trim());
    if (_email.text.trim().isNotEmpty) q = q.where('email', isEqualTo: _email.text.trim());
    if (_tel.text.trim().isNotEmpty) q = q.where('telefone', isEqualTo: _tel.text.trim());
    if (_aniv.text.trim().isNotEmpty) q = q.where('aniversario', isEqualTo: _aniv.text.trim());
    if (_marca.text.trim().isNotEmpty) q = q.where('marca', isEqualTo: _marca.text.trim());
    if (_obs.text.trim().isNotEmpty) q = q.where('observacoes', isEqualTo: _obs.text.trim());

    // Busca parcial/insensível por NOME
    if (_nome.text.trim().isNotEmpty) {
      final s = _nome.text.trim().toLowerCase();
      q = q
          .where('nomeLower', isGreaterThanOrEqualTo: s)
          .where('nomeLower', isLessThan: '$s\uf8ff');
    }

    // Busca parcial/insensível por PRODUTO
    if (_produto.text.trim().isNotEmpty) {
      final p = _produto.text.trim().toLowerCase();
      q = q
          .where('produtoLower', isGreaterThanOrEqualTo: p)
          .where('produtoLower', isLessThan: '$p\uf8ff');
    }

    // Data de cadastro:
    // - dd/MM/yyyy: filtra por aquele dia (Timestamp no Firestore)
    // - MM/yyyy: filtra o mês inteiro
    final cad = _cadastro.text.trim();
    if (cad.isNotEmpty) {
      if (cad.length == 10) {
        // dd/MM/yyyy
        try {
          final d = DateFormat('dd/MM/yyyy').parseStrict(cad);
          final start = DateTime(d.year, d.month, d.day);
          final end = start.add(const Duration(days: 1));
          q = q
              .where('dataCadastro', isGreaterThanOrEqualTo: start)
              .where('dataCadastro', isLessThan: end);
        } catch (_) {}
      } else if (cad.length == 7) {
        // MM/yyyy
        try {
          final d = DateFormat('MM/yyyy').parseStrict(cad);
          final start = DateTime(d.year, d.month, 1);
          final end = DateTime(d.year, d.month + 1, 1);
          q = q
              .where('dataCadastro', isGreaterThanOrEqualTo: start)
              .where('dataCadastro', isLessThan: end);
        } catch (_) {}
      }
    }

    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesquisar Clientes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _cpf,
              decoration: const InputDecoration(labelText: 'CPF'),
              keyboardType: TextInputType.number,
              inputFormatters: [_cpfFmt],
            ),
            TextFormField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome')),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail')),
            TextFormField(
              controller: _tel,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [_telFmt],
            ),
            TextFormField(
              controller: _aniv,
              decoration: const InputDecoration(labelText: 'Data de Aniversário (dd/MM/yyyy)'),
              keyboardType: TextInputType.number,
              inputFormatters: [_dataFmt],
            ),
            TextFormField(controller: _produto, decoration: const InputDecoration(labelText: 'Produto Desejado')),
            TextFormField(controller: _marca, decoration: const InputDecoration(labelText: 'Marca')),
            TextFormField(controller: _obs, decoration: const InputDecoration(labelText: 'Observações')),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cadastro,
                    decoration: const InputDecoration(
                      labelText: 'Data de Cadastro (dd/MM/yyyy ou MM/yyyy)',
                      helperText: 'Use TAB para alternar máscara',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [_dataFmt],
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  ),
                ),
                IconButton(
                  tooltip: 'Alternar dd/MM/yyyy ⇄ MM/yyyy',
                  onPressed: () {
                    // Alterna máscara rapidamente
                    if (_cadastro.text.length <= 7) {
                      setState(() {
                        _cadastro.clear();
                        // troca o inputFormatter
                        // remove e adiciona outra máscara
                        // (o TextFormField acima já está com _dataFmt por padrão;
                        //  aqui só mostramos como alternar visualmente para o usuário)
                      });
                    }
                  },
                  icon: const Icon(Icons.swap_horiz),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final q = _buildQuery();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ListaClientesPage(query: q)),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
