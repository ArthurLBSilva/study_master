import 'package:flutter/material.dart';
import 'dart:async'; // Importe o Timer
import '../services/store_service.dart'; // Importe o StoreService

class CronometroScreen extends StatefulWidget {
  final String disciplina;
  final int tempoEstudo; // Em minutos
  final int tempoDescanso; // Em minutos
  final String pomodoroId;

  CronometroScreen({
    required this.disciplina,
    required this.tempoEstudo,
    required this.tempoDescanso,
    required this.pomodoroId,
  });

  @override
  _CronometroScreenState createState() => _CronometroScreenState();
}

class _CronometroScreenState extends State<CronometroScreen> {
  int _tempoRestante = 0; // Em segundos
  bool _emEstudo = true; // Indica se está no ciclo de estudo ou descanso
  bool _pausado = true; // Indica se o cronômetro está pausado
  double _tempoEstudadoTotal = 0; // Em minutos (com valor quebrado)
  bool _mostrarBotaoSalvar = false; // Controla a visibilidade do botão de salvar
  bool _tempoIniciado = false; // Indica se o cronômetro foi iniciado pelo menos uma vez
  Timer? _timer; // Timer para controlar a contagem regressiva

  @override
  void initState() {
    super.initState();
    _tempoRestante = widget.tempoEstudo * 60; // Converte minutos para segundos
  }

  void _iniciarCronometro() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_pausado && _tempoRestante > 0) {
        setState(() {
          _tempoRestante--;
          if (_emEstudo) {
            _tempoEstudadoTotal += 1 / 60; // Adiciona 1 segundo ao tempo estudado
          }
        });
      } else if (_tempoRestante == 0) {
        _alternarCiclo();
      }
    });
  }

  void _alternarCiclo() {
    setState(() {
      if (_emEstudo) {
        // Terminou o tempo de estudo, inicia o descanso
        _emEstudo = false;
        _tempoRestante = widget.tempoDescanso * 60; // Converte minutos para segundos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hora do descanso!')),
        );
      } else {
        // Terminou o tempo de descanso, volta ao estudo
        _emEstudo = true;
        _tempoRestante = widget.tempoEstudo * 60; // Converte minutos para segundos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Volte aos estudos!')),
        );
      }
    });
  }

  void _iniciarOuPausar() {
    setState(() {
      _pausado = !_pausado;
      if (!_pausado) {
        _iniciarCronometro();
        _mostrarBotaoSalvar = true; // Mostra o botão de salvar após iniciar
        _tempoIniciado = true; // Indica que o cronômetro foi iniciado
      } else {
        _timer?.cancel(); // Pausa o cronômetro
      }
    });
  }

  void _salvarTempoEstudado() async {
    try {
      final storeService = StoreService();
      await storeService.atualizarPomodoroFinal(
        pomodoroId: widget.pomodoroId,
        tempoEstudado: _tempoEstudadoTotal, // Salva em minutos (com valor quebrado)
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tempo estudado salvo com sucesso!')),
      );

      Navigator.pushNamed(context, '/pomodoro'); // Volta para a tela anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar tempo estudado: $e')),
      );
    }
  }

  String _formatarTempo(int segundos) {
    int horas = segundos ~/ 3600;
    int minutos = (segundos % 3600) ~/ 60;
    int segundosRestantes = segundos % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmarSaida() async {
    if (_tempoIniciado) {
      final confirmar = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Certeza que quer sair?'),
          content: Text('Você vai perder seu progresso. Clique em Salvar antes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sair'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        Navigator.pop(context); // Volta para a tela anterior
      }
    } else {
      Navigator.pop(context); // Volta para a tela anterior sem aviso
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela o timer ao sair da tela
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StudyMaster',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.disciplina,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E8B57),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _confirmarSaida, // Chama a função de confirmação ao clicar na seta
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cronômetro
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _emEstudo ? Colors.green : Colors.blue,
              ),
              child: Center(
                child: Text(
                  _formatarTempo(_tempoRestante),
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botão de Iniciar/Pausar (ícone)
            IconButton(
              onPressed: _iniciarOuPausar,
              iconSize: 64,
              icon: Icon(
                _pausado ? Icons.play_circle_filled : Icons.pause_circle_filled,
                color: _pausado ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            // Botão de Salvar (aparece apenas após iniciar)
            if (_mostrarBotaoSalvar)
              ElevatedButton(
                onPressed: _salvarTempoEstudado,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}