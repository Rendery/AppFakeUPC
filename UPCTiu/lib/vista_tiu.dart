import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fuentes.dart';
import 'perfil.dart';
import 'vista_configuracion.dart';

class VistaTIU extends StatefulWidget {
  final SharedPreferences prefs;

  const VistaTIU({super.key, required this.prefs});

  @override
  State<VistaTIU> createState() => _VistaTIUState();
}

class _VistaTIUState extends State<VistaTIU> {
  static const Color _rojo = Color(0xFFE33E3E);
  static const Color _textoOscuro = Color(0xFF344563);
  static const Color _textoGris = Color(0xFF6B778C);

  // null = la app todavía no tiene datos (recién instalada o después de borrarlos)
  Perfil? _perfil;
  // Se resuelve una sola vez (no en cada build) para no hacer IO síncrono al dibujar.
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // Las preferencias ya vienen cargadas desde main, así que esto es síncrono
    _perfil = PerfilStore.leerActual(widget.prefs);
    _imageFile = _resolverFoto(_perfil?.imagePath);
  }

  File? _resolverFoto(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  void _aplicarPerfil(Perfil? perfil) {
    setState(() {
      _perfil = perfil;
      _imageFile = _resolverFoto(perfil?.imagePath);
    });
    PerfilStore.guardarActual(widget.prefs, perfil);
  }

  Future<void> _navigateToConfig() async {
    final result = await Navigator.push<Perfil>(
      context,
      MaterialPageRoute(
        builder: (context) => VistaConfiguracion(prefs: widget.prefs, inicial: _perfil),
      ),
    );
    if (result == null) return; // Cerró sin aplicar
    _aplicarPerfil(result.estaVacio ? null : result);
  }

  // Importa un archivo de perfiles: se guardan todos y el primero pasa a ser el TIU actual
  Future<void> _importarPerfil() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final importados = await PerfilArchivo.importar();
      if (importados == null || !mounted) return;
      final guardados = PerfilStore.leerGuardados(widget.prefs)..addAll(importados);
      await PerfilStore.guardarGuardados(widget.prefs, guardados);
      _aplicarPerfil(importados.first);
      messenger.showSnackBar(SnackBar(
        content: Text(importados.length == 1
            ? 'Perfil "${importados.first.nombrePerfil}" importado'
            : 'Se importaron ${importados.length} perfiles'),
        backgroundColor: Colors.green,
      ));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final photoTopPosition = screenHeight * 0.38;
    // Decodificamos la foto al tamaño en que se muestra (175 dp), no a resolución completa:
    // una foto de galería de 12 MP tardaba muchísimo en decodificarse al abrir.
    final photoCacheSize = (175 * dpr).round();
    final perfil = _perfil;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: Stack(
        children: [
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/arbolito.png',
                height: 350,
                cacheHeight: (350 * dpr).round(),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const _NubesAnimadas(),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _navigateToConfig,
                        child: const Icon(Icons.arrow_back_ios_new, color: _rojo, size: 22),
                      ),
                      const SizedBox(width: 25),
                      Text(
                        'TIU VIRTUAL',
                        style: oswald(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.black.withOpacity(0.09),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 135,
            left: 0,
            right: 0,
            child: _RelojTIU(),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: perfil == null ? _buildSinDatos() : _buildDatos(perfil),
            ),
          ),
          Positioned(
            top: photoTopPosition,
            left: 0,
            right: 0,
            child: Center(
              child: ClipOval(
                child: _imageFile != null
                    ? Image.file(
                  _imageFile!,
                  width: 175,
                  height: 175,
                  cacheWidth: photoCacheSize,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 175,
                  height: 175,
                  color: const Color(0xFFE9ECF1),
                  child: const Icon(Icons.person, size: 110, color: Color(0xFFB7BFCC)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatos(Perfil perfil) {
    final descStyle = TextStyle(fontSize: perfil.descSize, fontWeight: FontWeight.bold, color: _textoOscuro);
    return Column(
      children: [
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            perfil.nombre,
            textAlign: TextAlign.center,
            style: oswald(
              fontSize: perfil.nameSize,
              color: _rojo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text("Código de alumno:", style: TextStyle(color: _textoGris, fontSize: 13)),
        Text(perfil.codigo, style: descStyle),
        const SizedBox(height: 8),
        const Text("ID Banner:", style: TextStyle(color: _textoGris, fontSize: 13)),
        Text(perfil.idBanner, style: descStyle),
        const SizedBox(height: 18),
        Text(
          perfil.carrera,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: perfil.descSize, fontWeight: FontWeight.w800, color: _textoOscuro),
        ),
        if (perfil.campus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: _rojo, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  perfil.campus,
                  style: const TextStyle(fontSize: 15, color: _textoGris, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Estado inicial de la APK: sin datos, esperando que el usuario los ingrese o importe
  Widget _buildSinDatos() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'TU TIU ESTÁ VACÍO',
          textAlign: TextAlign.center,
          style: oswald(fontSize: 26, color: _rojo, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ingresa tu nombre, foto, código, ID Banner y carrera, o importa un perfil que hayas guardado.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _textoGris),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Ingresar datos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _rojo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _navigateToConfig,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Importar perfil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _rojo,
              side: const BorderSide(color: _rojo),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _importarPerfil,
          ),
        ),
      ],
    );
  }
}

// --- RELOJ: solo este widget se redibuja cada segundo, no toda la pantalla ---
class _RelojTIU extends StatefulWidget {
  const _RelojTIU();

  @override
  State<_RelojTIU> createState() => _RelojTIUState();
}

class _RelojTIUState extends State<_RelojTIU> {
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  final DateFormat _dateFormat = DateFormat('EEEE, d MMM. yyyy', 'es_ES');
  // Roboto es la fuente del sistema en Android: no hace falta empaquetarla.
  static const TextStyle _timeStyle =
      TextStyle(fontFamily: 'Roboto', fontSize: 42, fontWeight: FontWeight.w400, color: Colors.black);

  late final Timer _timer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final time = _timeFormat.format(now);
    final date = _dateFormat.format(now);
    if (!mounted || (time == _currentTime && date == _currentDate)) return;
    setState(() {
      _currentTime = time;
      _currentDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E3FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_currentTime, style: _timeStyle),
        ),
        const SizedBox(height: 15),
        Text(
          _currentDate,
          style: const TextStyle(fontSize: 17, color: Color(0xFF5C6B82), fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

// --- NUBES: animación por Ticker (sincronizada con la pantalla) y aislada en su propia capa ---
class _NubesAnimadas extends StatefulWidget {
  const _NubesAnimadas();

  @override
  State<_NubesAnimadas> createState() => _NubesAnimadasState();
}

class _NubesAnimadasState extends State<_NubesAnimadas> with SingleTickerProviderStateMixin {
  static const double _cloudBaseSize = 50.0;
  static const double _cloudSizeVariation = 6.0;
  static const double _cloudSpawnYBase = 350.0;
  static const double _cloudSpawnYVariation = 40.0;
  static const int _cloudCount = 6;

  final List<double> _startX = List.generate(_cloudCount, (_) => Random().nextDouble() * 380);
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Las nubes salen por la izquierda en -130 y reaparecen a la derecha en width + 100.
    final span = width + 230;

    // Las imágenes no cambian: se construyen una vez y solo se desplazan.
    final clouds = List.generate(_cloudCount, (index) {
      final cloudWidth = _cloudBaseSize + (index * _cloudSizeVariation);
      return Opacity(
        opacity: 0.4,
        child: Image.asset(
          'assets/cloud.png',
          width: cloudWidth,
          cacheWidth: (cloudWidth * dpr).round(),
        ),
      );
    });

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _seconds,
            builder: (context, seconds, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < _cloudCount; i++)
                    Positioned(
                      top: _cloudSpawnYBase + (i * _cloudSpawnYVariation),
                      left: _posicionX(i, seconds, span),
                      child: clouds[i],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Misma velocidad que antes: (0.6 + i % 2) px cada 50 ms = 12 o 32 px/s.
  double _posicionX(int i, double seconds, double span) {
    final speed = (0.6 + (i % 2)) * 20;
    final x = (_startX[i] + 130 - speed * seconds) % span;
    return x - 130;
  }
}
