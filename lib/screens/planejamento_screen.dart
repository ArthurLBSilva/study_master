import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService

class PlanejamentoScreen extends StatefulWidget {
  @override
  _PlanejamentoScreenState createState() => _PlanejamentoScreenState();
}

class _PlanejamentoScreenState extends State<PlanejamentoScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService
  

  void _mostrarModal(BuildContext context, DateTime selectedDay) {
    TextEditingController _disciplinaController = TextEditingController();
    TextEditingController _compromissoController = TextEditingController();
    TextEditingController _lembreteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Compromisso/Lembrete'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _disciplinaController,
                  decoration: InputDecoration(
                    labelText: 'Disciplina*',
                    hintText: 'Ex: Matemática',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _compromissoController,
                  decoration: InputDecoration(
                    labelText: 'Compromisso',
                    hintText: 'Ex: Estudar cálculo',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _lembreteController,
                  decoration: InputDecoration(
                    labelText: 'Lembrete',
                    hintText: 'Ex: Revisar tópico X',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o modal
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String disciplina = _disciplinaController.text;
                String compromisso = _compromissoController.text;
                String lembrete = _lembreteController.text;

                // Validação 1: Disciplina é obrigatória
                if (disciplina.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Erro'),
                        content: Text('O campo Disciplina é obrigatório.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Fecha o diálogo de erro
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  return; // Impede o salvamento se a disciplina não for preenchida
                }

                // Validação 2: Pelo menos um dos campos (compromisso ou lembrete) deve ser preenchido
                if (compromisso.isEmpty && lembrete.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Erro'),
                        content: Text('Preencha pelo menos um campo: Compromisso ou Lembrete.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Fecha o diálogo de erro
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  return; // Impede o salvamento se nenhum dos campos for preenchido
                }

                // Obtém o ID do usuário logado
                String userId = _authService.getCurrentUser();

                // Salva os dados no Firestore
                try {
                  await _storeService.salvarAgenda(
                    userId: userId,
                    data: selectedDay,
                    disciplina: disciplina,
                    compromisso: compromisso.isNotEmpty ? compromisso : null,
                    lembrete: lembrete.isNotEmpty ? lembrete : null,
                  );

                  // Fecha o modal após salvar
                  Navigator.pop(context);

                  // Exibe uma mensagem de sucesso
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Compromisso salvo com sucesso!')),
                  );
                } catch (e) {
                  // Exibe uma mensagem de erro se o salvamento falhar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar compromisso: $e')),
                  );
                }
              },
              child: Text('Salvar'),
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
        title: Text('Planejamento de Estudos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _mostrarModal(context, selectedDay); // Abre o modal ao clicar no dia
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.green[300],
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              eventLoader: (day) {
                if (day.day == 15) {
                  return [('Evento de exemplo')];
                }
                return [];
              },
            ),
          ],
        ),
      ),
    );
  }
}