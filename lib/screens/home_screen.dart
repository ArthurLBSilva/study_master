import 'package:flutter/material.dart';
import 'package:hoot/screens/editar_agenda_screen.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar datas

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final StoreService _storeService = StoreService();
  final AuthService _authService = AuthService();

  String? idUsuario;

  // Cores salvas em variáveis para fácil manutenção
  final Color _backgroundColor = Color(0xFF0d192b); // Verde azulado escuro
  final Color _primaryColor = Color(0xFF256666); // Verde 
  final Color _appBarColor = Color(0xFF0C5149);
  final Color _avisoDiario = Color(0xFF256666);
  final Color _textColor = Colors.white; // Cor do texto

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // Busca o ID do usuário
    idUsuario = _authService.getCurrentUser();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navega para telas com base no índice
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/planejamento');
        break;
      case 2:
        Navigator.pushNamed(context, '/flashCard');
        break;
      case 3:
        Navigator.pushNamed(context, '/pomodoro');
        break;
      case 4:
        Navigator.pushNamed(context, '/estatistica');
        break;
    }
  }

  // Filtra os compromissos para o aviso diário (data igual à atual)
  Map<String, dynamic>? getAvisoDiario(
      List<Map<String, dynamic>> compromissos) {
    final hoje = DateTime.now();
    final formatador = DateFormat('yyyy-MM-dd'); // Formato da data

    for (var compromisso in compromissos) {
      final dataCompromisso = (compromisso['data'] as Timestamp).toDate();
      if (formatador.format(dataCompromisso) == formatador.format(hoje)) {
        return compromisso;
      }
    }
    return null;
  }

  // Filtra e ordena os lembretes para datas iguais ou posteriores à atual
  List<Map<String, dynamic>> getLembretesOrdenados(
      List<Map<String, dynamic>> compromissos) {
    final hoje = DateTime.now();
    final formatador = DateFormat('yyyy-MM-dd'); // Formato da data

    // Filtra os lembretes
    final lembretes = compromissos.where((compromisso) {
      final dataCompromisso = (compromisso['data'] as Timestamp).toDate();
      return formatador.format(dataCompromisso) == formatador.format(hoje) ||
          dataCompromisso.isAfter(hoje);
    }).toList();

    // Ordena os lembretes pela data (mais próximos primeiro)
    lembretes.sort((a, b) {
      final dataA = (a['data'] as Timestamp).toDate();
      final dataB = (b['data'] as Timestamp).toDate();
      return dataA.compareTo(dataB);
    });

    return lembretes;
  }

  // Função para excluir um item (lembrete ou compromisso)
  Future<void> _excluirItem(String idItem) async {
    try {
      await _storeService.excluirItem(idItem);
      print('Item excluído com sucesso!');
    } catch (e) {
      print('Erro ao excluir item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir item. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Diálogo de confirmação para exclusão
  void _confirmarExclusao(String idItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Excluir item?'),
          content: Text('Tem certeza que deseja excluir este item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fechar o diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _excluirItem(idItem); // Excluir o item
                Navigator.pop(context); // Fechar o diálogo
              },
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove o botão de voltar
        title: Row(
          children: [
            Text(
              'Hoot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.logout, color: _textColor),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        backgroundColor: _appBarColor,
        elevation: 0,
      ),
      body: Container(
        color: _backgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: idUsuario != null
              ? _storeService.getCompromissosStream(idUsuario!)
              : Stream.empty(), // Stream do Firestore
          builder: (context, snapshot) {
            if (idUsuario == null) {
              return Center(
                child: Text(
                  'Usuário não autenticado!',
                  style: TextStyle(fontSize: 16, color: _textColor),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _primaryColor));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Nenhum compromisso cadastrado!',
                  style: TextStyle(fontSize: 16, color: _textColor),
                ),
              );
            }

            // Converte os documentos em uma lista de mapas
            final compromissos = snapshot.data!.docs.map((doc) {
              return {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              };
            }).toList();

            final avisoDiario = getAvisoDiario(compromissos);
            final lembretes = getLembretesOrdenados(compromissos);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aviso Diário
                if (avisoDiario != null)
                  SizedBox(
                    width: double.infinity, // Ocupa toda a largura disponível
                    child: Card(
                      color: _avisoDiario,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Aviso Diário',
                                  style: TextStyle(
                                    fontSize: 20, // Tamanho aumentado
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: _textColor, size: 20),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditarAgendaScreen(
                                              id: avisoDiario['id'],
                                              data: (avisoDiario['data']
                                                      as Timestamp)
                                                  .toDate(),
                                              disciplina: avisoDiario[
                                                  'disciplina'],
                                              compromisso: avisoDiario[
                                                  'compromisso'],
                                              lembrete: avisoDiario['lembrete'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: _textColor, size: 20),
                                      onPressed: () {
                                        _confirmarExclusao(avisoDiario['id']);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${avisoDiario['disciplina'] ?? 'Sem disciplina'}',
                              style: TextStyle(
                                fontSize: 18, // Tamanho aumentado
                                fontWeight: FontWeight.bold, // Negrito
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${avisoDiario['compromisso'] ?? 'Sem compromisso'}',
                              style: TextStyle(
                                fontSize: 16, // Tamanho aumentado
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                // Lembretes
                Text(
                  'Lembretes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 10),
                // Lista de lembretes
                Expanded(
                  child: ListView(
                    children: lembretes.map((lembrete) {
                      final data = (lembrete['data'] as Timestamp).toDate();
                      final formatadorData = DateFormat('dd/MM'); // Formato da data

                      return Card(
                        color: _primaryColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatadorData.format(data), // Data formatada
                                    style: TextStyle(
                                      fontSize: 18, // Tamanho aumentado
                                      fontWeight: FontWeight.bold, // Negrito
                                      color: _textColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: _textColor, size: 20),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditarAgendaScreen(
                                                id: lembrete['id'],
                                                data: (lembrete['data']
                                                        as Timestamp)
                                                    .toDate(),
                                                disciplina: lembrete['disciplina'],
                                                compromisso: lembrete['compromisso'],
                                                lembrete: lembrete['lembrete'],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: _textColor, size: 20),
                                        onPressed: () {
                                          _confirmarExclusao(lembrete['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${lembrete['disciplina'] ?? 'Sem disciplina'}',
                                style: TextStyle(
                                  fontSize: 18, // Tamanho aumentado
                                  fontWeight: FontWeight.bold, // Negrito
                                  color: _textColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${lembrete['lembrete'] ?? 'Sem lembrete'}',
                                style: TextStyle(
                                  fontSize: 16, // Tamanho menor que os outros
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: _appBarColor,
        selectedItemColor: _textColor,
        unselectedItemColor: _textColor.withOpacity(0.7),
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Pomodoro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Estatística',
          ),
        ],
      ),
    );
  }
}