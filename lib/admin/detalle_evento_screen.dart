import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import 'crear_evento_screen.dart'; // Para poder ir a editar

class DetalleEventoScreen extends StatefulWidget {
  final Evento evento;

  const DetalleEventoScreen({super.key, required this.evento});

  @override
  State<DetalleEventoScreen> createState() => _DetalleEventoScreenState();
}

class _DetalleEventoScreenState extends State<DetalleEventoScreen> {
  // Simulamos una función de notificación (RF-014)
  void _enviarNotificacion() {
    final asistentes = widget.evento.asistentes;

    if (asistentes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay asistentes para notificar.')),
      );
      return;
    }

    // Mostrar diálogo para escribir el mensaje
    showDialog(
      context: context,
      builder: (ctx) {
        final msgController = TextEditingController();
        return AlertDialog(
          title: const Text('Notificar a Asistentes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escribe el mensaje que recibirán los alumnos:'),
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
              onPressed: () {
                // AQUÍ IRÍA LA LÓGICA DE FIREBASE CLOUD MESSAGING
                // Como es un prototipo, simulamos el éxito:
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Mensaje enviado a ${asistentes.length} personas.')),
                );
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
                // Al volver, podrías necesitar recargar, pero como usamos Stream en la lista principal,
                // lo ideal es regresar a la lista si hubo cambios drásticos.
                Navigator.pop(context);
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

          // 2. Título de la sección de asistentes
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Asistentes Registrados (${widget.evento.asistentes.length})",
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

          // 3. Lista de Asistentes (RF-013)
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
                      // Aquí deberíamos buscar el nombre del alumno en la colección 'users'
                      // Por ahora mostramos su ID
                      final alumnoId = widget.evento.asistentes[index];
                      return ListTile(
                        leading:
                            CircleAvatar(child: Text((index + 1).toString())),
                        title: Text('Alumno ID: $alumnoId'),
                        subtitle: const Text('Ingeniería en Sistemas'),
                        trailing:
                            const Icon(Icons.check_circle, color: Colors.green),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
