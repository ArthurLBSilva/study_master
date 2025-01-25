import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Importe o pacote google_sign_in

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Instância do Google Sign-In

  // Função para criar um novo usuário
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Função para login com email e senha
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Função para login/cadastro com Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Inicia o fluxo de login com Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuário cancelou o login

      // Obtém os detalhes de autenticação do Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Cria uma credencial do Firebase com os dados do Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Faz login no Firebase com a credencial do Google
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      print('Erro ao fazer login com Google: $e');
      return null;
    }
  }

  // Função para redefinir a senha
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print('E-mail de recuperação enviado');
    } catch (e) {
      print('Erro ao enviar e-mail de recuperação: $e');
    }
  }

  // Função para obter o UID do usuário atual
  String getCurrentUser() {
    return _firebaseAuth.currentUser!.uid;
  }

  // Função para logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut(); // Faz logout do Google também
  }
}
