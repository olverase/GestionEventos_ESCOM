import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crear_evento_screen.dart';
import 'detalle_evento_screen.dart';
import '../models/evento_model.dart';
import '../auth/login_screen.dart';
import '../profile/perfil_screen.dart';

class MisEventosScreen extends StatefulWidget {
  final bool esAdmin;
  const MisEventosScreen({super.key, this.esAdmin = false});

  @override
  State<MisEventosScreen> createState() => _MisEventosScreenState();
}

class _MisEventosScreenState extends State<MisEventosScreen> {
  final String miId = FirebaseAuth.instance.currentUser!.uid;

  // --- NUEVO: Mapa para traducir códigos de avatar a Íconos visuales ---
  final Map<String, dynamic> _avatarMap = {
    'tech': {'icon': Icons.computer, 'color': Colors.indigo},
    'science': {'icon': Icons.science, 'color': Colors.teal},
    'hardware': {'icon': Icons.electrical_services, 'color': Colors.orange},
    'grad': {'icon': Icons.school, 'color': Colors.purple},
    'security': {'icon': Icons.security, 'color': Colors.redAccent},
    'A': {
      'icon': Icons.person,
      'color': Colors.grey
    }, // Fallback para datos viejos
  };
  // ---------------------------------------------------------------------

  void _toggleValidacion(String eventoId, bool estadoActual) {
    FirebaseFirestore.instance.collection('eventos').doc(eventoId).update({
      'validado': !estadoActual,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!estadoActual ? 'Evento APROBADO' : 'Evento OCULTO'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esAdmin ? 'Supervisión (Validar)' : 'Mis Eventos'),
        backgroundColor: widget.esAdmin ? Colors.purple : Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const PerfilScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted)
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (c) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.esAdmin
            ? FirebaseFirestore.instance.collection('eventos').snapshots()
            : FirebaseFirestore.instance
                .collection('eventos')
                .where('organizadorId', isEqualTo: miId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(widget.esAdmin
                  ? 'No hay eventos para supervisar.'
                  : 'No has creado eventos.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final eventoId = docs[index].id;
              final evento = Evento.fromMap(data, eventoId);
              final bool isValidado = data['validado'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: (!isValidado && widget.esAdmin)
                    ? Colors.orange.shade50
                    : Colors.white,
                child: ListTile(
                  // Ícono principal: Estado de validación (Palomita o Reloj)
                  leading: CircleAvatar(
                    backgroundColor: isValidado
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(isValidado ? Icons.check : Icons.access_time,
                        color: isValidado ? Colors.green : Colors.orange),
                  ),
                  title: Text(evento.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(evento.ubicacion),
                      if (widget.esAdmin && !isValidado)
                        const Text("⚠️ PENDIENTE",
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),

                      // --- NUEVO: Mostrar el Avatar Académico del Organizador (Solo para Admin) ---
                      if (widget.esAdmin)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(evento.organizadorId)
                              .get(),
                          builder: (context, snap) {
                            if (!snap.hasData || !snap.data!.exists)
                              return const SizedBox();

                            final uData =
                                snap.data!.data() as Map<String, dynamic>;
                            final nombre = uData['nombre'] ?? 'Desconocido';
                            // Obtenemos el código del avatar (ej: 'tech')
                            final avatarCode = uData['avatar'] ?? 'A';
                            // Buscamos su ícono y color en el mapa
                            final avatarInfo =
                                _avatarMap[avatarCode] ?? _avatarMap['A']!;

                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  // Dibujamos el pequeño avatar académico
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: avatarInfo['color'],
                                    child: Icon(avatarInfo['icon'],
                                        size: 12, color: Colors.white),
                                  ),
                                  const SizedBox(width: 5),
                                  Text("Org: $nombre",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple.shade300)),
                                ],
                              ),
                            );
                          },
                        )
                      // -----------------------------------------------------------------------
                    ],
                  ),
                  trailing: widget.esAdmin
                      ? Switch(
                          value: isValidado,
                          activeColor: Colors.green,
                          onChanged: (val) =>
                              _toggleValidacion(eventoId, isValidado),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => DetalleEventoScreen(evento: evento))),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.esAdmin
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const CrearEventoScreen())),
            ),
    );
  }
}
