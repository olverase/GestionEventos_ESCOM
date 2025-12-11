import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import 'crear_evento_screen.dart'; // Para navegar al formulario
import 'detalle_evento_screen.dart';

class MisEventosScreen extends StatelessWidget {
  const MisEventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Eventos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // BOTÓN FLOTANTE PARA CREAR NUEVOS
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Navegar a la pantalla de crear
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearEventoScreen()),
          );
        },
      ),
      // CUERPO: LISTA DE EVENTOS
      body: StreamBuilder<QuerySnapshot>(
        // 1. Escuchamos la colección de eventos
        // Filtrando solo los creados por "mi usuario" (el ID temporal)
        stream: FirebaseFirestore.instance
            .collection('eventos')
            .where('organizadorId', isEqualTo: 'ID_TEMPORAL_DEL_ORGANIZADOR')
            .snapshots(),
        builder: (context, snapshot) {
          // Caso A: Esperando datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Caso B: Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Caso C: No hay eventos
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No has creado eventos aún. \n¡Usa el botón +!',
                  textAlign: TextAlign.center),
            );
          }

          // Caso D: Mostrar la lista
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Convertimos el documento de Firebase a tu objeto Evento
              final data = docs[index].data() as Map<String, dynamic>;
              final evento = Evento.fromMap(data, docs[index].id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(_getIconoCategoria(evento.categoria)),
                  ),
                  title: Text(evento.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${evento.fecha.day}/${evento.fecha.month} - ${evento.ubicacion}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navegar al Panel de Detalles
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalleEventoScreen(evento: evento),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Ayuda visual para iconos según categoría
  IconData _getIconoCategoria(String cat) {
    switch (cat) {
      case 'Académico':
        return Icons.school;
      case 'Cultural':
        return Icons.theater_comedy;
      case 'Deportivo':
        return Icons.sports_soccer;
      default:
        return Icons.event;
    }
  }
}
