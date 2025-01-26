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
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _compromissoController = TextEditingController();
  final TextEditingController _lembreteController = TextEditingController();

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  @override
  void initState() {
    super.initState();
    // Preenche os campos com os valores atuais
    _disciplinaController.text = widget.disciplina;
    _compromissoController.text = widget.compromisso ?? '';
    _lembreteController.text = widget.lembrete ?? '';
  }

  // Função para salvar as alterações
  void _editarAgendamento() async {
    final disciplina = _disciplinaController.text.trim();
    final compromisso = _compromissoController.text.trim();
    final lembrete = _lembreteController.text.trim();

    // Validação 1: Disciplina é obrigatória
    if (disciplina.isEmpty) {
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
        backgroundColor: const Color(0xFF2E8B57), // Cor de fundo do AppBar
      ),
      body: Padding(
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
                color: const Color(0xFF2E8B57),
              ),
            ),
            SizedBox(height: 20),
            // Campo de Disciplina
            TextField(
              controller: _disciplinaController,
              decoration: InputDecoration(
                labelText: 'Disciplina*',
                hintText: 'Ex: Matemática',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Campo de Compromisso Diário
            TextField(
              controller: _compromissoController,
              decoration: InputDecoration(
                labelText: 'Compromisso Diário',
                hintText: 'Ex: Estudar Cálculo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Campo de Lembrete
            TextField(
              controller: _lembreteController,
              decoration: InputDecoration(
                labelText: 'Lembrete',
                hintText: 'Ex: Revisar Cálculo 1',
                border: OutlineInputBorder(),
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
                    onPressed: _editarAgendamento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2E8B57), // Cor do botão Salvar
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Salvar',
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