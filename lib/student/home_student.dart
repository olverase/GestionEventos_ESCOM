import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento_model.dart';
import '../auth/login_screen.dart';
import '../profile/perfil_screen.dart'; // <--- IMPORTANTE

class HomeStudentScreen extends StatefulWidget {
  const HomeStudentScreen({super.key});

  @override
  State<HomeStudentScreen> createState() => _HomeStudentScreenState();
}

class _HomeStudentScreenState extends State<HomeStudentScreen> {
  final String miId = FirebaseAuth.instance.currentUser!.uid;
  String _categoriaSeleccionada = 'Todas';
  final List<String> _categorias = [
    'Todas',
    'Académico',
    'Cultural',
    'Deportivo',
    'Otro'
  ];

  // Panel de Notificaciones
  void _mostrarNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mis Notificaciones',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notificaciones')
                      .where('paraUserId', isEqualTo: miId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return const Center(
                          child: Text('No tienes mensajes nuevos.'));
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        String hora = '';
                        if (data['fecha'] != null) {
                          final f = DateTime.fromMillisecondsSinceEpoch(
                              data['fecha']);
                          hora =
                              '${f.hour}:${f.minute.toString().padLeft(2, '0')}';
                        }
                        return Card(
                          color: Colors.yellow.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.campaign,
                                color: Colors.orange),
                            title: Text(data['tituloEvento'] ?? 'Aviso'),
                            subtitle: Text(data['mensaje'] ?? ''),
                            trailing: Text(hora,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Inscribirse
  Future<void> _toggleInscripcion(Evento evento) async {
    final estaInscrito = evento.asistentes.contains(miId);
    final docRef =
        FirebaseFirestore.instance.collection('eventos').doc(evento.id);
    try {
      if (estaInscrito) {
        await docRef.update({
          'asistentes': FieldValue.arrayRemove([miId])
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inscripción cancelada')));
      } else {
        await docRef.update({
          'asistentes': FieldValue.arrayUnion([miId])
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('¡Te has inscrito!'),
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
      appBar: AppBar(
        title: const Text('Catálogo Eventos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // BOTÓN PERFIL (RF-005)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const PerfilScreen())),
          ),
          IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => _mostrarNotificaciones(context)),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted)
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (c) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // FILTROS
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: _categorias.map((cat) {
                final isSelected = _categoriaSeleccionada == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _categoriaSeleccionada = cat),
                    selectedColor: Colors.teal.shade200,
                  ),
                );
              }).toList(),
            ),
          ),

          // LISTA DE EVENTOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('eventos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text('No hay eventos.'));

                // --- FILTRO DE SEGURIDAD: Solo mostramos los VALIDADOS ---
                var docsRaw = snapshot.data!.docs;
                List<Evento> eventos = [];
                for (var doc in docsRaw) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['validado'] == true) {
                    // Solo si es true
                    eventos.add(Evento.fromMap(data, doc.id));
                  }
                }

                if (_categoriaSeleccionada != 'Todas') {
                  eventos = eventos
                      .where((e) => e.categoria == _categoriaSeleccionada)
                      .toList();
                }

                eventos.sort((a, b) => a.fecha.compareTo(b.fecha));

                if (eventos.isEmpty)
                  return const Center(
                      child: Text('No hay eventos disponibles.'));

                return ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    final yaEstoyInscrito = evento.asistentes.contains(miId);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                    label: Text(evento.categoria),
                                    backgroundColor: Colors.teal.shade50),
                                Text(
                                    '${evento.fecha.day}/${evento.fecha.month} - ${evento.fecha.hour}:${evento.fecha.minute.toString().padLeft(2, '0')}'),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(evento.titulo,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),

                            // Mostrar nombre del Organizador
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(evento.organizadorId)
                                  .get(),
                              builder: (context, snapshot) {
                                String nombreOrg = "...";
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  nombreOrg =
                                      snapshot.data!['nombre'] ?? 'Desconocido';
                                }
                                return Text('Organizado por: $nombreOrg',
                                    style: TextStyle(
                                        color: Colors.teal.shade700,
                                        fontStyle: FontStyle.italic));
                              },
                            ),

                            const SizedBox(height: 5),
                            Text('📍 ${evento.ubicacion}',
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(evento.descripcion),
                            const Divider(),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _toggleInscripcion(evento),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: yaEstoyInscrito
                                      ? Colors.red.shade50
                                      : Colors.teal,
                                  foregroundColor: yaEstoyInscrito
                                      ? Colors.red
                                      : Colors.white,
                                  elevation: yaEstoyInscrito ? 0 : 2,
                                ),
                                icon: Icon(yaEstoyInscrito
                                    ? Icons.remove_circle_outline
                                    : Icons.check_circle_outline),
                                label: Text(yaEstoyInscrito
                                    ? 'CANCELAR INSCRIPCIÓN'
                                    : 'INSCRIBIRME'),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
