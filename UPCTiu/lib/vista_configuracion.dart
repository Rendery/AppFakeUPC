import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para las mayúsculas automáticas
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fuentes.dart';
import 'perfil.dart';

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

class VistaConfiguracion extends StatefulWidget {
  final SharedPreferences prefs;
  // Perfil que se muestra ahora en el TIU; null si la app todavía no tiene datos
  final Perfil? inicial;

  const VistaConfiguracion({
    super.key,
    required this.prefs,
    this.inicial,
  });

  @override
  State<VistaConfiguracion> createState() => _VistaConfiguracionState();
}

class _VistaConfiguracionState extends State<VistaConfiguracion> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _idBannerController;
  late TextEditingController _carreraController;
  late TextEditingController _campusController;

  late double _nameSize;
  late double _descSize;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();
  List<Perfil> _perfiles = [];

  final Color primaryRed = const Color(0xFFE33E3E);
  final Color backgroundColor = const Color(0xFFF4F6F9);

  @override
  void initState() {
    super.initState();
    final perfil = widget.inicial ?? const Perfil();
    _nameController = TextEditingController(text: perfil.nombre);
    _codeController = TextEditingController(text: perfil.codigo);
    _idBannerController = TextEditingController(text: perfil.idBanner);
    _carreraController = TextEditingController(text: perfil.carrera);
    _campusController = TextEditingController(text: perfil.campus);
    _nameSize = perfil.nameSize;
    _descSize = perfil.descSize;

    if (perfil.imagePath != null && perfil.imagePath!.isNotEmpty) {
      _selectedImage = File(perfil.imagePath!);
    }

    _perfiles = PerfilStore.leerGuardados(widget.prefs);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _idBannerController.dispose();
    _carreraController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  Perfil _perfilDelFormulario({String id = '', String nombrePerfil = ''}) {
    return Perfil(
      id: id,
      nombrePerfil: nombrePerfil,
      nombre: _nameController.text.trim().toUpperCase(),
      codigo: _codeController.text.trim(),
      idBanner: _idBannerController.text.trim().toUpperCase(),
      carrera: _carreraController.text.trim().toUpperCase(),
      campus: _campusController.text.trim(),
      nameSize: _nameSize,
      descSize: _descSize,
      imagePath: _selectedImage?.path,
    );
  }

  void _mostrarMensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? Colors.redAccent : Colors.green),
    );
  }

  Future<bool> _confirmar(String titulo, String mensaje, String accion) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  // --- LÓGICA DE PERFILES GUARDADOS ---
  Future<void> _guardarPerfilesEnMemoria() => PerfilStore.guardarGuardados(widget.prefs, _perfiles);

  void _dialogoCrearPerfil() {
    TextEditingController nombrePerfilController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombrar Perfil'),
        content: TextField(
          controller: nombrePerfilController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: "Ej. Perfil Principal, Amigo 1..."),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
            onPressed: () {
              if (nombrePerfilController.text.trim().isNotEmpty) {
                _guardarConfiguracionComoPerfil(nombrePerfilController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _guardarConfiguracionComoPerfil(String nombrePerfil) {
    final nuevoPerfil = _perfilDelFormulario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombrePerfil: nombrePerfil,
    );

    setState(() {
      _perfiles.add(nuevoPerfil);
    });

    _guardarPerfilesEnMemoria();
    _mostrarMensaje('Perfil "$nombrePerfil" guardado');
  }

  void _cargarDatosDePerfil(Perfil perfil) {
    setState(() {
      _nameController.text = perfil.nombre;
      _codeController.text = perfil.codigo;
      _idBannerController.text = perfil.idBanner;
      _carreraController.text = perfil.carrera;
      _campusController.text = perfil.campus;
      _nameSize = perfil.nameSize;
      _descSize = perfil.descSize;
      if (perfil.imagePath != null && File(perfil.imagePath!).existsSync()) {
        _selectedImage = File(perfil.imagePath!);
      } else {
        _selectedImage = null;
      }
    });
  }

  Future<void> _eliminarPerfil(Perfil perfil) async {
    final ok = await _confirmar('Eliminar perfil', '¿Eliminar "${perfil.nombrePerfil}"?', 'Eliminar');
    if (!ok) return;
    setState(() {
      _perfiles.removeWhere((p) => p.id == perfil.id);
    });
    _guardarPerfilesEnMemoria();
  }

  Future<void> _exportar(List<Perfil> perfiles, String nombreArchivo) async {
    try {
      final guardado = await PerfilArchivo.exportar(perfiles, nombreArchivo);
      if (guardado && mounted) {
        _mostrarMensaje(perfiles.length == 1 ? 'Perfil exportado' : '${perfiles.length} perfiles exportados');
      }
    } catch (e) {
      if (mounted) _mostrarMensaje('No se pudo exportar: $e', error: true);
    }
  }

  Future<void> _importar() async {
    try {
      final importados = await PerfilArchivo.importar();
      if (importados == null || !mounted) return;
      setState(() {
        _perfiles.addAll(importados);
      });
      await _guardarPerfilesEnMemoria();
      if (!mounted) return;
      _mostrarMensaje(importados.length == 1
          ? 'Perfil "${importados.first.nombrePerfil}" importado. Tócalo para cargarlo.'
          : 'Se importaron ${importados.length} perfiles. Toca uno para cargarlo.');
    } on FormatException catch (e) {
      if (mounted) _mostrarMensaje(e.message, error: true);
    } catch (e) {
      if (mounted) _mostrarMensaje('No se pudo importar: $e', error: true);
    }
  }

  ImageProvider? _miniatura(String? path) {
    if (path == null || !File(path).existsSync()) return null;
    return ResizeImage(FileImage(File(path)), width: 120);
  }

  void _mostrarGestorPerfiles() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Perfiles Guardados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      if (_perfiles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            "Todavía no tienes perfiles.\nGuarda tus datos actuales o importa un archivo.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _perfiles.length,
                            itemBuilder: (context, index) {
                              final p = _perfiles[index];
                              final foto = _miniatura(p.imagePath);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: foto,
                                  child: foto == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                ),
                                title: Text(p.nombrePerfil, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                subtitle: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () {
                                  _cargarDatosDePerfil(p);
                                  Navigator.pop(context);
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.file_download_outlined, color: Colors.blueGrey),
                                      tooltip: "Exportar",
                                      onPressed: () => _exportar([p], PerfilArchivo.nombreArchivoPara(p.nombrePerfil)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      tooltip: "Eliminar",
                                      onPressed: () async {
                                        await _eliminarPerfil(p);
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Guardar datos actuales como perfil"),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            _dialogoCrearPerfil();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_open_outlined),
                              label: const Text("Importar"),
                              style: OutlinedButton.styleFrom(foregroundColor: primaryRed),
                              onPressed: () async {
                                await _importar();
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.save_alt),
                              label: const Text("Exportar todos"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.blueGrey),
                              onPressed: _perfiles.isEmpty ? null : () => _exportar(_perfiles, 'perfiles_tiu.upctiu.json'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  // --- LÓGICA DE FOTO Y GUARDADO PRINCIPAL ---
  Future<void> _pickAndSaveImage() async {
    // Se reduce al elegirla: la foto se muestra a 175 dp y así también pesa poco al exportar
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
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
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _perfilDelFormulario());
  }

  Future<void> _borrarDatos() async {
    final ok = await _confirmar(
      'Borrar datos del TIU',
      'El TIU quedará vacío. Tus perfiles guardados no se borran.',
      'Borrar',
    );
    if (ok && mounted) Navigator.pop(context, const Perfil());
  }

  String? _requerido(String? valor) => (valor == null || valor.trim().isEmpty) ? 'Este dato es obligatorio' : null;

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
              child: Form(
                key: _formKey,
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
                                  ? ResizeImage(FileImage(_selectedImage!), width: 260)
                                  : null,
                              child: _selectedImage == null
                                  ? Icon(Icons.person, size: 80, color: Colors.grey[400])
                                  : null,
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
                            validator: _requerido,
                          ),
                          const SizedBox(height: 15),
                          _buildCustomTextField(
                            controller: _codeController,
                            label: "Código de Alumno",
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            validator: _requerido,
                          ),
                          const SizedBox(height: 15),
                          _buildCustomTextField(
                            controller: _idBannerController,
                            label: "ID Banner",
                            icon: Icons.credit_card,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [UpperCaseTextFormatter()],
                            validator: _requerido,
                          ),
                          const SizedBox(height: 15),
                          _buildCustomTextField(
                            controller: _carreraController,
                            label: "Carrera",
                            hint: "Ej. INGENIERÍA DE SOFTWARE",
                            icon: Icons.school_outlined,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [UpperCaseTextFormatter()],
                            validator: _requerido,
                          ),
                          const SizedBox(height: 15),
                          _buildCustomTextField(
                            controller: _campusController,
                            label: "Campus (opcional)",
                            hint: "Ej. Campus San Miguel",
                            icon: Icons.location_on_outlined,
                            textCapitalization: TextCapitalization.words,
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
                              Text("Tamaño del Nombre", style: TextStyle(color: Colors.grey[700])),
                              Text("${_nameSize.toInt()} pt", style: TextStyle(fontWeight: FontWeight.bold, color: primaryRed)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(activeTrackColor: primaryRed, thumbColor: primaryRed, overlayColor: primaryRed.withOpacity(0.2)),
                            child: Slider(value: _nameSize, min: 15.0, max: 50.0, onChanged: (val) => setState(() => _nameSize = val)),
                          ),
                          Center(
                            child: Text(
                              _nameController.text.isEmpty ? "VISTA PREVIA" : _nameController.text.toUpperCase(),
                              style: oswald(color: primaryRed, fontSize: _nameSize, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Tamaño de Descripciones", style: TextStyle(color: Colors.grey[700])),
                              Text("${_descSize.toInt()} pt", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                        child: Text('APLICAR AL TIU VIRTUAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                    if (widget.inicial != null) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Borrar datos del TIU'),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: _borrarDatos,
                      ),
                    ],
                  ],
                ),
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.2),
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
              tooltip: "Perfiles",
              onPressed: _mostrarGestorPerfiles,
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
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF344563))),
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
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: primaryRed, size: 20),
        filled: true, fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryRed, width: 1.5)),
      ),
    );
  }
}
