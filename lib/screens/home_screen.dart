import 'package:flutter/material.dart';
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
        Navigator.pushNamed(context, '/planejamento');
        break;
      case 1:
        // Adicione a navegação para a tela de flashcards
        break;
      case 2:
        // Adicione a navegação para a tela de Pomodoro
        break;
      case 3:
        // Adicione a navegação para a tela de Revisão
        break;
    }
  }

  // Filtra os compromissos para o aviso diário (data igual à atual)
  Map<String, dynamic>? getAvisoDiario(List<Map<String, dynamic>> compromissos) {
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
  List<Map<String, dynamic>> getLembretesOrdenados(List<Map<String, dynamic>> compromissos) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove o botão de voltar
        title: Row(
          children: [
            Text(
              'StudyMaster',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 218, 218, 218),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E8B57),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: idUsuario != null
            ? _storeService.getCompromissosStream(idUsuario!)
            : Stream.empty(), // Stream do Firestore
        builder: (context, snapshot) {
          if (idUsuario == null) {
            return Center(
              child: Text(
                'Usuário não autenticado!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Nenhum compromisso cadastrado!',
                style: TextStyle(fontSize: 16),
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

          return Container(
            color: Color.fromARGB(255, 219, 220, 219),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aviso Diário
                SizedBox(
                  width: double.infinity, // Ocupa toda a largura disponível
                  child: Card(
                    color: const Color.fromARGB(255, 41, 103, 45),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8), // Margem igual aos lembretes
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aviso Diário',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          avisoDiario != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${avisoDiario['disciplina'] ?? 'Sem disciplina'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${avisoDiario['compromisso'] ?? 'Sem compromisso'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Nenhum diário para hoje!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
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
                    color: const Color.fromARGB(255, 25, 80, 28),
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
                        color: const Color.fromARGB(255, 44, 119, 50),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8), // Margem igual ao aviso diário
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatadorData.format(data), // Data formatada
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 254, 255, 254),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${lembrete['disciplina'] ?? 'Sem disciplina'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color.fromARGB(255, 254, 255, 254),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${lembrete['lembrete'] ?? 'Sem lembrete'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 255, 255, 255),
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
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF2E8B57),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planejamento',
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
            icon: Icon(Icons.refresh),
            label: 'Revisão',
          ),
        ],
      ),
    );
  }
}