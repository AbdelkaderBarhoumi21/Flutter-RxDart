import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_rxdart/utils/type_def.dart';

class LoginPage extends HookWidget {
  const LoginPage({
    required this.goToRegisterView,
    required this.login,
    super.key,
  });

  final VoidCallback goToRegisterView;
  final LoginFunction login;

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(text: 'user@gmail.com');
    final passwordController = useTextEditingController(text: '***********');

    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            spacing: 12,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(hintText: 'Enter your email'),
                keyboardType: TextInputType.name,
                keyboardAppearance: Brightness.dark,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(hintText: 'Enter your password'),
                keyboardType: TextInputType.name,
                keyboardAppearance: Brightness.dark,
                obscureText: true,
                obscuringCharacter: '*',
              ),

              TextButton(
                onPressed: () {
                  final email = emailController.text;
                  final password = passwordController.text;
                  login(email: email, password: password);
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: goToRegisterView,
                child: const Text('Not register yet? Register here!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
