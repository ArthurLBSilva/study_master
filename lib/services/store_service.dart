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
  Future<Map<String, dynamic>?> getAgenda(String userId) async {
  try {
    // Referência à coleção "agenda"
    final querySnapshot = await _firestore
        .collection('agenda')
        .where('userId', isEqualTo: userId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Obtem o primeiro documento encontrado
      final document = querySnapshot.docs.first;

      // Retorna os dados do documento como um mapa
      return document.data();
    } else {
      print('Nenhum compromisso encontrado para o usuário $userId.');
      return null; // Retorna null se nenhum documento for encontrado
    }
  } catch (e) {
    print('Erro ao buscar compromisso: $e');
    throw Exception('Erro ao buscar compromisso');
  }
}

}
