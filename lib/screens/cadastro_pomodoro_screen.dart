import 'package:flutter/material.dart';
import 'package:hoot/screens/cronometro_screen.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService

class CadastroPomodoroScreen extends StatefulWidget {
  @override
  _CadastroPomodoroScreenState createState() => _CadastroPomodoroScreenState();
}

class _CadastroPomodoroScreenState extends State<CadastroPomodoroScreen> {
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _tempoEstudoController = TextEditingController();
  final TextEditingController _tempoDescansoController =
      TextEditingController();

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas
  String? _disciplinaSelecionada; // Disciplina selecionada

  // Cores salvas em variáveis para fácil manutenção
  final Color _backgroundColor = Color(0xFF0d192b); // Verde azulado escuro
  final Color _primaryColor = Color(0xFF256666); // Verde
  final Color _appBarColor = Color(0xFF0C5149); // Cor da AppBar
  final Color _textColor = Colors.white; // Cor do texto

  @override
  void initState() {
    super.initState();
    // Carrega a lista de disciplinas ao iniciar a tela
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
                          _disciplinaController.text = disciplina;
                        });
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

  // Função para salvar os dados do Pomodoro
  void _salvarPomodoro() async {
    final disciplina = _disciplinaController.text.trim();
    final tempoEstudo = int.tryParse(_tempoEstudoController.text.trim()) ?? 0;
    final tempoDescanso =
        int.tryParse(_tempoDescansoController.text.trim()) ?? 0;

    // Validações
    if (disciplina.isEmpty || tempoEstudo <= 0 || tempoDescanso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
      return;
    }

    // Obtém o ID do usuário logado
    final userId = _authService.getCurrentUser();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    // Salva os dados no Firestore
    try {
      final pomodoroId = await _storeService.salvarPomodoroInicial(
        disciplina: disciplina,
        tempoEstudo: tempoEstudo,
        tempoDescanso: tempoDescanso,
        userId: userId,
      );

      // Redireciona para a tela do cronômetro, passando todos os parâmetros obrigatórios
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CronometroScreen(
            disciplina: disciplina, // Passa a disciplina
            tempoEstudo: tempoEstudo, // Passa o tempo de estudo
            tempoDescanso: tempoDescanso, // Passa o tempo de descanso
            pomodoroId: pomodoroId, // Passa o ID do Pomodoro
          ),
        ),
      );
    } catch (e) {
      // Exibe uma mensagem de erro se o salvamento falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar Pomodoro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cadastrar Pomodoro',
          style: TextStyle(
            color: _textColor, // Cor do texto em branco
          ),
        ),
        backgroundColor: _appBarColor, // Cor de fundo do AppBar
      ),
      body: Container(
        color: _backgroundColor, // Cor de fundo da tela
        height: MediaQuery.of(context).size.height, // Ocupa toda a altura da tela
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24), // Espaçamento maior entre a AppBar e o campo
              // Campo de Disciplina
              InkWell(
                onTap: _mostrarListaDisciplinas, // Abre o modal de disciplinas
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Disciplina*',
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
              SizedBox(height: 24), // Espaçamento maior entre os campos
              // Campo de Tempo de Estudo
              TextField(
                controller: _tempoEstudoController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: 'Tempo de Estudo (minutos)*',
                  labelStyle: TextStyle(color: _textColor),
                  hintText: 'Ex: 25',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24), // Espaçamento maior entre os campos
              // Campo de Tempo de Descanso
              TextField(
                controller: _tempoDescansoController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: 'Tempo de Descanso (minutos)*',
                  labelStyle: TextStyle(color: _textColor),
                  hintText: 'Ex: 5',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 32), // Espaçamento maior antes dos botões
              // Botões de Salvar e Cancelar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Volta para a tela anterior
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // Cor do botão Cancelar
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: _textColor, // Cor do texto em branco
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvarPomodoro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor, // Cor do botão Salvar
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Começar',
                        style: TextStyle(
                          color: _textColor, // Cor do texto em branco
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}