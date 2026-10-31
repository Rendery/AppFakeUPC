import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELO DE DATOS DEL PERFIL ---
class Perfil {
  final String id;
  final String nombrePerfil;
  final String nombre;
  final String codigo;
  final String idBanner;
  final String carrera;
  final String campus;
  final double nameSize;
  final double descSize;
  final String? imagePath;

  const Perfil({
    this.id = '',
    this.nombrePerfil = '',
    this.nombre = '',
    this.codigo = '',
    this.idBanner = '',
    this.carrera = '',
    this.campus = '',
    this.nameSize = 32.0,
    this.descSize = 18.0,
    this.imagePath,
  });

  // Un perfil sin ningún dato equivale a "borrar todo" (el TIU vuelve a quedar vacío)
  bool get estaVacio =>
      nombre.isEmpty && codigo.isEmpty && idBanner.isEmpty && carrera.isEmpty && campus.isEmpty && imagePath == null;

  Perfil copyWith({String? id, String? nombrePerfil}) => Perfil(
    id: id ?? this.id,
    nombrePerfil: nombrePerfil ?? this.nombrePerfil,
    nombre: nombre,
    codigo: codigo,
    idBanner: idBanner,
    carrera: carrera,
    campus: campus,
    nameSize: nameSize,
    descSize: descSize,
    imagePath: imagePath,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombrePerfil': nombrePerfil,
    'nombre': nombre,
    'codigo': codigo,
    'idBanner': idBanner,
    'carrera': carrera,
    'campus': campus,
    'nameSize': nameSize,
    'descSize': descSize,
    'imagePath': imagePath,
  };

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
    id: json['id'] as String? ?? '',
    nombrePerfil: json['nombrePerfil'] as String? ?? '',
    nombre: json['nombre'] as String? ?? '',
    codigo: json['codigo'] as String? ?? '',
    idBanner: json['idBanner'] as String? ?? '',
    carrera: json['carrera'] as String? ?? '',
    campus: json['campus'] as String? ?? '',
    nameSize: (json['nameSize'] as num?)?.toDouble() ?? 32.0,
    descSize: (json['descSize'] as num?)?.toDouble() ?? 18.0,
    imagePath: json['imagePath'] as String?,
  );
}

// --- ALMACENAMIENTO LOCAL (SharedPreferences) ---
class PerfilStore {
  static const _kNombre = 'userName';
  static const _kCodigo = 'userCode';
  static const _kIdBanner = 'idBanner';
  static const _kCarrera = 'carrera';
  static const _kCampus = 'campus';
  static const _kNameSize = 'nameFontSize';
  static const _kDescSize = 'descFontSize';
  static const _kImagePath = 'imagePath';
  static const _kGuardados = 'perfilesGuardados';

  // Perfil que se muestra en el TIU; null si la app todavía no tiene datos
  static Perfil? leerActual(SharedPreferences prefs) {
    if (!prefs.containsKey(_kNombre)) return null;
    return Perfil(
      nombre: prefs.getString(_kNombre) ?? '',
      codigo: prefs.getString(_kCodigo) ?? '',
      idBanner: prefs.getString(_kIdBanner) ?? '',
      carrera: prefs.getString(_kCarrera) ?? '',
      campus: prefs.getString(_kCampus) ?? '',
      nameSize: prefs.getDouble(_kNameSize) ?? 32.0,
      descSize: prefs.getDouble(_kDescSize) ?? 18.0,
      imagePath: prefs.getString(_kImagePath),
    );
  }

