import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';

const users =  {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Duration get loginTime => const Duration(milliseconds: 500);

  Future<String?> _authUser(LoginData data) {
    debugPrint('Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(data.name)) {
        return 'User not exists';
      }
      if (users[data.name] != data.password) {
        return 'Password does not match';
      }
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'User not exists';
      }
      return 'Password recovery link has been sent to your email';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      theme: LoginTheme(
        pageColorLight: Colors.grey[100],
        primaryColor: Colors.lightBlueAccent

      ),
      title: 'MRI',
      onLogin: _authUser,
      onSignup: _signupUser,
      onSubmitAnimationCompleted: () {
        // Push the home route so the browser history contains the login page
        // as the previous entry (this enables the browser back button).
        Navigator.of(context).pushNamed('/home');
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}