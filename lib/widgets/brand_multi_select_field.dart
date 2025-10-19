import 'package:flutter/material.dart';
import '../repositories/marcas_repository.dart';

class BrandMultiSelectField extends FormField<List<String>> {
  BrandMultiSelectField({
    Key? key,
    List<String>? initialValue,
    FormFieldSetter<List<String>>? onSaved,
    FormFieldValidator<List<String>>? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String? hintText,
  }) : super(
          key: key,
          initialValue: initialValue ?? const <String>[],
          onSaved: onSaved,
          validator: validator,
          autovalidateMode: autovalidateMode,
          builder: (state) {
            final selected = List<String>.from(state.value ?? <String>[]);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result = await showModalBottomSheet<List<String>>(
                      context: state.context,
                      isScrollControlled: true,
                      builder: (ctx) => _BrandPickerSheet(initial: selected),
                    );
                    if (result != null) state.didChange(result);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Marcas',
                      hintText: hintText ?? 'Selecione uma ou mais marcas',
                      border: const OutlineInputBorder(),
                      errorText: state.errorText,
                    ),
                    isEmpty: selected.isEmpty,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: -8,
                      children: selected.isEmpty
                          ? [
                              Text(
                                hintText ?? 'Nenhuma marca selecionada',
                                style: TextStyle(
                                  color: Theme.of(state.context).hintColor,
                                ),
                              ),
                            ]
                          : selected
                              .map((m) => Chip(
                                    label: Text(m),
                                    onDeleted: () {
                                      final newList =
                                          List<String>.from(selected)..remove(m);
                                      state.didChange(newList);
                                    },
                                  ))
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        );
}

class _BrandPickerSheet extends StatefulWidget {
  final List<String> initial;
  const _BrandPickerSheet({super.key, required this.initial});

  @override
  State<_BrandPickerSheet> createState() => _BrandPickerSheetState();
}

class _BrandPickerSheetState extends State<_BrandPickerSheet> {
  final _repo = MarcasRepository();
  late List<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (ctx, ctrl) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar marca…',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (t) => setState(() => _query = t),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _repo.streamAll(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = (snap.data ?? <String>[])
                        .where((m) =>
                            m.toLowerCase().contains(_query.toLowerCase()))
                        .toList();
                    if (all.isEmpty) {
                      return const Center(
                          child: Text('Nenhuma marca encontrada'));
                    }
                    return ListView.builder(
                      controller: ctrl,
                      itemCount: all.length,
                      itemBuilder: (ctx, i) {
                        final marca = all[i];
                        final checked = _selected.contains(marca);
                        return CheckboxListTile(
                          title: Text(marca),
                          value: checked,
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
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                        label: const Text('Aplicar'),
                        onPressed: () => Navigator.pop(
                            context, _selected.toSet().toList()),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
