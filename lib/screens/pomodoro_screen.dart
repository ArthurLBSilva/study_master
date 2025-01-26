import 'package:flutter/material.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService
import 'package:intl/intl.dart'; // Para formatar datas

class PomodoroScreen extends StatefulWidget {
  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas
  String? _disciplinaSelecionada; // Disciplina selecionada
  List<Map<String, dynamic>> _estudosRealizados = []; // Lista de estudos realizados
  bool _isLoading = false; // Indicador de carregamento

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
                      title: Text(disciplina),
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
        title: Text(
          'StudyMaster',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 218, 218, 218),
          ),
        ),
        backgroundColor: const Color(0xFF2E8B57),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove a seta de voltar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Botão de selecionar disciplina
            InkWell(
              onTap: _mostrarListaDisciplinas,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Selecione a disciplina',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _disciplinaSelecionada ?? 'Selecione uma disciplina',
                      style: TextStyle(
                        fontSize: 16,
                        color: _disciplinaSelecionada == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Lista de estudos realizados
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
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
                              margin: EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dataSessao != null)
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(dataSessao),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
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
            // Botão de cadastrar Pomodoro
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/cadastro_pomodoro');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Cadastrar Pomodoro',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Índice da tela atual (Pomodoro)
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/planejamento');
              break;
            case 2:
              Navigator.pushNamed(context, '/flashcards');
              break;
            case 3:
              // Já está na tela de Pomodoro
              break;
            case 4:
              Navigator.pushNamed(context, '/revisao');
              break;
          }
        },
        backgroundColor: const Color(0xFF2E8B57),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
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