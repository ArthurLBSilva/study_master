import 'package:flutter/material.dart';
import 'package:study_master/screens/cronometro_screen.dart';
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

  final StoreService _storeService =
      StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas

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

    // Validações (como antes)
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
        title: const Text(
          'Cadastrar Pomodoro',
          style: TextStyle(
            color: Colors.white, // Cor do texto em branco
          ),
        ),
        backgroundColor: const Color(0xFF2E8B57), // Cor de fundo do AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de Disciplina
            InkWell(
              onTap: _mostrarListaDisciplinas, // Abre o modal de disciplinas
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Disciplina*',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _disciplinaController.text.isEmpty
                          ? 'Selecione uma disciplina'
                          : _disciplinaController.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: _disciplinaController.text.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Campo de Tempo de Estudo
            TextField(
              controller: _tempoEstudoController,
              decoration: InputDecoration(
                labelText: 'Tempo de Estudo (minutos)*',
                hintText: 'Ex: 25',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            // Campo de Tempo de Descanso
            TextField(
              controller: _tempoDescansoController,
              decoration: InputDecoration(
                labelText: 'Tempo de Descanso (minutos)*',
                hintText: 'Ex: 5',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 32),
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
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.white, // Cor do texto em branco
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvarPomodoro,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2E8B57), // Cor do botão Salvar
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Começar',
                      style: TextStyle(
                        color: Colors.white, // Cor do texto em branco
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
