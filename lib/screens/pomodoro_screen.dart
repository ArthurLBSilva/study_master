import 'package:flutter/material.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService
import 'package:intl/intl.dart'; // Para formatar datas

class PomodoroScreen extends StatefulWidget {
  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final StoreService _storeService =
      StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas
  String? _disciplinaSelecionada; // Disciplina selecionada
  List<Map<String, dynamic>> _estudosRealizados =
      []; // Lista de estudos realizados
  bool _isLoading = false; // Indicador de carregamento

  // Cores salvas em variáveis para fácil manutenção
  final Color _backgroundColor = Color(0xFF0d192b); // Verde azulado escuro
  final Color _primaryColor = Color(0xFF256666); // Verde
  final Color _appBarColor =
      Color(0xFF0C5149); // Cor da AppBar e BottomNavigationBar
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

  // Função para buscar os estudos realizados para a disciplina selecionada
  Future<void> _buscarEstudosRealizados() async {
    if (_disciplinaSelecionada == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.getCurrentUser();
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final estudos = await _storeService.getPomodorosPorDisciplina(
        disciplina: _disciplinaSelecionada!,
        userId: userId,
      );

      setState(() {
        _estudosRealizados = estudos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar estudos: $e')),
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
                        _buscarEstudosRealizados(); // Busca os estudos realizados
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

  // Função para formatar o tempo estudado
  String _formatarTempoEstudado(dynamic tempoEstudado) {
    double tempo = 0;
    if (tempoEstudado is int) {
      tempo = tempoEstudado.toDouble();
    } else if (tempoEstudado is double) {
      tempo = tempoEstudado;
    }

    int horas = tempo ~/ 60;
    int minutos = (tempo % 60).toInt();
    if (horas > 0) {
      return '${horas}h${minutos.toString().padLeft(2, '0')}';
    } else {
      return '$minutos minuto${minutos != 1 ? 's' : ''}';
    }
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
          children: [
            // Botão de selecionar disciplina
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
            // Lista de estudos realizados
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor))
                  : _estudosRealizados.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum estudo realizado ainda!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _estudosRealizados.length,
                          itemBuilder: (context, index) {
                            final estudo = _estudosRealizados[index];
                            final dataSessao = estudo['dataSessao'] != null
                                ? DateTime.parse(estudo['dataSessao'])
                                : null;
                            final tempoEstudado = estudo['tempoEstudado'];

                            return Card(
                              color: _primaryColor,
                              margin: EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dataSessao != null)
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(dataSessao),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _textColor,
                                        ),
                                      ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tempo estudado: ${_formatarTempoEstudado(tempoEstudado)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      // Botão flutuante para cadastrar Pomodoro
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cadastro_pomodoro');
        },
        backgroundColor: _primaryColor,
        child: Icon(Icons.add, color: _textColor),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Índice da tela atual (Pomodoro)
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/planejamento');
              break;
            case 2:
              Navigator.pushNamed(context, '/flashCard');
              break;
            case 3:
              // Já está na tela de Pomodoro
              break;
            case 4:
              Navigator.pushNamed(context, '/estatistica');
              break;
          }
        },
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