  static Future<void> guardarActual(SharedPreferences prefs, Perfil? perfil) async {
    if (perfil == null) {
      for (final key in [_kNombre, _kCodigo, _kIdBanner, _kCarrera, _kCampus, _kNameSize, _kDescSize, _kImagePath]) {
        await prefs.remove(key);
      }
      return;
    }
    await prefs.setString(_kNombre, perfil.nombre);
    await prefs.setString(_kCodigo, perfil.codigo);
    await prefs.setString(_kIdBanner, perfil.idBanner);
    await prefs.setString(_kCarrera, perfil.carrera);
    await prefs.setString(_kCampus, perfil.campus);
    await prefs.setDouble(_kNameSize, perfil.nameSize);
    await prefs.setDouble(_kDescSize, perfil.descSize);
    if (perfil.imagePath != null && perfil.imagePath!.isNotEmpty) {
      await prefs.setString(_kImagePath, perfil.imagePath!);
    } else {
      await prefs.remove(_kImagePath);
    }
  }

  static List<Perfil> leerGuardados(SharedPreferences prefs) {
    final lista = prefs.getStringList(_kGuardados) ?? [];
    return lista.map((s) => Perfil.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  static Future<void> guardarGuardados(SharedPreferences prefs, List<Perfil> perfiles) async {
    await prefs.setStringList(_kGuardados, perfiles.map((p) => jsonEncode(p.toJson())).toList());
  }
}

// --- EXPORTAR / IMPORTAR A ARCHIVO ---
// Formato: {"app": "upctiu", "version": 1, "perfiles": [ {...datos, "foto": "<jpg en base64>"} ]}
// La foto va incrustada para que el archivo funcione en cualquier celular.
class PerfilArchivo {
  static const _app = 'upctiu';
  static const _version = 1;

  static Future<Uint8List> codificar(List<Perfil> perfiles) async {
    final lista = <Map<String, dynamic>>[];
    for (final p in perfiles) {
      final json = p.toJson()
        ..remove('id')
        ..remove('imagePath');
      final foto = p.imagePath == null ? null : File(p.imagePath!);
      if (foto != null && await foto.exists()) {
        json['foto'] = base64Encode(await foto.readAsBytes());
      }
      lista.add(json);
    }
    final texto = const JsonEncoder.withIndent('  ').convert({'app': _app, 'version': _version, 'perfiles': lista});
    return Uint8List.fromList(utf8.encode(texto));
  }

  // Lanza FormatException si el archivo no es un perfil de esta app
  static Future<List<Perfil>> decodificar(Uint8List bytes) async {
    final Object? data;
    try {
      data = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const FormatException('El archivo no es un perfil válido.');
    }
    if (data is! Map<String, dynamic> || data['app'] != _app || data['perfiles'] is! List) {
      throw const FormatException('El archivo no es un perfil de UPC TIU.');
    }

    final base = DateTime.now().millisecondsSinceEpoch;
    final perfiles = <Perfil>[];
    var i = 0;
    for (final item in data['perfiles'] as List) {
      if (item is! Map<String, dynamic>) continue;
      final id = '${base}_${i++}';
      String? imagePath;
      final foto = item['foto'];
      if (foto is String && foto.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/perfil_$id.jpg');
        await file.writeAsBytes(base64Decode(foto));
        imagePath = file.path;
      }
      final json = Map<String, dynamic>.of(item)
        ..['id'] = id
        ..['imagePath'] = imagePath;
      perfiles.add(Perfil.fromJson(json));
    }
    if (perfiles.isEmpty) throw const FormatException('El archivo no trae ningún perfil.');
    return perfiles;
  }

  // Devuelve false si el usuario canceló el guardado
  static Future<bool> exportar(List<Perfil> perfiles, String nombreArchivo) async {
    final uri = await FilePicker.saveFile(
      fileName: nombreArchivo,
      bytes: await codificar(perfiles),
      mimeType: 'application/json',
    );
    return uri != null;
  }

  // Devuelve null si el usuario canceló la selección
  static Future<List<Perfil>?> importar() async {
    final archivos = await FilePicker.pickFiles(type: FileType.any);
    if (archivos.isEmpty) return null;
    return decodificar(await archivos.first.readAsBytes());
  }

  static String nombreArchivoPara(String nombre) {
    final limpio = nombre.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return 'perfil_${limpio.isEmpty ? 'tiu' : limpio}.upctiu.json';
  }
}
