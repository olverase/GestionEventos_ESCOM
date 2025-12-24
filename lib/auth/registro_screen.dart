import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/mis_eventos_screen.dart';
import '../student/home_student.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // SOLO permitimos estos dos. El Admin es VIP y se crea "por fuera".
  String _rolSeleccionado = 'Estudiante';
  final List<String> _roles = ['Estudiante', 'Organizador'];

  Future<void> _registrarse() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        // Guardamos el usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'rol': _rolSeleccionado, // Se guarda como Estudiante u Organizador
          'fecha_registro': DateTime.now().millisecondsSinceEpoch,
          'intereses': [],
          'avatar': 'A'
        });

        if (mounted) {
          // Redirección simple
          if (_rolSeleccionado == 'Organizador') {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (c) => const MisEventosScreen(esAdmin: false)));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (c) => const HomeStudentScreen()));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Correo Institucional',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Correo inválido',
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: _rolSeleccionado,
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _rolSeleccionado = v.toString()),
                decoration: const InputDecoration(
                    labelText: 'Soy...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registrarse,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                child: const Text('REGISTRARSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
