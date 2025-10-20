import 'package:flutter/material.dart';
import '../repositories/marcas_repository.dart';

class BrandMultiSelectField extends FormField<List<String>> {
  BrandMultiSelectField({
    Key? key,
    List<String>? initialValue,
    FormFieldSetter<List<String>>? onSaved,
    FormFieldValidator<List<String>>? validator,
  }) : super(
          key: key,
          initialValue: initialValue ?? const <String>[],
          onSaved: onSaved,
          validator: validator,
          builder: (state) {
            final selected = List<String>.from(state.value ?? <String>[]);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final result = await showModalBottomSheet<List<String>>(
                  context: state.context,
                  isScrollControlled: true,
                  builder: (ctx) =>
                      _BrandPickerSheet(initial: selected),
                );
                if (result != null) {
                  state.didChange(result);
                }
              },
              child: InputDecorator(
                isEmpty: selected.isEmpty,
                decoration: InputDecoration(
  border: const OutlineInputBorder(),
  errorText: state.errorText,
  contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
),

                child: selected.isEmpty
                    ? Text(
                        'Selecione uma ou mais marcas',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: -4,
                        children: selected
                            .map(
                              (m) => Chip(
                                label: Text(
                                  m,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.blue.shade400,
                                deleteIconColor: Colors.white,
                                onDeleted: () {
                                  final newList =
                                      List<String>.from(selected)..remove(m);
                                  state.didChange(newList);
                                },
                              ),
                            )
                            .toList(),
                      ),
              ),
            );
          },
        );
}

/// ------------------------------------------------------------
///  Modal de seleção otimizado com cache local
/// ------------------------------------------------------------
class _BrandPickerSheet extends StatefulWidget {
  final List<String> initial;
  const _BrandPickerSheet({super.key, required this.initial});

  @override
  State<_BrandPickerSheet> createState() => _BrandPickerSheetState();
}

class _BrandPickerSheetState extends State<_BrandPickerSheet> {
  final _repo = MarcasRepository();
  late List<String> _selected;
  List<String> _todasMarcas = [];
  String _query = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initial);
    _carregarMarcas();
  }

  Future<void> _carregarMarcas() async {
    try {
      final marcas = await _repo.getAll(); // usa cache local
      setState(() {
        _todasMarcas = marcas;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar marcas: $e');
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marcasFiltradas = _todasMarcas
        .where((m) => m.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (ctx, scrollController) => Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar marca...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (t) => setState(() => _query = t),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : marcasFiltradas.isEmpty
                        ? const Center(
                            child: Text('Nenhuma marca encontrada.'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: marcasFiltradas.length,
                            itemBuilder: (ctx, i) {
                              final marca = marcasFiltradas[i];
                              final selecionada = _selected.contains(marca);
                              return CheckboxListTile(
                                value: selecionada,
                                title: Text(marca),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(marca);
                                    } else {
                                      _selected.remove(marca);
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context, widget.initial),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar'),
                        onPressed: () =>
                            Navigator.pop(context, _selected.toList()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
