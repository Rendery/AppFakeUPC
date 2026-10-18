import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para las mayúsculas automáticas
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- FORMATTER PARA MAYÚSCULAS AUTOMÁTICAS ---
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// --- MODELO DE DATOS PARA LA PLANTILLA ---
class PerfilPlantilla {
  final String id;
  final String nombrePlantilla;
  final String nombre;
  final String codigo;
  final String idBanner;
  final double nameSize;
  final double descSize;
  final String? imagePath;

  PerfilPlantilla({
    required this.id,
    required this.nombrePlantilla,
    required this.nombre,
    required this.codigo,
    required this.idBanner,
    required this.nameSize,
    required this.descSize,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombrePlantilla': nombrePlantilla,
    'nombre': nombre,
    'codigo': codigo,
    'idBanner': idBanner,
    'nameSize': nameSize,
    'descSize': descSize,
    'imagePath': imagePath,
  };

  factory PerfilPlantilla.fromJson(Map<String, dynamic> json) => PerfilPlantilla(
    id: json['id'],
    nombrePlantilla: json['nombrePlantilla'],
    nombre: json['nombre'],
    codigo: json['codigo'],
    idBanner: json['idBanner'],
    nameSize: json['nameSize'],
    descSize: json['descSize'],
    imagePath: json['imagePath'],
  );
}

class VistaConfiguracion extends StatefulWidget {
  final String initialName;
  final String initialCode;
  final String initialIdBanner;
  final double initialNameSize;
  final double initialDescSize;
  final String? initialImagePath;

  const VistaConfiguracion({
    super.key,
    required this.initialName,
    required this.initialCode,
    required this.initialIdBanner,
    required this.initialNameSize,
    required this.initialDescSize,
    this.initialImagePath,
  });

  @override
  State<VistaConfiguracion> createState() => _VistaConfiguracionState();
}

class _VistaConfiguracionState extends State<VistaConfiguracion> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _idBannerController;

  late double _nameSize;
  late double _descSize;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();
  List<PerfilPlantilla> _plantillas = [];

  final Color primaryRed = const Color(0xFFE33E3E);
  final Color backgroundColor = const Color(0xFFF4F6F9);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _codeController = TextEditingController(text: widget.initialCode);
    _idBannerController = TextEditingController(text: widget.initialIdBanner);
    _nameSize = widget.initialNameSize;
    _descSize = widget.initialDescSize;

    if (widget.initialImagePath != null && widget.initialImagePath!.isNotEmpty) {
      _selectedImage = File(widget.initialImagePath!);
    }

    _cargarPlantillas();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _idBannerController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE PLANTILLAS ---
  Future<void> _cargarPlantillas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? plantillasJson = prefs.getStringList('plantillasGuardadas');

