import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registro_screen.dart';
import '../admin/mis_eventos_screen.dart';
import '../student/home_student.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Pre-llenado para facilitar pruebas (puedes borrar el texto si quieres)
  final _emailController = TextEditingController(text: 'admin@escom.mx');
  final _passController = TextEditingController(text: '123456');
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      // 1. Autenticación en Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      // 2. Buscar qué rol tiene este usuario en Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final rol = userDoc.data()?['rol'] ?? 'Estudiante';

          // --- AQUÍ ESTÁ LA LÓGICA DE ROLES (RF-004 y Público Objetivo) ---
          if (rol == 'Administrador') {
            // Admin: Entra en modo Supervisión (Ve todo, no crea)
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (c) => const MisEventosScreen(esAdmin: true)));
          } else if (rol == 'Organizador') {
            // Organizador: Entra en modo Gestión (Solo ve lo suyo y crea)
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (c) => const MisEventosScreen(esAdmin: false)));
          } else {
            // Estudiante: Va al catálogo
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (c) => const HomeStudentScreen()));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Usuario sin datos en BD')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  // RF-003: Recuperar Contraseña
  Future<void> _recuperarPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe tu correo primero')));
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Se envió un enlace a tu correo'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Gestión Eventos ESCOM',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),

            // Botón de recuperar contraseña (RF-003)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _recuperarPassword,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _login, child: const Text('INICIAR SESIÓN')),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => const RegistroScreen()));
                    },
                    child: const Text('¿No tienes cuenta? Regístrate aquí'),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
