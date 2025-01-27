import 'package:flutter/material.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService
import 'package:intl/intl.dart'; // Para usar DateFormat

class EditarAgendaScreen extends StatefulWidget {
  final String id; // ID do agendamento a ser editado
  final DateTime data; // Data do agendamento
  final String disciplina; // Disciplina atual
  final String? compromisso; // Compromisso atual
  final String? lembrete; // Lembrete atual

  EditarAgendaScreen({
    required this.id,
    required this.data,
    required this.disciplina,
    this.compromisso,
    this.lembrete,
  });

  @override
  _EditarAgendaScreenState createState() => _EditarAgendaScreenState();
}

class _EditarAgendaScreenState extends State<EditarAgendaScreen> {
  final TextEditingController _compromissoController = TextEditingController();
  final TextEditingController _lembreteController = TextEditingController();

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas
  String? _disciplinaSelecionada; // Disciplina selecionada

  // Cores salvas em variáveis para fácil manutenção
  final Color _backgroundColor = Color(0xFF0d192b); // Verde azulado escuro
  final Color _primaryColor = Color(0xFF256666); // Verde 
  final Color _appBarColor = Color(0xFF0C5149);
  final Color _textColor = Colors.white; // Cor do texto

  @override
  void initState() {
    super.initState();
    // Preenche os campos com os valores atuais
    _disciplinaSelecionada = widget.disciplina;
    _compromissoController.text = widget.compromisso ?? '';
    _lembreteController.text = widget.lembrete ?? '';

    // Carrega a lista de disciplinas
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

  // Função para salvar as alterações
  void _editarAgendamento() async {
    final disciplina = _disciplinaSelecionada;
    final compromisso = _compromissoController.text.trim();
    final lembrete = _lembreteController.text.trim();

    // Validação 1: Disciplina é obrigatória
    if (disciplina == null || disciplina.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O campo Disciplina é obrigatório.')),
      );
      return;
    }

    // Validação 2: Pelo menos um dos campos (compromisso ou lembrete) deve ser preenchido
    if (compromisso.isEmpty && lembrete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Preencha pelo menos um campo: Compromisso Diário ou Lembrete.')),
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

    // Salva as alterações no Firestore
    try {
      await _storeService.editarAgenda(
        id: widget.id, // ID do agendamento a ser editado
        userId: userId,
        data: widget.data,
        disciplina: disciplina,
        compromisso: compromisso.isNotEmpty ? compromisso : null,
        lembrete: lembrete.isNotEmpty ? lembrete : null,
      );

      // Fecha a tela após salvar
      Navigator.pop(context);

      // Exibe uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agendamento editado com sucesso!')),
      );
    } catch (e) {
      // Exibe uma mensagem de erro se a edição falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar agendamento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Agenda',
          style: TextStyle(
            color: Colors.white, // Cor do texto em branco
          ),
        ),
        backgroundColor: _appBarColor, // Cor de fundo do AppBar
      ),
      body: Container(
        color: _backgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data selecionada
            Text(
              DateFormat('dd/MM').format(widget.data),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 16),
            // Campo de Compromisso Diário
            TextField(
              controller: _compromissoController,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                labelText: 'Compromisso Diário',
                labelStyle: TextStyle(color: _textColor),
                hintText: 'Ex: Estudar Cálculo',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Campo de Lembrete
            TextField(
              controller: _lembreteController,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                labelText: 'Lembrete',
                labelStyle: TextStyle(color: _textColor),
                hintText: 'Ex: Revisar Cálculo 1',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                ),
              ),
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
                    onPressed: _editarAgendamento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor, // Cor do botão Salvar
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Salvar',
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
    );
  }
}