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
            final context = state.context;
            final selected = List<String>.from(state.value ?? <String>[]);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Marcas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final result = await showModalBottomSheet<List<String>>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) =>
                          _BrandPickerSheet(initial: selected),
                    );
                    if (result != null) {
                      state.didChange(result);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selected.isEmpty
                        ? Text(
                            'Selecione uma ou mais marcas',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: -4,
                            children: selected
                                .map((m) => Chip(
                                      label: Text(m),
                                      labelStyle: const TextStyle(
                                          color: Colors.white),
                                      backgroundColor: Colors.blue.shade400,
                                      deleteIconColor: Colors.white,
                                      onDeleted: () {
                                        final newList =
                                            List<String>.from(selected)
                                              ..remove(m);
                                        state.didChange(newList);
                                      },
                                    ))
                                .toList(),
                          ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
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
                child: StreamBuilder<List<String>>(
                  stream: _repo.streamAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final todas = (snapshot.data ?? <String>[])
                        .where((m) => m
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();

                    if (todas.isEmpty) {
                      return const Center(
                          child: Text('Nenhuma marca encontrada.'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: todas.length,
                      itemBuilder: (ctx, i) {
                        final marca = todas[i];
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
