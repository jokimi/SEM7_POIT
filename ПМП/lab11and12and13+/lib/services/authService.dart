import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/userModel.dart';
import 'firestoreService.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Получить текущего пользователя Firebase
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Стрим изменений состояния аутентификации
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Регистрация
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        final user = User(
          id: credential.user!.uid,
          name: name,
          email: email,
          role: 0,
          createdAt: DateTime.now(),
        );

        await _firestoreService.addUser(user);
        return user;
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Вход
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _firestoreService.getUser(credential.user!.uid);
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Вход через Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        
        // Проверяем, существует ли пользователь в Firestore
        var user = await _firestoreService.getUser(firebaseUser.uid);
        
        if (user == null) {
          user = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Пользователь',
            email: firebaseUser.email ?? '',
            role: 0,
            createdAt: DateTime.now(),
          );
          await _firestoreService.addUser(user);
        }
        
        return user;
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Вход через GitHub (через OAuth)
  Future<User?> signInWithGitHub() async {
    try {
      // Для GitHub нужно настроить OAuth в Firebase Console
      // Здесь используется общий подход через OAuthProvider
      final githubProvider = firebase_auth.GithubAuthProvider();
      
      // В реальном приложении нужно настроить GitHub OAuth в Firebase Console
      // и использовать правильный провайдер
      throw UnimplementedError('GitHub sign in requires OAuth setup in Firebase Console');
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Вход через Microsoft (через OAuth)
  Future<User?> signInWithMicrosoft() async {
    try {
      // Для Microsoft нужно настроить OAuth в Firebase Console
      final microsoftProvider = firebase_auth.OAuthProvider('microsoft.com');
      
      // В реальном приложении нужно настроить Microsoft OAuth в Firebase Console
      throw UnimplementedError('Microsoft sign in requires OAuth setup in Firebase Console');
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Пароль слишком слабый';
        case 'email-already-in-use':
          return 'Этот email уже используется';
        case 'user-not-found':
          return 'Пользователь не найден';
        case 'wrong-password':
          return 'Неверный пароль';
        case 'invalid-email':
          return 'Неверный формат email';
        case 'user-disabled':
          return 'Аккаунт отключен';
        case 'too-many-requests':
          return 'Слишком много запросов. Попробуйте позже';
        default:
          return error.message ?? 'Ошибка аутентификации';
      }
    }
    return error.toString();
  }
}

