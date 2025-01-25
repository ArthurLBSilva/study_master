import 'package:cloud_firestore/cloud_firestore.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para salvar um compromisso/lembrete no Firestore
  Future<void> salvarAgenda({
    required String userId,
    required DateTime data,
    required String disciplina,
    String? compromisso,
    String? lembrete,
    String cor = '#FF0000', // Cor padrão (vermelho)
  }) async {
    try {
      await _firestore.collection('agenda').add({
        'userId': userId,
        'data': Timestamp.fromDate(data), // Converte DateTime para Timestamp
        'disciplina': disciplina,
        'compromisso': compromisso,
        'lembrete': lembrete,
        'cor': cor,
      });
      print('Compromisso salvo com sucesso!');
    } catch (e) {
      print('Erro ao salvar compromisso: $e');
      throw Exception('Erro ao salvar compromisso');
    }
  }

  // Função para recuperar todos os compromissos/lembretes do usuário
  Future<List<Map<String, dynamic>>> getCompromissos(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('agenda')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // ID do documento (opcional)
          'userId': data['userId'],
          'data': data['data'], // Já é um Timestamp
          'disciplina': data['disciplina'],
          'compromisso': data['compromisso'],
          'lembrete': data['lembrete'],
          'cor': data['cor'],
        };
      }).toList();
    } catch (e) {
      print('Erro ao buscar compromissos: $e');
      throw Exception('Erro ao buscar compromissos');
    }
  }

  // Função para retornar um Stream de compromissos/lembretes do usuário
  Stream<QuerySnapshot> getCompromissosStream(String userId) {
    return _firestore
        .collection('agenda')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}