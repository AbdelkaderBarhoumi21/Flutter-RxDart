import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_rxdart/core/utils/type_def.dart';

class RegisterPage extends HookWidget {
  const RegisterPage({
    required this.goToLoginView,
    required this.register,
    super.key,
  });

  final VoidCallback goToLoginView;
  final RegisterFunction register;

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(text: 'user@gmail.com');
    final passwordController = useTextEditingController(text: '***********');

    return Scaffold(
      appBar: AppBar(title: Text('Register Page')),
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
                  register(email: email, password: password);
                },
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: goToLoginView,
                child: const Text('Already have account? Login here!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
