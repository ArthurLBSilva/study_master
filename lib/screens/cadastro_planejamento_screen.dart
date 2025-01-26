import 'package:flutter/material.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService
import 'package:intl/intl.dart'; // Para usar DateFormat

class CadastroPlanejamentoScreen extends StatefulWidget {
  final DateTime selectedDate; // Data selecionada no calendário

  CadastroPlanejamentoScreen({required this.selectedDate});

  @override
  _CadastroPlanejamentoScreenState createState() =>
      _CadastroPlanejamentoScreenState();
}

class _CadastroPlanejamentoScreenState
    extends State<CadastroPlanejamentoScreen> {
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _compromissoController = TextEditingController();
  final TextEditingController _lembreteController = TextEditingController();

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  // Função para salvar os dados
  void _salvarPlanejamento() async {
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

    // Salva os dados no Firestore
    try {
      await _storeService.salvarAgenda(
        userId: userId,
        data: widget.selectedDate,
        disciplina: disciplina,
        compromisso: compromisso.isNotEmpty ? compromisso : null,
        lembrete: lembrete.isNotEmpty ? lembrete : null,
      );

      // Fecha a tela após salvar
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
  }

  // Função para abrir a lista de disciplinas
  Future<void> _abrirListaDisciplinas() async {
    // Busca a lista de disciplinas do Firestore
    final disciplinas = await _storeService.getDisciplinas();

    // Ordena a lista em ordem alfabética
    disciplinas.sort();

    // Exibe a lista em um modal
    final disciplinaSelecionada = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione uma disciplina'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: disciplinas.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(disciplinas[index]),
                  onTap: () {
                    Navigator.pop(context, disciplinas[index]); // Retorna a disciplina selecionada
                  },
                );
              },
            ),
          ),
        );
      },
    );

    // Preenche o campo de disciplina com o valor selecionado
    if (disciplinaSelecionada != null) {
      setState(() {
        _disciplinaController.text = disciplinaSelecionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar à Agenda',
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
              DateFormat('dd/MM').format(widget.selectedDate),
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
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_drop_down),
                  onPressed: _abrirListaDisciplinas, // Abre a lista de disciplinas
                ),
              ),
              readOnly: true, // Impede que o usuário digite manualmente
              onTap: _abrirListaDisciplinas, // Abre a lista ao clicar no campo
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
                    onPressed: _salvarPlanejamento,
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