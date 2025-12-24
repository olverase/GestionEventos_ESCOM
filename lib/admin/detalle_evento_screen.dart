import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import 'crear_evento_screen.dart'; // Para poder ir a editar

class DetalleEventoScreen extends StatefulWidget {
  final Evento evento;

  const DetalleEventoScreen({super.key, required this.evento});

  @override
  State<DetalleEventoScreen> createState() => _DetalleEventoScreenState();
}

class _DetalleEventoScreenState extends State<DetalleEventoScreen> {
  // Lógica para enviar Notificación real a la BD
  void _enviarNotificacion() {
    final asistentes = widget.evento.asistentes;

    if (asistentes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay asistentes para notificar.')),
      );
      return;
    }

    final msgController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Notificar a Asistentes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Se enviará un mensaje al buzón de los alumnos inscritos.'),
              const SizedBox(height: 10),
              TextField(
                controller: msgController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ej: El evento se mueve al Salón 2',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // Cerrar diálogo
                final mensaje = msgController.text.trim();
                if (mensaje.isEmpty) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enviando notificaciones...')),
                );

                try {
                  // Escribimos en lote (Batch) para ser eficientes
                  final batch = FirebaseFirestore.instance.batch();

                  for (String alumnoId in asistentes) {
                    // Imprimimos en consola para verificar (DEBUG)
                    debugPrint("Enviando notificación a: $alumnoId");

                    final docRef = FirebaseFirestore.instance
                        .collection('notificaciones')
                        .doc();
                    batch.set(docRef, {
                      'paraUserId': alumnoId,
                      'tituloEvento': widget.evento.titulo,
                      'mensaje': mensaje,
                      'leido': false,
                      'fecha': DateTime.now().millisecondsSinceEpoch,
                    });
                  }

                  await batch.commit(); // Ejecutar todo

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '¡Mensaje enviado a ${asistentes.length} alumnos!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Evento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Botón para ir a EDITAR (RF-012)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CrearEventoScreen(evento: widget.evento),
                ),
              ).then((_) {
                // Al volver, si hubo cambios, lo ideal sería regresar
                if (mounted) Navigator.pop(context);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Resumen del Evento
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.indigo.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.evento.titulo,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                        '${widget.evento.fecha.day}/${widget.evento.fecha.month} - ${widget.evento.fecha.hour}:${widget.evento.fecha.minute.toString().padLeft(2, '0')}'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.evento.descripcion),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. Título y Botón Avisar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Asistentes (${widget.evento.asistentes.length})",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Botón Notificar (RF-014)
                ElevatedButton.icon(
                  onPressed: _enviarNotificacion,
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text("Avisar"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                )
              ],
            ),
          ),

          // 3. Lista de Asistentes con Nombres Reales (RF-013)
          Expanded(
            child: widget.evento.asistentes.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no hay alumnos inscritos.',
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.evento.asistentes.length,
                    itemBuilder: (context, index) {
                      final alumnoId = widget.evento.asistentes[index];

                      // Buscamos nombre real en Firebase
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(alumnoId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(title: Text('Cargando...'));
                          }

                          String nombre = 'Desconocido';
                          String email = alumnoId;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            nombre = data['nombre'] ?? 'Sin Nombre';
                            email = data['email'] ?? 'Sin correo';
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(nombre.isNotEmpty
                                  ? nombre[0].toUpperCase()
                                  : '?'),
                            ),
                            title: Text(nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(email),
                            trailing: const Icon(Icons.check_circle,
                                color: Colors.green),
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
