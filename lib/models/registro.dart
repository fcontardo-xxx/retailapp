import 'package:hive_flutter/hive_flutter.dart';

part 'registro.g.dart';

@HiveType(typeId: 0)
class Registro {
  @HiveField(0)
  final String? idRegistro; // ✅ ID único por VENTA (no por producto)

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String? idProducto;

  @HiveField(3)
  final String? producto;

  @HiveField(4)
  final String? color;

  @HiveField(5)
  final String? talla;

  @HiveField(6)
  final String? categoria;

  @HiveField(7)
  final String? linea;

  @HiveField(8)
  final String? nombreCliente;

  @HiveField(9)
  final String? instagram;

  @HiveField(10)
  final String? correo;

  @HiveField(11)
  final String? sexo;

  @HiveField(12)
  final String? rangoEdad;

  @HiveField(13)
  final String? lugarResidencia;

  @HiveField(14)
  final String? comentarios;

  Registro({
    this.idRegistro, // ✅ Puede ser null al crear, pero se asigna antes de guardar
    required this.timestamp,
    this.idProducto,
    this.producto,
    this.color,
    this.talla,
    this.categoria,
    this.linea,
    this.nombreCliente,
    this.instagram,
    this.correo,
    this.sexo,
    this.rangoEdad,
    this.lugarResidencia,
    this.comentarios,
  });
}