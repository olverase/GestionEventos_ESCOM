class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String ubicacion;
  final String categoria;
  final String organizadorId;
  final List<String> asistentes; // Lista de IDs de usuarios inscritos

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.ubicacion,
    required this.categoria,
    required this.organizadorId,
    required this.asistentes,
  });

  // Convertir de Objeto a Mapa (Para subir a Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha
          .millisecondsSinceEpoch, // Firebase guarda fechas como números o Timestamp
      'ubicacion': ubicacion,
      'categoria': categoria,
      'organizadorId': organizadorId,
      'asistentes': asistentes,
    };
  }

  // Convertir de Mapa a Objeto (Para leer de Firebase)
  factory Evento.fromMap(Map<String, dynamic> map, String docId) {
    return Evento(
      id: docId,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
      ubicacion: map['ubicacion'] ?? '',
      categoria: map['categoria'] ?? 'General',
      organizadorId: map['organizadorId'] ?? '',
      asistentes: List<String>.from(map['asistentes'] ?? []),
    );
  }
}
