import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';

class ClientesRepository {
  static final _col = FirebaseFirestore.instance.collection('clientes');

  Future<String> add(Cliente c) async {
    final doc = await _col.add(c.toMap());
    return doc.id;
  }

  Future<void> update(Cliente c) async {
    await _col.doc(c.id).update(c.toMap());
  }

  Stream<List<Cliente>> streamAll() {
    return _col.orderBy('nome').snapshots().map(
      (qs) => qs.docs.map((d) => Cliente.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<List<Cliente>> queryByMarca(String marca) async {
    final qs = await _col.where('marcas', arrayContains: marca).get();
    return qs.docs.map((d) => Cliente.fromMap(d.id, d.data())).toList();
  }
}
