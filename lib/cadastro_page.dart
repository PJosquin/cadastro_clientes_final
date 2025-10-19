import 'package:flutter/material.dart';
import 'models/cliente.dart';
import 'repositories/clientes_repository.dart';
import 'widgets/brand_multi_select_field.dart';

class CadastroPage extends StatefulWidget {
  final Cliente? cliente;
  const CadastroPage({super.key, this.cliente});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final _cpfCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _niverCtrl = TextEditingController();
  final _produtoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  List<String> _marcas = <String>[];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _cpfCtrl.text = c.id;
      _nomeCtrl.text = c.nome;
      _emailCtrl.text = c.email ?? '';
      _telCtrl.text = c.telefone ?? '';
      _niverCtrl.text = c.nascimento ?? '';
      _produtoCtrl.text = c.produto ?? '';
      _marcas = List<String>.from(c.marcas);
      _obsCtrl.text = c.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _niverCtrl.dispose();
    _produtoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _formatarData(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    if (digits.length >= 2) {
      formatted = '${digits.substring(0, 2)}';
      if (digits.length >= 4) {
        formatted += '/${digits.substring(2, 4)}';
        if (digits.length > 4) {
          formatted += '/${digits.substring(4, digits.length.clamp(0, 8))}';
        }
      } else {
        formatted += '/${digits.substring(2)}';
      }
    } else {
      formatted = digits;
    }
    _niverCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _salvando = true);
    final repo = ClientesRepository();

    final cliente = Cliente(
      id: widget.cliente?.id ?? _cpfCtrl.text.trim(),
      nome: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telefone: _telCtrl.text.trim(),
      nascimento: _niverCtrl.text.trim(),
      produto: _produtoCtrl.text.trim(),
      marcas: _marcas,
      observacoes: _obsCtrl.text.trim(),
    );

    try {
      if (widget.cliente == null) {
        await repo.add(cliente);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente cadastrado com sucesso!')),
        );
      } else {
        await repo.update(cliente);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente atualizado com sucesso!')),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Cadastro de Cliente',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _campo(_cpfCtrl, 'CPF', TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o CPF'
                              : null),
                      _campo(_nomeCtrl, 'Nome', TextInputType.text,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome'
                              : null),
                      _campo(_emailCtrl, 'E-mail', TextInputType.emailAddress),
                      _campo(_telCtrl, 'Telefone', TextInputType.phone),
                      _campo(_niverCtrl, 'Data de Aniversário',
                          TextInputType.number,
                          onChanged: _formatarData),
                      _campo(
                          _produtoCtrl, 'Produto desejado', TextInputType.text),
                      const SizedBox(height: 8),
                      BrandMultiSelectField(
                        initialValue: _marcas,
                        validator: (list) => (list == null || list.isEmpty)
                            ? 'Selecione ao menos uma marca'
                            : null,
                        onSaved: (list) =>
                            _marcas = List<String>.from(list ?? <String>[]),
                      ),
                      const SizedBox(height: 8),
                      _campo(_obsCtrl, 'Observações', TextInputType.multiline,
                          maxLines: 3),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // Botão fixo no final da tela
            Container(
              width: double.infinity,
              color: Colors.blue.shade100,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade300,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _salvando ? null : _salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController controller, String label,
      TextInputType tipo,
      {String? Function(String?)? validator,
      void Function(String)? onChanged,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        keyboardType: tipo,
        validator: validator,
        onChanged: onChanged,
        maxLines: maxLines,
      ),
    );
  }
}
