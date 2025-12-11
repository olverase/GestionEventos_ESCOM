import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin/mis_eventos_screen.dart'; // Importante: Aquí traemos tu pantalla

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión Eventos ESCOM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // AQUÍ ESTÁ EL CAMBIO:
      // En lugar de mostrar texto, mostramos tu formulario de crear eventos
      home: const MisEventosScreen(),
    );
  }
}
