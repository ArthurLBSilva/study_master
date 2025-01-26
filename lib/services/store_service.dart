import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_master/services/auth_service.dart';
import 'dart:async';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

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
          .collection(
              'agenda') // Coleção onde os agendamentos estão armazenados
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

  Future<void> salvarFlashcard({
    required String userId,
    required String disciplina,
    required String pergunta,
    required String resposta,
  }) async {
    try {
      await _firestore.collection('flashcards').add({
        'userId': userId,
        'disciplina': disciplina,
        'pergunta': pergunta,
        'resposta': resposta,
        'dataCriacao': Timestamp.now(), // Data atual
      });
    } catch (e) {
      print('Erro ao salvar flashcard: $e');
      throw Exception('Erro ao salvar flashcard');
    }
  }

  Future<List<Map<String, dynamic>>> getFlashcardsPorDisciplina(
      String disciplina) async {
    try {
      final userId = _authService.getCurrentUser();
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      print('Buscando flashcards para a disciplina: $disciplina');

      final querySnapshot = await _firestore
          .collection('flashcards')
          .where('userId', isEqualTo: userId)
          .where('disciplina', isEqualTo: disciplina)
          .get();

      print('Flashcards encontrados: ${querySnapshot.docs.length}');

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Flashcard: $data');
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Erro ao buscar flashcards: $e');
      throw Exception('Erro ao buscar flashcards');
    }
  }

  Future<void> deletarFlashcard(String flashcardId) async {
    try {
      await _firestore.collection('flashcards').doc(flashcardId).delete();
      print('Flashcard deletado com sucesso');
    } catch (e) {
      print('Erro ao deletar flashcard: $e');
      throw Exception('Erro ao deletar flashcard');
    }
  }

  Future<String> salvarPomodoroInicial({
    required String disciplina,
    required int tempoEstudo,
    required int tempoDescanso,
    required String userId,
  }) async {
    try {
      final docRef = await _firestore.collection('pomodoro').add({
        'disciplina': disciplina,
        'tempoEstudo': tempoEstudo,
        'tempoDescanso': tempoDescanso,
        'userId': userId,
        'tempoEstudado': 0, // Inicializa com 0
        'dataSessao': DateTime.now().toIso8601String(), // Data atual
      });
      return docRef.id; // Retorna o ID do documento criado
    } catch (e) {
      print('Erro ao salvar Pomodoro inicial: $e');
      throw Exception('Erro ao salvar Pomodoro inicial');
    }
  }

  Future<void> atualizarPomodoroFinal({
    required String pomodoroId,
    required double tempoEstudado, // Alterado para double
  }) async {
    try {
      await _firestore.collection('pomodoro').doc(pomodoroId).update({
        'tempoEstudado': tempoEstudado, // Salva como double
      });
    } catch (e) {
      print('Erro ao atualizar Pomodoro: $e');
      throw Exception('Erro ao atualizar Pomodoro');
    }
  }

  Future<List<Map<String, dynamic>>> getPomodorosPorDisciplina({
    required String disciplina,
    required String userId,
  }) async {
    try {
      // Verifica se a disciplina e o userId são válidos
      if (disciplina.isEmpty || userId.isEmpty) {
        throw Exception('Disciplina ou userId inválidos');
      }

      // Realiza a consulta no Firestore (sem filtrar tempoEstudado)
      final querySnapshot = await _firestore
          .collection('pomodoro')
          .where('disciplina', isEqualTo: disciplina)
          .where('userId', isEqualTo: userId)
          .get();

      // Filtra os documentos localmente (tempoEstudado > 0)
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {}; // Evita null
        return {
          'id': doc.id,
          ...data,
        };
      }).where((data) {
        // Converte tempoEstudado para double, independentemente de ser int ou double
        final tempoEstudado = data['tempoEstudado'];
        if (tempoEstudado is int) {
          return tempoEstudado > 0;
        } else if (tempoEstudado is double) {
          return tempoEstudado > 0;
        }
        return false; // Ignora valores inválidos
      }).toList();
    } catch (e) {
      print('Erro ao buscar Pomodoros: $e');
      throw Exception('Erro ao buscar Pomodoros: $e');
    }
  }
}
