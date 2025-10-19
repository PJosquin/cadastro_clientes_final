import 'package:cloud_firestore/cloud_firestore.dart';

class MarcasRepository {
  static final _col = FirebaseFirestore.instance.collection('marcas');

  Stream<List<String>> streamAll() {
    return _col.snapshots().map(
          (qs) => qs.docs
              .map((d) => (d.data()['nome'] as String).trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        );
  }
}
