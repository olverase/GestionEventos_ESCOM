import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrearEventoScreen extends StatefulWidget {
  final Evento? evento; // Si es null, es CREAR. Si tiene datos, es EDITAR.

  const CrearEventoScreen({super.key, this.evento});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final _lugarController = TextEditingController();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String _categoria = 'Académico';
  final List<String> _categorias = [
    'Académico',
    'Cultural',
    'Deportivo',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    // Si recibimos un evento para editar, llenamos los campos
    if (widget.evento != null) {
      _tituloController.text = widget.evento!.titulo;
      _descController.text = widget.evento!.descripcion;
      _lugarController.text = widget.evento!.ubicacion;
      _categoria = widget.evento!.categoria;
      _fechaSeleccionada = widget.evento!.fecha;
      _horaSeleccionada = TimeOfDay.fromDateTime(widget.evento!.fecha);
    }
  }

  // Guardar o Actualizar
  Future<void> _guardarEvento() async {
    if (_formKey.currentState!.validate()) {
      if (_fechaSeleccionada == null || _horaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor define fecha y hora')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procesando...')),
      );

      try {
        final db = FirebaseFirestore.instance;
        // Si es editar, usamos el ID existente. Si es nuevo, generamos uno.
        final String id =
            widget.evento?.id ?? db.collection('eventos').doc().id;

        final fechaFinal = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
          _horaSeleccionada!.hour,
          _horaSeleccionada!.minute,
        );

        final nuevoEvento = Evento(
          id: id,
          titulo: _tituloController.text,
          descripcion: _descController.text,
          fecha: fechaFinal,
          ubicacion: _lugarController.text,
          categoria: _categoria,
          organizadorId: FirebaseAuth.instance.currentUser!.uid,
          asistentes: widget.evento?.asistentes ??
              [], // Mantener asistentes si se edita
        );

        // Guardamos (Esto sirve para Crear y para Sobreescribir/Editar)
        await db.collection('eventos').doc(id).set(nuevoEvento.toMap());

        if (mounted) {
          Navigator.pop(context); // Regresar a la lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('¡Operación exitosa!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  // Eliminar Evento (RF-012)
  Future<void> _eliminarEvento() async {
    // Confirmación simple
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true && widget.evento != null) {
      try {
        await FirebaseFirestore.instance
            .collection('eventos')
            .doc(widget.evento!.id)
            .delete();
        if (mounted) {
          Navigator.pop(context); // Cerrar pantalla
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Evento eliminado'), backgroundColor: Colors.red));
        }
      } catch (e) {
        // Manejo de error
      }
    }
  }

  // ... (Las funciones de _seleccionarFecha y _seleccionarHora son iguales, las dejo abreviadas aquí,
  // pero tú asegúrate de que estén en tu archivo o cópialas del anterior si las borraste)
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
        context: context, initialTime: _horaSeleccionada ?? TimeOfDay.now());
    if (picked != null) setState(() => _horaSeleccionada = picked);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.evento != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Evento' : 'Nuevo Evento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Botón de Eliminar (Solo aparece si estamos editando)
          if (esEdicion)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminarEvento,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                    labelText: 'Título', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Descripción', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: _categoria,
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v.toString()),
                decoration: const InputDecoration(
                    labelText: 'Categoría', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _lugarController,
                decoration: const InputDecoration(
                    labelText: 'Ubicación', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_fechaSeleccionada == null
                          ? 'Fecha'
                          : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}'),
                      onPressed: _seleccionarFecha,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_horaSeleccionada == null
                          ? 'Hora'
                          : _horaSeleccionada!.format(context)),
                      onPressed: _seleccionarHora,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _guardarEvento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child:
                    Text(esEdicion ? 'ACTUALIZAR EVENTO' : 'PUBLICAR EVENTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