    if (plantillasJson != null) {
      setState(() {
        _plantillas = plantillasJson
            .map((jsonStr) => PerfilPlantilla.fromJson(jsonDecode(jsonStr)))
            .toList();
      });
    }
  }

  Future<void> _guardarPlantillasEnMemoria() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> plantillasJson = _plantillas.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('plantillasGuardadas', plantillasJson);
  }

  void _dialogoCrearPlantilla() {
    TextEditingController nombrePlantillaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombrar Plantilla'),
        content: TextField(
          controller: nombrePlantillaController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: "Ej. Perfil Principal, Amigo 1..."),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
            onPressed: () {
              if (nombrePlantillaController.text.isNotEmpty) {
                _guardarConfiguracionComoPlantilla(nombrePlantillaController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _guardarConfiguracionComoPlantilla(String nombrePlantilla) {
    final nuevaPlantilla = PerfilPlantilla(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombrePlantilla: nombrePlantilla,
      nombre: _nameController.text,
      codigo: _codeController.text,
      idBanner: _idBannerController.text,
      nameSize: _nameSize,
      descSize: _descSize,
      imagePath: _selectedImage?.path,
    );

    setState(() {
      _plantillas.add(nuevaPlantilla);
    });

    _guardarPlantillasEnMemoria();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plantilla "$nombrePlantilla" guardada'), backgroundColor: Colors.green),
    );
  }

  void _cargarDatosDePlantilla(PerfilPlantilla plantilla) {
    setState(() {
      _nameController.text = plantilla.nombre;
      _codeController.text = plantilla.codigo;
      _idBannerController.text = plantilla.idBanner;
      _nameSize = plantilla.nameSize;
      _descSize = plantilla.descSize;
      if (plantilla.imagePath != null && File(plantilla.imagePath!).existsSync()) {
        _selectedImage = File(plantilla.imagePath!);
      } else {
        _selectedImage = null;
      }
    });
    Navigator.pop(context); // Cierra el modal de selección
  }

  void _eliminarPlantilla(String id) {
    setState(() {
      _plantillas.removeWhere((p) => p.id == id);
    });
    _guardarPlantillasEnMemoria();
  }

  void _mostrarGestorPlantillas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              // Creamos la lista combinando la de por defecto + las guardadas
              final List<PerfilPlantilla> listaMostrada = [
                PerfilPlantilla(
                  id: 'default',
                  nombrePlantilla: 'Por Defecto (Fábrica)',
                  nombre: 'EDERY RENZO A*** V***',
                  codigo: '201822832',
                  idBanner: 'N01864219',
                  nameSize: 32.0,
                  descSize: 18.0,
                  imagePath: null,
                ),
                ..._plantillas
              ];

              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Plantillas Guardadas", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: listaMostrada.length,
                        itemBuilder: (context, index) {
                          final p = listaMostrada[index];
                          final bool esPorDefecto = p.id == 'default';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: esPorDefecto ? Colors.orange[100] : Colors.grey[200],
                              backgroundImage: p.imagePath != null ? FileImage(File(p.imagePath!)) : null,
                              child: p.imagePath == null
                                  ? Icon(esPorDefecto ? Icons.factory : Icons.person, color: esPorDefecto ? Colors.orange : Colors.grey)
                                  : null,
                            ),
                            title: Text(
                                p.nombrePlantilla,
                                style: TextStyle(fontWeight: FontWeight.bold, color: esPorDefecto ? Colors.orange[800] : Colors.black87)
                            ),
                            subtitle: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => _cargarDatosDePlantilla(p),
                            trailing: esPorDefecto
                                ? const Icon(Icons.check_circle, color: Colors.orange) // No se puede borrar la default
                                : IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                setModalState(() => _eliminarPlantilla(p.id));
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Guardar configuración actual"),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _dialogoCrearPlantilla();
                        },
                      ),
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // --- LÓGICA DE FOTO Y GUARDADO PRINCIPAL ---
  Future<void> _pickAndSaveImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedImage = await File(image.path).copy(newPath);

      setState(() {
        _selectedImage = savedImage;
      });
    }
  }

  void _guardarYSalir() {
    Navigator.pop(context, {
      'name': _nameController.text.toUpperCase(),
      'code': _codeController.text,
      'idBanner': _idBannerController.text,
      'nameSize': _nameSize,
      'descSize': _descSize,
      'imagePath': _selectedImage?.path,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Fondo del encabezado (Curvado)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
            ),
          ),

          // 2. Contenido Principal (Lo ponemos antes para que NO tape los botones superiores)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 40),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : const AssetImage('assets/profile_picture.jpg') as ImageProvider,
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickAndSaveImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryRed, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildCardSection(
                    title: "Datos del Estudiante",
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        _buildCustomTextField(
                          controller: _nameController,
                          label: "Nombre Completo",
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.characters, // Mayúsculas automáticas teclado
                          inputFormatters: [UpperCaseTextFormatter()], // Fuerza mayúsculas en pegado/código
                        ),
                        const SizedBox(height: 15),
                        _buildCustomTextField(
                            controller: _codeController,
                            label: "Código de Alumno",
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number
                        ),
                        const SizedBox(height: 15),
                        _buildCustomTextField(
                            controller: _idBannerController,
                            label: "ID Banner",
                            icon: Icons.credit_card
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    title: "Apariencia de Textos",
                    icon: Icons.text_fields,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Tamaño del Nombre", style: GoogleFonts.poppins(color: Colors.grey[700])),
                            Text("${_nameSize.toInt()} pt", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryRed)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(activeTrackColor: primaryRed, thumbColor: primaryRed, overlayColor: primaryRed.withOpacity(0.2)),
                          child: Slider(value: _nameSize, min: 15.0, max: 50.0, onChanged: (val) => setState(() => _nameSize = val)),
                        ),
                        Center(
                          child: Text(
                            _nameController.text.isEmpty ? "VISTA PREVIA" : _nameController.text.toUpperCase(),
                            style: GoogleFonts.oswald(color: primaryRed, fontSize: _nameSize, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Tamaño de Descripciones", style: GoogleFonts.poppins(color: Colors.grey[700])),
                            Text("${_descSize.toInt()} pt", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(activeTrackColor: Colors.blueGrey, thumbColor: Colors.blueGrey, overlayColor: Colors.blueGrey.withOpacity(0.2)),
                          child: Slider(value: _descSize, min: 10.0, max: 30.0, onChanged: (val) => setState(() => _descSize = val)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 5, shadowColor: primaryRed.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _guardarYSalir,
                      child: Text('APLICAR AL TIU VIRTUAL', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Título de la vista (Protegido con IgnorePointer por si acaso)
          Positioned(
            top: 55, left: 0, right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'Personalizar TIU',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.2),
                ),
              ),
            ),
          ),

          // 4. Botones Superiores (¡AQUÍ ESTÁ LA MAGIA! Puestos al final del Stack garantizan que se puedan tocar)
          Positioned(
            top: 45, left: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 45, right: 15,
            child: IconButton(
              icon: const Icon(Icons.bookmarks, color: Colors.white, size: 28),
              tooltip: "Gestor de Plantillas",
              onPressed: _mostrarGestorPlantillas,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 22), const SizedBox(width: 10),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF344563))),
            ],
          ),
          const SizedBox(height: 20), child,
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: primaryRed, size: 20),
        filled: true, fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryRed, width: 1.5)),
      ),
    );
  }
}