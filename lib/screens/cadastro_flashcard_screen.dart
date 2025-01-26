import 'package:flutter/material.dart';
import '../services/store_service.dart'; // Importe o StoreService
import '../services/auth_service.dart'; // Importe o AuthService

class CadastroFlashcardScreen extends StatefulWidget {
  @override
  _CadastroFlashcardScreenState createState() => _CadastroFlashcardScreenState();
}

class _CadastroFlashcardScreenState extends State<CadastroFlashcardScreen> {
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _perguntaController = TextEditingController();
  final TextEditingController _respostaController = TextEditingController();

  final StoreService _storeService = StoreService(); // Instância do StoreService
  final AuthService _authService = AuthService(); // Instância do AuthService

  List<String> _disciplinas = []; // Lista de disciplinas

  @override
  void initState() {
    super.initState();
    // Carrega a lista de disciplinas ao iniciar a tela
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
                      title: Text(disciplina),
                      onTap: () {
                        setState(() {
                          _disciplinaController.text = disciplina;
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

  // Função para salvar o flashcard
  void _salvarFlashcard() async {
    final disciplina = _disciplinaController.text.trim();
    final pergunta = _perguntaController.text.trim();
    final resposta = _respostaController.text.trim();

    // Validação 1: Disciplina é obrigatória
    if (disciplina.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O campo Disciplina é obrigatório.')),
      );
      return;
    }

    // Validação 2: Pergunta é obrigatória
    if (pergunta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O campo Pergunta é obrigatório.')),
      );
      return;
    }

    // Validação 3: Resposta é obrigatória
    if (resposta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O campo Resposta é obrigatório.')),
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

    // Salva o flashcard no Firestore
    try {
      await _storeService.salvarFlashcard(
        userId: userId,
        disciplina: disciplina,
        pergunta: pergunta,
        resposta: resposta,
      );

      // Fecha a tela após salvar
      Navigator.pop(context);

      // Exibe uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flashcard salvo com sucesso!')),
      );
    } catch (e) {
      // Exibe uma mensagem de erro se o salvamento falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar flashcard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar Flashcard',
          style: TextStyle(
            color: Colors.white, // Cor do texto em branco
          ),
        ),
        backgroundColor: const Color(0xFF2E8B57), // Cor de fundo do AppBar
      ),
      body: SingleChildScrollView(
        // Permite rolar a tela
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24), // Espaçamento maior entre a AppBar e o campo
            // Campo de Disciplina
            InkWell(
              onTap: _mostrarListaDisciplinas, // Abre o modal de disciplinas
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Disciplina*',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _disciplinaController.text.isEmpty
                          ? 'Selecione uma disciplina'
                          : _disciplinaController.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: _disciplinaController.text.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24), // Espaçamento maior entre os campos
            // Campo de Pergunta
            TextField(
              controller: _perguntaController,
              decoration: InputDecoration(
                labelText: 'Pergunta*',
                hintText: 'Ex: Qual é a capital da França?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24), // Espaçamento maior entre os campos
            // Campo de Resposta (maior)
            Container(
              height: 150, // Altura maior para o campo de resposta
              child: TextField(
                controller: _respostaController,
                maxLines: null, // Permite múltiplas linhas
                expands: true, // Expande para ocupar o espaço disponível
                decoration: InputDecoration(
                  labelText: 'Resposta*',
                  hintText: 'Ex: Paris',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true, // Alinha o label com o texto
                ),
              ),
            ),
            SizedBox(height: 32), // Espaçamento maior antes dos botões
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
                    onPressed: _salvarFlashcard,
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