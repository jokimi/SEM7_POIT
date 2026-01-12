import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/appBLoC.dart';
import '../bloc/appEvent.dart';
import '../bloc/appState.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listener: (context, state) {
        if (state is AppError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        } else if (state is AppLoaded) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is AppLoading) {
          setState(() => _isLoading = true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Daily Reading',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5d666f),
                      fontFamily: 'Pretendard',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Войдите в аккаунт' : 'Создайте аккаунт',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF5d666f),
                      fontFamily: 'Pretendard',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (!_isLogin) ...[
                    TextFormField(
                    key: const Key('auth_name_field'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите имя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                  key: const Key('auth_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!value.contains('@')) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                  key: const Key('auth_password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен быть не менее 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                  key: const Key('auth_submit_button'),
                  onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffae1a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Войти' : 'Зарегистрироваться',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      key: const Key('auth_forgot_password_button'),
                      onPressed: _handlePasswordReset,
                      child: const Text(
                        'Забыли пароль?',
                        style: TextStyle(
                          color: Color(0xFF5d666f),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'или',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                  key: const Key('auth_google_button'),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 32),
                    label: const Text(
                      'Войти через Google',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Color(0xFF5d666f),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      TextButton(
                        key: const Key('auth_toggle_button'),
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          _isLogin ? 'Зарегистрироваться' : 'Войти',
                          style: const TextStyle(
                            color: Color(0xFFffae1a),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        context.read<AppBloc>().add(SignInRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ));
      } else {
        context.read<AppBloc>().add(SignUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim(),
            ));
      }
    }
  }

  void _handleGoogleSignIn() {
    context.read<AppBloc>().add(const SignInWithGoogleRequested());
  }

  void _handlePasswordReset() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите email для сброса пароля'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: Text(
          'Ссылка для сброса пароля будет отправлена на ${_emailController.text}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppBloc>().add(
                    PasswordResetRequested(_emailController.text.trim()),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Проверьте почту для сброса пароля'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}

