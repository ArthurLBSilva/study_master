import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:study_master/screens/home_screen.dart';
import 'package:study_master/screens/login_screen.dart';
import 'package:study_master/screens/planejamento_screen.dart';
import 'package:study_master/screens/sign_up_screen.dart';
import 'firebase_options.dart'; // Importando o arquivo gerado pelo Firebase CLI
import 'package:firebase_auth/firebase_auth.dart'; // Importando para autenticação
import 'screens/auth_state_widget.dart';

void main() async {
  // Garantir que os widgets sejam inicializados antes de executar o código.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando o Firebase com as opções do arquivo gerado.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Usando as configurações específicas da plataforma
  );

  // Agora, podemos rodar o aplicativo após a inicialização do Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meu App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          AuthStateWidget(), // Verifica o estado de autenticação e direciona para a tela apropriada
      routes: {
        '/login': (context) => LoginScreen(),
        '/sign-up': (context) => SignUpScreen(), // Tela de Cadastro
        '/home': (context) => HomeScreen(),
        '/planejamento': (context) => PlanejamentoScreen(),
        //  '/rotina_start': (context) => RotinaStartScreen(),
        //  '/rotina_end': (context) => RotinaEndScreen(),
      },
    );
  }
}
