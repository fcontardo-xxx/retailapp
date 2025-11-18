// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registro.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegistroAdapter extends TypeAdapter<Registro> {
  @override
  final int typeId = 0;

  @override
  Registro read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Registro(
      idRegistro: fields[0] as String?,
      timestamp: fields[1] as DateTime,
      idProducto: fields[2] as String?,
      producto: fields[3] as String?,
      color: fields[4] as String?,
      talla: fields[5] as String?,
      categoria: fields[6] as String?,
      linea: fields[7] as String?,
      nombreCliente: fields[8] as String?,
      instagram: fields[9] as String?,
      correo: fields[10] as String?,
      sexo: fields[11] as String?,
      rangoEdad: fields[12] as String?,
      lugarResidencia: fields[13] as String?,
      comentarios: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Registro obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.idRegistro)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.idProducto)
      ..writeByte(3)
      ..write(obj.producto)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.talla)
      ..writeByte(6)
      ..write(obj.categoria)
      ..writeByte(7)
      ..write(obj.linea)
      ..writeByte(8)
      ..write(obj.nombreCliente)
      ..writeByte(9)
      ..write(obj.instagram)
      ..writeByte(10)
      ..write(obj.correo)
      ..writeByte(11)
      ..write(obj.sexo)
      ..writeByte(12)
      ..write(obj.rangoEdad)
      ..writeByte(13)
      ..write(obj.lugarResidencia)
      ..writeByte(14)
      ..write(obj.comentarios);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistroAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
