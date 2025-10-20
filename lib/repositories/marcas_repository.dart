import 'package:cloud_firestore/cloud_firestore.dart';

/// Repositório otimizado para leitura das marcas.
/// Usa cache local para evitar leituras repetidas do Firestore.
class MarcasRepository {
  final _firestore = FirebaseFirestore.instance;

  /// Cache interno em memória.
  static List<String>? _cache;

  /// Última hora em que o cache foi atualizado.
  static DateTime? _lastUpdate;

  /// Tempo máximo de validade do cache (em minutos).
  static const _cacheDuration = Duration(minutes: 15);

  /// Retorna todas as marcas do cache (ou busca do Firestore, se necessário).
  Future<List<String>> getAll() async {
    // Se temos cache recente, usa ele
    if (_cache != null && _lastUpdate != null) {
      final diff = DateTime.now().difference(_lastUpdate!);
      if (diff < _cacheDuration) {
        return _cache!;
      }
    }

    // Caso contrário, busca do Firestore
    final snapshot = await _firestore
        .collection('marcas')
        .orderBy('nome')
        .get(const GetOptions(source: Source.serverAndCache));

    _cache = snapshot.docs
        .map((doc) => doc['nome'].toString())
        .where((nome) => nome.isNotEmpty)
        .toList();

    _lastUpdate = DateTime.now();
    return _cache!;
  }

  /// Retorna um stream das marcas (para uso em widgets reativos).
  /// Também aproveita o cache em memória quando possível.
  Stream<List<String>> streamAll() async* {
    // Se há cache, emite primeiro
    if (_cache != null) {
      yield _cache!;
    }

    // Em seguida, emite atualizações do Firestore
    final snapshots = _firestore.collection('marcas').orderBy('nome').snapshots();
    await for (final snapshot in snapshots) {
      final marcas = snapshot.docs
          .map((doc) => doc['nome'].toString())
          .where((nome) => nome.isNotEmpty)
          .toList();
      _cache = marcas;
      _lastUpdate = DateTime.now();
      yield marcas;
    }
  }

  /// Limpa manualmente o cache.
  static void clearCache() {
    _cache = null;
    _lastUpdate = null;
  }
}
