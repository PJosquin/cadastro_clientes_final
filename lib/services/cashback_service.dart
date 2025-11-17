// lib/services/cashback_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CashbackService {
  CashbackService._internal();
  static final CashbackService instance = CashbackService._internal();

  // Percentual padrão caso não haja configuração no banco (5%)
  final double _percentualPadrao = 0.05;

  /// Lê do Firestore: collection 'config', doc 'cashback', campo 'percentual'
  /// Ex: 0.05 = 5%
  Future<double> getPercentualCashback() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('cashback')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['percentual'] is num) {
          return (data['percentual'] as num).toDouble();
        }
      }
    } catch (e) {
      // aqui você pode dar um print/log se quiser
      // print('Erro ao buscar percentual de cashback: $e');
    }

    // se deu qualquer problema, usa o padrão
    return _percentualPadrao;
  }
}
