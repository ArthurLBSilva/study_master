import 'package:flutter/material.dart';
import 'package:study_master/screens/editar_agenda_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class PlanejamentoScreen extends StatefulWidget {
  @override
  _PlanejamentoScreenState createState() => _PlanejamentoScreenState();
}

class _PlanejamentoScreenState extends State<PlanejamentoScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _currentIndex = 1;
  DateTime? _lastTap;
  final AuthService _authService = AuthService();
  Map<DateTime, bool> _agendamentos = {}; // Armazena apenas se há agendamento

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    final userId = _authService.getCurrentUser();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      _agendamentos.clear();
      for (var doc in querySnapshot.docs) {
        final data = (doc['data'] as Timestamp).toDate(); // Usa a data local
        final dataSemHora =
            DateTime(data.year, data.month, data.day); // Remove a hora
        _agendamentos[dataSemHora] =
            true; // Armazena apenas a data (não precisa da cor)
      }
    });
  }

  Future<bool> _existeRegistro(DateTime dataLocal) async {
    final userId = _authService.getCurrentUser();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .where('userId', isEqualTo: userId)
        .where('data',
            isEqualTo: Timestamp.fromDate(dataLocal)) // Usa a data local
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  void _abrirModalAgendamento(BuildContext context, DateTime data) async {
    final userId = _authService.getCurrentUser();

    // Busca os agendamentos para a data selecionada
    final querySnapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .where('userId', isEqualTo: userId)
        .where('data', isEqualTo: Timestamp.fromDate(data))
        .get();

    // Verifica se há agendamentos
    if (querySnapshot.docs.isNotEmpty) {
      final agendamento = querySnapshot.docs.first.data();
      final idAgendamento = querySnapshot.docs.first.id; // ID do agendamento

      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Data e dia da semana
                Text(
                  '${DateFormat('dd').format(data)} ${DateFormat('EEEE', 'pt_BR').format(data)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Card com as informações
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Disciplina
                        Text(
                          agendamento['disciplina'] ?? 'Sem disciplina',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Lembrete
                        if (agendamento['lembrete'] != null)
                          Text(
                            'Lembrete: ${agendamento['lembrete']}',
                            style: TextStyle(fontSize: 14),
                          ),

                        // Compromisso
                        if (agendamento['compromisso'] != null)
                          Text(
                            'Compromisso: ${agendamento['compromisso']}',
                            style: TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Botões de ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão de adicionar
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        Navigator.pop(context); // Fecha o modal
                        Navigator.pushNamed(
                          context,
                          '/cadastro_planejamento',
                          arguments: data,
                        );
                      },
                    ),

                    // Botão de editar
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context); // Fecha o modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarAgendaScreen(
                              id: idAgendamento, // ID do agendamento
                              data: (agendamento['data'] as Timestamp)
                                  .toDate(), // Data do agendamento
                              disciplina: agendamento[
                                  'disciplina'], // Disciplina atual
                              compromisso: agendamento[
                                  'compromisso'], // Compromisso atual
                              lembrete: agendamento['lembrete'], // Lembrete atual
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _onDayDoubleTapped(DateTime selectedDay) async {
    // Usa a data local diretamente
    final dataLocal =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    // Verifica se já existe um registro para a data
    final existeRegistro = await _existeRegistro(dataLocal);

    if (existeRegistro) {
      _abrirModalAgendamento(context, dataLocal); // Abre o modal
    } else {
      Navigator.pushNamed(
        context,
        '/cadastro_planejamento',
        arguments: dataLocal,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now().toLocal();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
      body: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: today,
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!selectedDay.isBefore(today) ||
                    isSameDay(selectedDay, today)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  final now = DateTime.now();
                  if (_lastTap != null &&
                      now.difference(_lastTap!) < Duration(milliseconds: 300)) {
                    _onDayDoubleTapped(selectedDay);
                  }
                  _lastTap = now;
                }
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
                  color: const Color(0xFF2E8B57),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF2E8B57).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: const Color(0xFF2E8B57),
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                titleTextStyle: TextStyle(
                  color: const Color(0xFF2E8B57),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: const Color(0xFF2E8B57)),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: const Color(0xFF2E8B57)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: const Color(0xFF2E8B57)),
                weekendStyle: TextStyle(color: Colors.red),
              ),
              locale: 'pt_BR',
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mês',
                CalendarFormat.week: 'Semana',
              },
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) {
                  final month =
                      DateFormat('MMM', 'pt_BR').format(day); // Mês em sigla
                  final year = DateFormat('y').format(day); // Ano
                  return Text(
                    '${month.toUpperCase()} $year', // Ex: JAN 2025
                    style: TextStyle(
                      color: const Color(0xFF2E8B57),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
                dowBuilder: (context, day) {
                  final weekday = DateFormat('E', 'pt_BR')
                      .format(day); // Dia da semana (1 letra)
                  return Center(
                    child: Text(
                      weekday[0]
                          .toUpperCase(), // Primeira letra do dia da semana em maiúscula
                      style: TextStyle(
                        color: day.weekday == DateTime.saturday ||
                                day.weekday == DateTime.sunday
                            ? Colors.red // Fim de semana em vermelho
                            : const Color(0xFF2E8B57), // Dias úteis em verde
                      ),
                    ),
                  );
                },
                markerBuilder: (context, date, events) {
                  final dataLocal = DateTime(
                      date.year, date.month, date.day); // Usa a data local
                  if (_agendamentos.containsKey(dataLocal)) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green, // Cor fixa (verde)
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
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
              // Navegação para flashcards
              break;
            case 3:
              // Navegação para Pomodoro
              break;
            case 4:
              // Navegação para Revisão
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