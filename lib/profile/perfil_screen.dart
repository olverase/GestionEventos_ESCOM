import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final String miId = FirebaseAuth.instance.currentUser!.uid;

  final _nombreController = TextEditingController();
  final _interesesController = TextEditingController();

  // Opción por defecto: Código 'tech'
  String _avatarSeleccionado = 'tech';

  bool _isLoading = true;

  // LISTA DE AVATARES ACADÉMICOS
  // Cada uno tiene un código (para guardar en BD), un ícono y un color.
  final List<Map<String, dynamic>> _avataresDisponibles = [
    {
      'code': 'tech',
      'icon': Icons.computer,
      'color': Colors.indigo,
      'label': 'Dev'
    },
    {
      'code': 'science',
      'icon': Icons.science,
      'color': Colors.teal,
      'label': 'Ciencia'
    },
    {
      'code': 'hardware',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
      'label': 'Hardw'
    },
    {
      'code': 'grad',
      'icon': Icons.school,
      'color': Colors.purple,
      'label': 'Est.'
    },
    {
      'code': 'security',
      'icon': Icons.security,
      'color': Colors.redAccent,
      'label': 'Sec'
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(miId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nombreController.text = data['nombre'] ?? '';

        // Cargamos el avatar guardado, o ponemos 'tech' si no existe
        _avatarSeleccionado = data['avatar'] ?? 'tech';

        List<dynamic> intereses = data['intereses'] ?? [];
        _interesesController.text = intereses.join(', ');
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _guardarCambios() async {
    if (_nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }

    setState(() => _isLoading = true);

    List<String> listaIntereses = _interesesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await FirebaseFirestore.instance.collection('users').doc(miId).update({
        'nombre': _nombreController.text.trim(),
        'intereses': listaIntereses,
        'avatar': _avatarSeleccionado, // Guardamos el código (ej: 'tech')
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Perfil Académico Actualizado'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil Académico')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // 1. SELECCIÓN DE AVATAR (Íconos Académicos)
                  const Text('Selecciona tu especialidad:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _avataresDisponibles.map((item) {
                      final isSelected = _avatarSeleccionado == item['code'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _avatarSeleccionado = item['code']),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3), // Borde
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 3)
                                    : null,
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: item['color'],
                                child: Icon(item['icon'],
                                    color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(item['label'],
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal))
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // 2. DATOS DEL ALUMNO/PROFESOR
                  const Text('Datos Personales',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. INTERESES ACADÉMICOS
                  const Text('Áreas de Interés',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  const Text('Esto ayuda a recomendarte eventos relevantes.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _interesesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Temas de Interés (separados por coma)',
                      // AQUÍ ESTÁ EL CAMBIO DE CONTEXTO:
                      hintText:
                          'Ej: Inteligencia Artificial, Bases de Datos, Java, Matemáticas...',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. BOTÓN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('GUARDAR PERFIL'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
