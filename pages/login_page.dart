import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'admin_home.dart';
import 'student_home.dart';
import 'teacher_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AppProvider>(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 70, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Login to your account',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  TextField(
                      controller: _userCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration:
                      const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    onPressed: () {
                      final u = prov.login(
                          _userCtrl.text.trim(), _passCtrl.text);
                      if (u == null) {
                        setState(
                                () => _error = 'Invalid username or password');
                        return;
                      }
                      final dest = switch (u.role) {
                        UserRole.admin   => const AdminHome(),
                        UserRole.teacher => const TeacherHome(),
                        UserRole.student => const StudentHome(),
                      };
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => dest));
                    },
                  ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
