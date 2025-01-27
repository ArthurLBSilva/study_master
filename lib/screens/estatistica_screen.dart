import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';

class EstatisticaScreen extends StatefulWidget {
  @override
  _EstatisticaScreenState createState() => _EstatisticaScreenState();
}

class _EstatisticaScreenState extends State<EstatisticaScreen> {
  final AuthService _authService = AuthService();
  final StoreService _storeService = StoreService();
  String _filtro = 'Dia'; // Filtro padrão: Dia
  Map<String, double> _tempoPorDisciplina = {}; // Tempo estudado por disciplina

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final userId = _authService.getCurrentUser();
    if (userId == null) return;

    DateTime dataInicio;
    DateTime dataFim = DateTime.now();

    switch (_filtro) {
      case 'Dia':
        dataInicio = DateTime(dataFim.year, dataFim.month, dataFim.day);
        break;
      case 'Semana':
        dataInicio = dataFim.subtract(Duration(days: dataFim.weekday - 1));
        break;
      case 'Mês':
        dataInicio = DateTime(dataFim.year, dataFim.month, 1);
        break;
      default:
        dataInicio = dataFim;
    }

    // Consulta simples: filtra apenas por userId
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pomodoro')
        .where('userId', isEqualTo: userId)
        .get();

    // Filtra os dados localmente por data
    _tempoPorDisciplina.clear();
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final disciplina = data['disciplina'] as String;
      final tempoEstudado =
          (data['tempoEstudado'] as num).toDouble(); // Corrigido aqui
      final dataSessao = DateTime.parse(data['dataSessao'] as String);

      // Verifica se a data está dentro do intervalo selecionado
      if (dataSessao.isAfter(dataInicio) && dataSessao.isBefore(dataFim)) {
        _tempoPorDisciplina[disciplina] =
            (_tempoPorDisciplina[disciplina] ?? 0) + tempoEstudado;
      }
    }

    setState(() {});
  }

  String _formatarTempo(double minutos) {
    final horas = (minutos / 60).floor();
    final minutosRestantes = (minutos % 60).round();
    return '${horas}h${minutosRestantes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se todos os valores são zero
    bool todosZeros = _tempoPorDisciplina.values.every((valor) => valor == 0);

    // Ordena as disciplinas por tempo estudado (do maior para o menor)
    final disciplinasOrdenadas = _tempoPorDisciplina.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Gera os dados para o gráfico de pizza
    List<PieChartSectionData> sections = [];
    if (todosZeros) {
      // Exibe uma única seção com 100% e uma mensagem
      sections.add(
        PieChartSectionData(
          color: Colors.grey, // Cor para indicar "sem dados"
          value: 100,
          title: '0%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Calcula o total do tempo estudado
      double total =
          _tempoPorDisciplina.values.fold(0, (sum, valor) => sum + valor);

      // Gera as seções para cada disciplina
      for (int i = 0; i < disciplinasOrdenadas.length; i++) {
        final entry = disciplinasOrdenadas[i];
        final double porcentagem = (entry.value / total) * 100;
        sections.add(
          PieChartSectionData(
            color: _getCorPorPosicao(i), // Define a cor com base na posição
            value: porcentagem,
            title: '${porcentagem.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'StudyMaster',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E8B57),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Espaçamento maior entre a navbar e os botões de filtro
            SizedBox(height: 20),
            // Filtros (Dia, Semana, Mês)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Dia', 'Semana', 'Mês'].map((filtro) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtro = filtro;
                    });
                    _carregarDados();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _filtro == filtro
                        ? const Color(0xFF2E8B57)
                        : Colors.grey[300],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    filtro,
                    style: TextStyle(
                      color: _filtro == filtro ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Gráfico de pizza
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Mensagem quando não há estudos
            if (todosZeros)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum estudo realizado ainda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            // Legenda (apenas se houver dados)
            if (!todosZeros)
              Expanded(
                child: ListView(
                  children: disciplinasOrdenadas.map((entry) {
                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        color: _getCorPorPosicao(
                            disciplinasOrdenadas.indexOf(entry)),
                      ),
                      title: Text(entry.key),
                      trailing: Text(_formatarTempo(entry.value)),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4, // Índice da tela de estatísticas
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/agenda');
              break;
            case 2:
              Navigator.pushNamed(context, '/flashCard');
              break;
            case 3:
              Navigator.pushNamed(context, '/pomodoro');
              break;
            case 4:
              break; // Já está na tela de estatísticas
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

  // Define a cor com base na posição da disciplina (do maior para o menor tempo estudado)
  Color _getCorPorPosicao(int posicao) {
    final cores = [
      Colors.blue, // Cor para a disciplina com mais tempo estudado
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.cyan,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    return posicao < cores.length
        ? cores[posicao]
        : Colors.grey; // Cinza para as demais
  }
}
