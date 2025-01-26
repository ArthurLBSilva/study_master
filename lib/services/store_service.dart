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
  }) async {
    try {
      await _firestore.collection('agenda').add({
        'userId': userId,
        'data': Timestamp.fromDate(data), // Converte DateTime para Timestamp
        'disciplina': disciplina,
        'compromisso': compromisso,
        'lembrete': lembrete,
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

  Future<void> excluirItem(String idItem) async {
    try {
      await _firestore.collection('agenda').doc(idItem).delete();
      print('Item excluído com sucesso!');
    } catch (e) {
      print('Erro ao excluir item: $e');
      throw Exception('Erro ao excluir item');
    }
  }

  Future<List<String>> getDisciplinas() async {
    try {
      print('Iniciando busca de disciplinas...');
      QuerySnapshot querySnapshot =
          await _firestore.collection('disciplinas').get();
      print('Documentos encontrados: ${querySnapshot.docs.length}');

      // Mapeia os documentos para uma lista de nomes de disciplinas
      List<String> disciplinas = querySnapshot.docs
          .map((doc) {
            final data =
                doc.data() as Map<String, dynamic>?; // Dados do documento
            if (data == null || !data.containsKey('nome')) {
              print('Documento ${doc.id} não possui o campo "nome".');
              return null; // Retorna null para documentos inválidos
            }
            return data['nome'] as String; // Extrai o campo "nome"
          })
          .where((nome) => nome != null) // Filtra valores nulos
          .cast<String>() // Converte para List<String>
          .toList();

      print('Disciplinas carregadas: $disciplinas');
      return disciplinas;
    } catch (e) {
      print('Erro ao buscar disciplinas: $e');
      throw Exception('Erro ao carregar disciplinas: $e');
    }
  }

   Future<void> editarAgenda({
    required String id, // ID do documento a ser editado
    required String userId, // ID do usuário
    required DateTime data,
    required String disciplina,
    String? compromisso,
    String? lembrete,
  }) async {
    try {
      await _firestore
          .collection('agenda') // Coleção onde os agendamentos estão armazenados
          .doc(id) // Documento específico a ser editado
          .update({
        'userId': userId,
        'data': data,
        'disciplina': disciplina,
        'compromisso': compromisso,
        'lembrete': lembrete,
      });
    } catch (e) {
      print('Erro ao editar agendamento: $e');
      throw Exception('Erro ao editar agendamento');
    }
  }
}
