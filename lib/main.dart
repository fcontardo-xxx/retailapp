import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:csv/csv.dart';
import 'models/registro.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(RegistroAdapter());
  await Hive.openBox<Registro>('registros');
  await Hive.openBox('temp_productos');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart-Pyme',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class ProductoEnVenta {
  final String idProducto;
  final String nombre;
  final String? color;
  final String? talla;
  final String? categoria;
  final String? linea;

  ProductoEnVenta({
    required this.idProducto,
    required this.nombre,
    this.color,
    this.talla,
    this.categoria,
    this.linea,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _inventarioFuture;
  List<ProductoEnVenta> _productosEnVenta = [];
  String? selectedProduct;
  List<String> colors = [];
  List<String> sizes = [];
  String? selectedColor;
  String? selectedSize;

  final _nombreController = TextEditingController();
  final _instagramController = TextEditingController();
  final _correoController = TextEditingController();
  String? _sexoSeleccionado;
  String? _rangoEdadSeleccionado;
  String? _lugarResidenciaSeleccionado;
  final _comentariosController = TextEditingController();

  Registro? _registroEnEdicion;
  int? _indiceEdicion;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _inventarioFuture = _loadInventarioCompleto();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _instagramController.dispose();
    _correoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadInventarioCompleto() async {
    final data = await rootBundle.loadString('assets/inventario.json');
    final List<dynamic> inventarioBase = jsonDecode(data).cast<Map<String, dynamic>>();
    final tempBox = Hive.box('temp_productos');
    final List<dynamic> tempProducts = [];
    tempBox.keys.forEach((key) {
      tempProducts.add(tempBox.get(key));
    });
    return [...inventarioBase, ...tempProducts];
  }

  void _onProductoChanged(String? value, List<dynamic> inventario) {
    setState(() {
      selectedProduct = value;
      selectedColor = null;
      selectedSize = null;
      colors = [];
      sizes = [];
      if (value != null) {
        final prod = inventario.firstWhere((p) => p['id'] == value);
        colors = List<String>.from(prod['colores'] ?? []);
      }
    });
  }

  void _onColorChanged(String? value, List<dynamic> inventario) {
    setState(() {
      selectedColor = value;
      selectedSize = null;
      sizes = [];
      if (value != null && selectedProduct != null) {
        final prod = inventario.firstWhere((p) => p['id'] == selectedProduct);
        sizes = List<String>.from(prod['tallas'] ?? []);
      }
    });
  }

  Future<void> _agregarProductoALista() async {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un producto')));
      return;
    }

    final inventario = await _loadInventarioCompleto();
    final prod = inventario.firstWhere((p) => p['id'] == selectedProduct);
    final nuevoProducto = ProductoEnVenta(
      idProducto: selectedProduct!,
      nombre: prod['nombre']?.toString() ?? 'Sin nombre',
      color: selectedColor,
      talla: selectedSize,
      categoria: prod['categoria']?.toString(),
      linea: prod['linea']?.toString(),
    );

    setState(() {
      _productosEnVenta.add(nuevoProducto);
      selectedProduct = null;
      selectedColor = null;
      selectedSize = null;
      colors = [];
      sizes = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Producto agregado')));
  }

  void _eliminarProductoDeLista(int index) {
    setState(() {
      _productosEnVenta.removeAt(index);
    });
  }

  Future<void> _mostrarDialogoEditarProducto(BuildContext context, ProductoEnVenta producto, int index) async {
    final inventario = await _loadInventarioCompleto();
    final prodData = inventario.firstWhere((p) => p['id'] == producto.idProducto);

    final List<String> coloresDisponibles = List<String>.from(prodData['colores'] ?? []);
    final List<String> tallasDisponibles = List<String>.from(prodData['tallas'] ?? []);

    String? colorSeleccionado = producto.color;
    String? tallaSeleccionada = producto.talla;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: colorSeleccionado,
                  hint: const Text('Color (opcional)'),
                  decoration: InputDecoration(
                    labelText: 'Color',
                    filled: true,
                    fillColor: const Color(0xFF6A66E3),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Ninguno')),
                    ...coloresDisponibles.map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      colorSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: tallaSeleccionada,
                  hint: const Text('Talla (opcional)'),
                  decoration: InputDecoration(
                    labelText: 'Talla',
                    filled: true,
                    fillColor: const Color(0xFF6A66E3),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Ninguna')),
                    ...tallasDisponibles.map<DropdownMenuItem<String>>((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tallaSeleccionada = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _productosEnVenta[index] = ProductoEnVenta(
                    idProducto: producto.idProducto,
                    nombre: producto.nombre,
                    color: colorSeleccionado,
                    talla: tallaSeleccionada,
                    categoria: producto.categoria,
                    linea: producto.linea,
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Producto actualizado')));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarRegistro() async {
    final box = Hive.box<Registro>('registros');

    final timestamp = _registroEnEdicion?.timestamp ?? DateTime.now();
    final idRegistro = _registroEnEdicion?.idRegistro ?? _uuid.v4();

    if (_registroEnEdicion != null) {
      final List<int> indicesAEliminar = [];
      for (int i = 0; i < box.length; i++) {
        final reg = box.getAt(i);
        if (reg?.idRegistro == idRegistro) {
          indicesAEliminar.add(i);
        }
      }
      for (int i = indicesAEliminar.length - 1; i >= 0; i--) {
        await box.deleteAt(indicesAEliminar[i]);
      }
    }

    if (_productosEnVenta.isNotEmpty) {
      for (var producto in _productosEnVenta) {
        final registro = Registro(
          idRegistro: idRegistro,
          timestamp: timestamp,
          idProducto: producto.idProducto,
          producto: producto.nombre,
          color: producto.color,
          talla: producto.talla,
          categoria: producto.categoria,
          linea: producto.linea,
          nombreCliente: _nombreController.text.trim(),
          instagram: _instagramController.text.trim(),
          correo: _correoController.text.trim(),
          sexo: _sexoSeleccionado,
          rangoEdad: _rangoEdadSeleccionado,
          lugarResidencia: _lugarResidenciaSeleccionado,
          comentarios: _comentariosController.text,
        );
        await box.add(registro);
      }
    } else {
      final registro = Registro(
        idRegistro: idRegistro,
        timestamp: timestamp,
        idProducto: null,
        producto: null,
        color: null,
        talla: null,
        categoria: null,
        linea: null,
        nombreCliente: _nombreController.text.trim(),
        instagram: _instagramController.text.trim(),
        correo: _correoController.text.trim(),
        sexo: _sexoSeleccionado,
        rangoEdad: _rangoEdadSeleccionado,
        lugarResidencia: _lugarResidenciaSeleccionado,
        comentarios: _comentariosController.text,
      );
      await box.add(registro);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_registroEnEdicion != null ? '✅ Registro modificado' : '✅ Registro guardado')),
    );
    _limpiarFormulario();
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _instagramController.clear();
    _correoController.clear();
    _comentariosController.clear();
    setState(() {
      _productosEnVenta.clear();
      selectedProduct = null;
      selectedColor = null;
      selectedSize = null;
      colors = [];
      sizes = [];
      _sexoSeleccionado = null;
      _rangoEdadSeleccionado = null;
      _lugarResidenciaSeleccionado = null;
      _registroEnEdicion = null;
      _indiceEdicion = null;
    });
  }

  void _mostrarListaRegistros(BuildContext context) {
    final box = Hive.box<Registro>('registros');

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Selecciona un registro para modificar', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<Registro> box, _) {
                  if (box.isEmpty) {
                    return const Expanded(child: Center(child: Text('No hay registros')));
                  }
                  return Expanded(
                    child: ListView.builder(
                      itemCount: box.length,
                      itemBuilder: (context, i) {
                        final reg = box.getAt(i)!;
                        return ListTile(
                          title: Text(reg.nombreCliente ?? reg.instagram ?? reg.correo ?? 'Sin nombre'),
                          subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(reg.timestamp)}'),
                          onTap: () {
                            Navigator.pop(context);
                            _cargarRegistroParaEditar(reg, i);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cargarRegistroParaEditar(Registro reg, int index) async {
    _limpiarFormulario();
    _registroEnEdicion = reg;
    _indiceEdicion = index;

    _nombreController.text = reg.nombreCliente ?? '';
    _instagramController.text = reg.instagram ?? '';
    _correoController.text = reg.correo ?? '';
    _sexoSeleccionado = reg.sexo;
    _rangoEdadSeleccionado = reg.rangoEdad;
    _lugarResidenciaSeleccionado = reg.lugarResidencia;
    _comentariosController.text = reg.comentarios ?? '';

    if (reg.idProducto != null) {
      final inventario = await _loadInventarioCompleto();
      setState(() {
        selectedProduct = reg.idProducto;
        if (reg.idProducto != null) {
          final prod = inventario.firstWhere((p) => p['id'] == reg.idProducto);
          colors = List<String>.from(prod['colores'] ?? []);
          selectedColor = reg.color;
          sizes = List<String>.from(prod['tallas'] ?? []);
          selectedSize = reg.talla;
          _productosEnVenta = [
            ProductoEnVenta(
              idProducto: reg.idProducto!,
              nombre: reg.producto ?? '',
              color: reg.color,
              talla: reg.talla,
              categoria: reg.categoria,
              linea: reg.linea,
            )
          ];
        }
      });
    }
  }

  Future<void> _exportarRegistros(BuildContext context, String formato) async {
    final box = Hive.box<Registro>('registros');
    if (box.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay registros')));
      return;
    }

    final headers = [
      'ID_Registro',
      'Fecha', 'ID_Producto', 'Producto', 'Color', 'Talla', 'Nombre_Cliente',
      'Instagram', 'Correo', 'Sexo', 'Rango_Edad', 'Lugar_Residencia', 'Comentarios'
    ];

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (formato == 'excel') {
      final excel = Excel.createExcel();
      final sheet = excel['Registros'];
      sheet.insertRow(0);
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
      }
      for (int i = 0; i < box.length; i++) {
        final reg = box.getAt(i)!;
        final row = i + 1;
        sheet.insertRow(row);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = reg.idRegistro;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = DateFormat('yyyy-MM-dd HH:mm:ss').format(reg.timestamp);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = reg.idProducto?.toString();
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = reg.producto;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = reg.color;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = reg.talla;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = reg.nombreCliente;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = reg.instagram;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = reg.correo;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = reg.sexo;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value = reg.rangoEdad;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value = reg.lugarResidencia;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value = reg.comentarios;
      }
      final file = File('${dir.path}/registros_$now.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFilex.open(file.path);
    } else {
      final List<List<dynamic>> rows = [headers];
      for (int i = 0; i < box.length; i++) {
        final reg = box.getAt(i)!;
        rows.add([
          reg.idRegistro,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(reg.timestamp),
          reg.idProducto?.toString(),
          reg.producto,
          reg.color,
          reg.talla,
          reg.nombreCliente,
          reg.instagram,
          reg.correo,
          reg.sexo,
          reg.rangoEdad,
          reg.lugarResidencia,
          reg.comentarios,
        ]);
      }
      final csv = const ListToCsvConverter().convert(rows);
      final file = File('${dir.path}/registros_$now.csv');
      await file.writeAsString(csv);
      OpenFilex.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade900,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _registroEnEdicion != null ? 'Modificar Registro' : 'Registrar Cliente / Venta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ✅ Menú con solo 2 opciones
                    PopupMenuButton<String>(
                      onSelected: (String result) {
                        switch (result) {
                          case 'modificar': _mostrarListaRegistros(context); break;
                          case 'exportar_csv': _exportarRegistros(context, 'csv'); break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'modificar',
                          child: Row(children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 10),
                            Text('Modificar Registro', style: const TextStyle(color: Colors.black)),
                          ]),
                        ),
                        PopupMenuItem<String>(
                          value: 'exportar_csv',
                          child: Row(children: [
                            const Icon(Icons.table_chart, size: 18),
                            const SizedBox(width: 10),
                            Text('Exportar a CSV', style: const TextStyle(color: Colors.black)),
                          ]),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _inventarioFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    final inventario = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_productosEnVenta.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Productos en esta venta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ..._productosEnVenta.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var p = entry.value;
                                    return Card(
                                      color: const Color(0xFF1e293b),
                                      child: ListTile(
                                        title: Text(p.nombre, style: const TextStyle(color: Colors.white)),
                                        subtitle: Text('${p.color ?? "–"} / ${p.talla ?? "–"}', style: const TextStyle(color: Colors.white70)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                              onPressed: () => _mostrarDialogoEditarProducto(context, p, index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => _eliminarProductoDeLista(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),

                          DropdownButtonFormField<String>(
                            initialValue: selectedProduct,
                            hint: Text('Producto', style: const TextStyle(color: Colors.white70)),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Color(0xFF6A66E3),
                            ),
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: Colors.white,
                            onChanged: (value) => _onProductoChanged(value, inventario),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('Producto', style: TextStyle(color: Colors.black))),
                              ...inventario
                                  .where((p) => p['id'] != null && p['id'].toString().isNotEmpty)
                                  .map<DropdownMenuItem<String>>((p) {
                                final id = p['id'].toString();
                                final nombre = p['nombre']?.toString() ?? 'Sin nombre';
                                final categoria = p['categoria']?.toString() ?? '';
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text('$nombre ($categoria)', style: TextStyle(color: Colors.black)),
                                );
                              })
                            ],
                          ),

                          if (colors.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: selectedColor,
                              hint: const Text('Color', style: TextStyle(color: Colors.white70)),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Color(0xFF6A66E3),
                              ),
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: Colors.white,
                              onChanged: (value) => _onColorChanged(value, inventario),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Color', style: TextStyle(color: Colors.black))),
                                ...colors.map<DropdownMenuItem<String>>((c) {
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c, style: TextStyle(color: Colors.black)),
                                  );
                                }).toList(),
                              ],
                            ),

                          if (sizes.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: selectedSize,
                              hint: const Text('Talla', style: TextStyle(color: Colors.white70)),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Color(0xFF6A66E3),
                              ),
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: Colors.white,
                              onChanged: (value) => setState(() => selectedSize = value),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Talla', style: TextStyle(color: Colors.black))),
                                ...sizes.map<DropdownMenuItem<String>>((s) {
                                  return DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(s, style: TextStyle(color: Colors.black)),
                                  );
                                }).toList(),
                              ],
                            ),

                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _agregarProductoALista,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Agregar Producto', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Text('Datos del Cliente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),

                          _campoConEtiquetaBlanca('Nombre', _nombreController),
                          const SizedBox(height: 12),
                          _campoConEtiquetaBlanca('Instagram', _instagramController),
                          const SizedBox(height: 12),
                          _campoConEtiquetaBlanca('Correo', _correoController),
                          const SizedBox(height: 12),

                          _dropdownConEtiquetaBlanca(
                            label: 'Sexo',
                            value: _sexoSeleccionado,
                            hint: 'Sexo',
                            items: const [
                              DropdownMenuItem<String>(value: null, child: Text('Sexo', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Hombre', child: Text('Hombre', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Mujer', child: Text('Mujer', style: TextStyle(color: Colors.black))),
                            ],
                            onChanged: (value) => setState(() => _sexoSeleccionado = value),
                          ),
                          const SizedBox(height: 12),

                          _dropdownConEtiquetaBlanca(
                            label: 'Rango de Edad',
                            value: _rangoEdadSeleccionado,
                            hint: 'Rango de Edad',
                            items: const [
                              DropdownMenuItem<String>(value: null, child: Text('Rango de Edad', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Menor de 18', child: Text('Menor de 18', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: '18-25', child: Text('18-25', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: '26-35', child: Text('26-35', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: '36-45', child: Text('36-45', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: '46-60', child: Text('46-60', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Mayor de 60', child: Text('Mayor de 60', style: TextStyle(color: Colors.black))),
                            ],
                            onChanged: (value) => setState(() => _rangoEdadSeleccionado = value),
                          ),
                          const SizedBox(height: 12),

                          _dropdownConEtiquetaBlanca(
                            label: 'Lugar de Residencia',
                            value: _lugarResidenciaSeleccionado,
                            hint: 'Lugar de Residencia',
                            items: const [
                              DropdownMenuItem<String>(value: null, child: Text('Lugar de Residencia', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Isla de Maipo', child: Text('Isla de Maipo', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Provincia de Talagante', child: Text('Provincia de Talagante', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Santiago', child: Text('Santiago', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem<String>(value: 'Otro', child: Text('Otro', style: TextStyle(color: Colors.black))),
                            ],
                            onChanged: (value) => setState(() => _lugarResidenciaSeleccionado = value),
                          ),

                          const SizedBox(height: 12),
                          TextField(
                            controller: _comentariosController,
                            decoration: _inputDecoration().copyWith(hintText: 'Comentarios'),
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _guardarRegistro,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _registroEnEdicion != null ? 'Guardar Cambios' : 'Guardar Registro',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownConEtiquetaBlanca({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: const TextStyle(color: Colors.white70)),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Color(0xFF6A66E3),
      ),
      style: const TextStyle(color: Colors.white), // ✅ Texto blanco en campo
      dropdownColor: Colors.white, // ✅ Fondo blanco en menú
      onChanged: onChanged,
      items: items, // ✅ Cada item ya tiene texto negro
    );
  }

  Widget _campoConEtiquetaBlanca(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration().copyWith(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Color(0xFF6A66E3),
    );
  }
}