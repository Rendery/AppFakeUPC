import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fuentes.dart';
import 'vista_configuracion.dart';

class VistaTIU extends StatefulWidget {
  final SharedPreferences prefs;

  const VistaTIU({super.key, required this.prefs});

  @override
  State<VistaTIU> createState() => _VistaTIUState();
}

class _VistaTIUState extends State<VistaTIU> {
  // Variables de estado con valores por defecto
  String _userName = 'EDERY RENZO A*** V***';
  String _userCode = '201822832';
  String _idBanner = 'N01864219';
  double _nameFontSize = 32.0;
  double _descFontSize = 18.0;
  String? _imagePath;
  // Se resuelve una sola vez (no en cada build) para no hacer IO síncrono al dibujar.
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Cargar datos de SharedPreferences (ya vienen cargados desde main, es síncrono)
  void _loadSavedData() {
    final prefs = widget.prefs;
    _userName = prefs.getString('userName') ?? _userName;
    _userCode = prefs.getString('userCode') ?? _userCode;
    _idBanner = prefs.getString('idBanner') ?? _idBanner;
    _nameFontSize = prefs.getDouble('nameFontSize') ?? _nameFontSize;
    _descFontSize = prefs.getDouble('descFontSize') ?? _descFontSize;
    _imagePath = prefs.getString('imagePath');
    _imageFile = _resolverFoto(_imagePath);
  }

  File? _resolverFoto(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  // Guardar datos en SharedPreferences
  Future<void> _saveData() async {
    final prefs = widget.prefs;
    await prefs.setString('userName', _userName);
    await prefs.setString('userCode', _userCode);
    await prefs.setString('idBanner', _idBanner);
    await prefs.setDouble('nameFontSize', _nameFontSize);
    await prefs.setDouble('descFontSize', _descFontSize);

    // CORRECCIÓN: Si es nulo, eliminamos el registro para que de verdad vuelva al de fábrica
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      await prefs.setString('imagePath', _imagePath!);
    } else {
      await prefs.remove('imagePath');
    }
  }

  Future<void> _navigateToConfig() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VistaConfiguracion(
          initialName: _userName,
          initialCode: _userCode,
          initialIdBanner: _idBanner,
          initialNameSize: _nameFontSize,
          initialDescSize: _descFontSize,
          initialImagePath: _imagePath,
        ),
      ),
    );

    // CORRECCIÓN AL RECIBIR LOS DATOS
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _userName = result['name'] ?? _userName;
        _userCode = result['code'] ?? _userCode;
        _idBanner = result['idBanner'] ?? _idBanner;
        _nameFontSize = result['nameSize'] ?? _nameFontSize;
        _descFontSize = result['descSize'] ?? _descFontSize;

        // El problema estaba aquí. Ahora forzamos a que acepte el null si viene en el mapa
        _imagePath = result['imagePath'];
        _imageFile = _resolverFoto(_imagePath);
      });
      _saveData();
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
                        child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFE33E3E), size: 22),
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
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _userName,
                      textAlign: TextAlign.center,
                      style: oswald(
                        fontSize: _nameFontSize,
                        color: const Color(0xFFE33E3E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Código de alumno:", style: TextStyle(color: Color(0xFF6B778C), fontSize: 13)),
                  Text(
                    _userCode,
                    style: TextStyle(fontSize: _descFontSize, fontWeight: FontWeight.bold, color: const Color(0xFF344563)),
                  ),
                  const SizedBox(height: 8),
                  const Text("ID Banner:", style: TextStyle(color: Color(0xFF6B778C), fontSize: 13)),
                  Text(
                    _idBanner,
                    style: TextStyle(fontSize: _descFontSize, fontWeight: FontWeight.bold, color: const Color(0xFF344563)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "INGENIERÍA DE SOFTWARE",
                    style: TextStyle(fontSize: _descFontSize, fontWeight: FontWeight.w800, color: const Color(0xFF344563)),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Color(0xFFE33E3E), size: 19),
                      SizedBox(width: 8),
                      Text(
                        "Campus San Miguel",
                        style: TextStyle(fontSize: 15, color: Color(0xFF6B778C), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
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
                    : Image.asset(
                  'assets/profile_picture.jpg',
                  width: 175,
                  height: 175,
                  cacheWidth: photoCacheSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
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
