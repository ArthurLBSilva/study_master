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

    final querySnapshot = await FirebaseFirestore.instance
        .collection('pomodoro')
        .where('userId', isEqualTo: userId)
        .where('dataSessao', isGreaterThanOrEqualTo: dataInicio.toIso8601String())
        .where('dataSessao', isLessThanOrEqualTo: dataFim.toIso8601String())
        .get();

    _tempoPorDisciplina.clear();
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final disciplina = data['disciplina'] as String;
      final tempoEstudado = data['tempoEstudado'] as double;

      _tempoPorDisciplina[disciplina] =
          (_tempoPorDisciplina[disciplina] ?? 0) + tempoEstudado;
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
      double total = _tempoPorDisciplina.values.fold(0, (sum, valor) => sum + valor);

      // Gera as seções para cada disciplina
      sections = _tempoPorDisciplina.entries.map((entry) {
        final double porcentagem = (entry.value / total) * 100;
        return PieChartSectionData(
          color: _getCorDisciplina(entry.key),
          value: porcentagem,
          title: '${porcentagem.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
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
            // Legenda (apenas se houver dados)
            if (!todosZeros)
              Expanded(
                child: ListView(
                  children: _tempoPorDisciplina.entries.map((entry) {
                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        color: _getCorDisciplina(entry.key),
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
    );
  }

  // Retorna uma cor com base na disciplina
  Color _getCorDisciplina(String disciplina) {
    // Mapeia disciplinas para cores
    final cores = {
      'Matemática': Colors.blue,
      'Física': Colors.green,
      'Química': Colors.orange,
      'História': Colors.red,
      'Geografia': Colors.purple,
      'Inglês': Colors.teal,
    };
    return cores[disciplina] ?? Colors.grey; // Retorna cinza se a disciplina não estiver mapeada
  }
}