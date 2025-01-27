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
  bool _mostrarBotaoSalvar =
      false; // Controla a visibilidade do botão de salvar
  bool _tempoIniciado =
      false; // Indica se o cronômetro foi iniciado pelo menos uma vez
  Timer? _timer; // Timer para controlar a contagem regressiva

  // Cores salvas em variáveis para fácil manutenção
  final Color _backgroundColor = Color(0xFF0d192b); // Verde azulado escuro
  final Color _primaryColor = Color(0xFF256666); // Verde
  final Color _appBarColor = Color(0xFF0C5149); // Cor da AppBar
  final Color _textColor = Colors.white; // Cor do texto

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
            _tempoEstudadoTotal +=
                1 / 60; // Adiciona 1 segundo ao tempo estudado
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
        _tempoRestante =
            widget.tempoDescanso * 60; // Converte minutos para segundos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hora do descanso!')),
        );
      } else {
        // Terminou o tempo de descanso, volta ao estudo
        _emEstudo = true;
        _tempoRestante =
            widget.tempoEstudo * 60; // Converte minutos para segundos
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
        tempoEstudado:
            _tempoEstudadoTotal, // Salva em minutos (com valor quebrado)
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
          content:
              Text('Você vai perder seu progresso. Clique em Salvar antes.'),
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
        title: Text(
          'Cronômetro',
          style: TextStyle(
            color: _textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed:
              _confirmarSaida, // Chama a função de confirmação ao clicar na seta
        ),
      ),
      body: Container(
        color: _backgroundColor,
        width:
            MediaQuery.of(context).size.width, // Ocupa toda a largura da tela
        height:
            MediaQuery.of(context).size.height, // Ocupa toda a altura da tela
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.center, // Centraliza horizontalmente
          children: [
            // Nome da disciplina
            Text(
              widget.disciplina,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 20),
            // Cronômetro
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _emEstudo ? _primaryColor : Colors.blue,
                  width: 4, // Borda mais fina
                ),
              ),
              child: Center(
                child: Text(
                  _formatarTempo(_tempoRestante),
                  style: TextStyle(
                    fontSize: 32,
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botão de Iniciar/Pausar
            ElevatedButton(
              onPressed: _iniciarOuPausar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pausado
                    ? _primaryColor
                    : const Color.fromARGB(255, 169, 62, 62), // Vermelho mais claro
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _pausado ? 'Iniciar' : 'Pausar',
                style: TextStyle(
                  fontSize: 18,
                  color: _textColor,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botão de Salvar (aparece apenas após iniciar)
            if (_mostrarBotaoSalvar)
              ElevatedButton(
                onPressed: _salvarTempoEstudado,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 18,
                    color: _textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
