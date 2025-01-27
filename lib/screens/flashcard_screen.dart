import 'package:flutter/material.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService

class FlashcardScreen extends StatefulWidget {
  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas
  String? _disciplinaSelecionada; // Disciplina selecionada
  List<Map<String, dynamic>> _flashcards = []; // Lista de flashcards
  bool _isLoading = false; // Indicador de carregamento
  int _currentIndex = 2; // Índice da Bottom Navigation Bar (Flashcards)

  // Cores salvas em variáveis para fácil manutenção
  final Color _backgroundColor = Color(0xFF0d192b); // Verde azulado escuro
  final Color _primaryColor = Color(0xFF256666); // Verde
  final Color _appBarColor = Color(0xFF0C5149); // Cor da AppBar e BottomNavigationBar
  final Color _textColor = Colors.white; // Cor do texto

  @override
  void initState() {
    super.initState();
    _carregarDisciplinas();
  }

  // Função para carregar a lista de disciplinas
  Future<void> _carregarDisciplinas() async {
    try {
      final disciplinas = await _storeService.getDisciplinas();
      setState(() {
        _disciplinas = disciplinas;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar disciplinas: $e')),
      );
    }
  }

  // Função para carregar os flashcards da disciplina selecionada
  Future<void> _carregarFlashcards() async {
    if (_disciplinaSelecionada == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final flashcards = await _storeService.getFlashcardsPorDisciplina(_disciplinaSelecionada!);
      setState(() {
        _flashcards = flashcards;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar flashcards: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para exibir a lista de disciplinas em um modal
  void _mostrarListaDisciplinas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecione uma disciplina',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _disciplinas.length,
                  itemBuilder: (context, index) {
                    final disciplina = _disciplinas[index];
                    return ListTile(
                      title: Text(
                        disciplina,
                        style: TextStyle(color: _textColor),
                      ),
                      onTap: () {
                        setState(() {
                          _disciplinaSelecionada = disciplina;
                        });
                        _carregarFlashcards(); // Carrega os flashcards da disciplina selecionada
                        Navigator.pop(context); // Fecha o modal
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Função para exibir o modal com a pergunta e a resposta
  void _mostrarModalFlashcard(Map<String, dynamic> flashcard) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _backgroundColor,
          title: Text(
            'Pergunta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                flashcard['pergunta'],
                style: TextStyle(
                  fontSize: 18,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Resposta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 10),
              Text(
                flashcard['resposta'],
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o modal
              },
              child: Text(
                'Fechar',
                style: TextStyle(color: _primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // Função para navegar entre as telas
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/planejamento');
        break;
      case 2:
        // Já está na tela de flashcards
        break;
      case 3:
        Navigator.pushNamed(context, '/pomodoro');
        break;
      case 4:
        Navigator.pushNamed(context, '/estatistica');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            SizedBox(width: 8), // Espaço entre o texto e a imagem
            Image.asset(
              'lib/assets/icone_corujinha.jpg', // Substitua pelo caminho da sua imagem
              height: 35, // Ajuste o tamanho conforme necessário
              width: 40,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // Campo de seleção de disciplina
            InkWell(
              onTap: _mostrarListaDisciplinas,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Selecione a disciplina',
                  labelStyle: TextStyle(color: _textColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _disciplinaSelecionada ?? 'Selecione uma disciplina',
                      style: TextStyle(
                        fontSize: 16,
                        color: _disciplinaSelecionada == null
                            ? Colors.grey
                            : _textColor,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: _textColor),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Lista de flashcards
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primaryColor))
                  : _flashcards.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum flashcard cadastrado para esta disciplina.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _flashcards.length,
                          itemBuilder: (context, index) {
                            final flashcard = _flashcards[index];
                            return Card(
                              color: _primaryColor,
                              margin: EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  _mostrarModalFlashcard(flashcard); // Exibe o modal com a pergunta e resposta
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              flashcard['pergunta'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: _textColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: _textColor),
                                            onPressed: () async {
                                              // Exibe o modal de confirmação
                                              final confirmar = await showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  backgroundColor: _backgroundColor,
                                                  title: Text(
                                                    'Confirmar exclusão',
                                                    style: TextStyle(color: _textColor),
                                                  ),
                                                  content: Text(
                                                    'Tem certeza que deseja excluir este flashcard?',
                                                    style: TextStyle(color: _textColor),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context, false),
                                                      child: Text(
                                                        'Cancelar',
                                                        style: TextStyle(color: _textColor),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context, true),
                                                      child: Text(
                                                        'Excluir',
                                                        style: TextStyle(color: Colors.red),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              // Se o usuário confirmar, exclui o flashcard
                                              if (confirmar == true) {
                                                try {
                                                  await _storeService.deletarFlashcard(
                                                      flashcard['id']);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Flashcard excluído com sucesso!',
                                                        style: TextStyle(color: _textColor),
                                                      ),
                                                      backgroundColor: _primaryColor,
                                                    ),
                                                  );
                                                  // Recarrega a lista de flashcards
                                                  _carregarFlashcards();
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Erro ao excluir flashcard: $e',
                                                        style: TextStyle(color: _textColor),
                                                      ),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navega para a tela de cadastro de flashcards e aguarda o retorno
          await Navigator.pushNamed(context, '/cadastro_flashcard');
          // Recarrega os flashcards ao voltar para a tela
          _carregarFlashcards();
        },
        backgroundColor: _primaryColor,
        child: Icon(Icons.add, color: _textColor),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: _appBarColor,
        selectedItemColor: _textColor,
        unselectedItemColor: Colors.white70,
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