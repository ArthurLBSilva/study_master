import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyMaster',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFF5F5F5), // Branco gelo
        fontFamily: 'Poppins', // Fonte personalizada
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Colors.black), // Títulos em preto
          bodyMedium: TextStyle(color: Colors.black), // Texto do corpo em preto
        ),
      ),
      home: HomeScreen(),
    );
  }
}



class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice do botão selecionado na BottomNavigationBar
  final StoreService _storeService = StoreService(); 
  final AuthService _authService = AuthService(); 

  void buscarAgenda(String userId) async {
  final agenda = await _storeService.getAgenda(userId);

  if (agenda != null) {
    // Acessando as variáveis retornadas do documento
    final String titulo = agenda['titulo'] ?? 'Sem título'; // Exemplo de chave
    final String descricao = agenda['descricao'] ?? 'Sem descrição';
    final DateTime data = (agenda['data'] as Timestamp).toDate();    
    // Agora você pode usar as variáveis como quiser
    print('Título: $titulo');
    print('Descrição: $descricao');
    print('Data: $data');
  } else {
    print('Nenhuma agenda encontrada para o usuário.');
  }
}

  String buscarUsuario() {
  final idUsuario = _authService.getCurrentUser();
  return idUsuario;
  } 


  // Método para atualizar o índice selecionado
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'StudyMaster',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 218, 218, 218), // Texto do AppBar em branco
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
        backgroundColor: const Color(0xFF2E8B57), // AppBar verde escuro
        elevation: 0, // Remove sombra
      ),
      body: Container(
        color: Color.fromARGB(255, 219, 220, 219), // Fundo branco gelo
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso Diário
            Card(
              color: const Color.fromARGB(255, 41, 103, 45), // Verde médio para o aviso diário
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                        color: Colors.white, // Texto branco
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aqui vai um aviso diário personalizado. (Temporário)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70, // Texto branco claro
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Lembretes Importantes
            Text(
              'Lembretes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 25, 80, 28), // Texto verde escuro
              ),
            ),
            SizedBox(height: 10),
            Card(
              color: const Color.fromARGB(255, 44, 119, 50), // Verde mais claro para os lembretes
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revisar Matemática - Tópico X',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 254, 255, 254), 
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Revisar História - Tópico Y',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 255, 255, 255), 
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF2E8B57), // Verde mais claro (mesmo dos lembretes)
        selectedItemColor: Colors.white, // Ícone/texto selecionado branco
        unselectedItemColor: Colors.white70, // Ícone/texto não selecionado branco claro
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
