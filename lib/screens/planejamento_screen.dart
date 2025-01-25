import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para traduzir datas
import 'package:intl/intl.dart'; // Para usar DateFormat
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
  int _currentIndex = 1; // Índice da tela atual (Planejamento)

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null); // Inicializa o formato de datas em português
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove o botão de voltar
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
        padding: const EdgeInsets.only(top: 32.0), // Espaçamento maior no topo
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now(), // Primeiro dia é o dia atual
              lastDay: DateTime.utc(2030, 12, 31), // Último dia
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!selectedDay.isBefore(DateTime.now())) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // Navega para a tela de cadastro com a data ajustada
                  Navigator.pushNamed(
                    context,
                    '/cadastro_planejamento',
                    arguments: selectedDay.subtract(Duration(days: 1)), // Ajusta a data (-1 dia)
                  );
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
                  color: const Color(0xFF2E8B57), // Verde escuro
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF2E8B57).withOpacity(0.5), // Verde claro
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red), // Cor do texto de fim de semana
                outsideDaysVisible: false, // Oculta dias de outros meses
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: const Color(0xFF2E8B57), // Verde escuro
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                titleTextStyle: TextStyle(
                  color: const Color(0xFF2E8B57), // Verde escuro
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: const Color(0xFF2E8B57)),
                rightChevronIcon: Icon(Icons.chevron_right, color: const Color(0xFF2E8B57)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: const Color(0xFF2E8B57)), // Verde escuro
                weekendStyle: TextStyle(color: Colors.red), // Vermelho para fins de semana
              ),
              locale: 'pt_BR', // Define o idioma para português
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mês',
                CalendarFormat.week: 'Semana',
              },
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) {
                  final month = DateFormat('MMM', 'pt_BR').format(day); // Mês em sigla
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
                  final weekday = DateFormat('E', 'pt_BR').format(day); // Dia da semana (1 letra)
                  return Center(
                    child: Text(
                      weekday[0], // Primeira letra do dia da semana
                      style: TextStyle(
                        color: day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
                            ? Colors.red // Fim de semana em vermelho
                            : const Color(0xFF2E8B57), // Dias úteis em verde
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Índice da tela atual
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Atualiza o índice da tela atual
          });
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home'); // Tela inicial
              break;
            case 1:
              Navigator.pushNamed(context, '/planejamento'); // Tela de planejamento
              break;
            case 2:
              // Adicione a navegação para a tela de flashcards
              break;
            case 3:
              // Adicione a navegação para a tela de Pomodoro
              break;
            case 4:
              // Adicione a navegação para a tela de Revisão
              break;
          }
        },
        backgroundColor: const Color(0xFF2E8B57),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Ícone de início
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