import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTACIÓN NECESARIA PARA LA BARRA DE NAVEGACIÓN
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vista_tiu.dart';

void main() async {
  // Aseguramos la inicialización de widgets para las fuentes, localización y SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // Las fuentes van empaquetadas en assets/google_fonts: nunca descargar en tiempo de ejecución.
  GoogleFonts.config.allowRuntimeFetching = false;

  // CONFIGURACIÓN DE BARRA DE NAVEGACIÓN DEL SISTEMA (NAV-BAR) TRANSPARENTE
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, // Barra de navegación transparente
    statusBarColor: Colors.transparent, // Barra de estado transparente si se desea
    systemNavigationBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
    statusBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
  ));

  // Formato de fecha en español y preferencias en paralelo: así la primera
  // pantalla ya sale con los datos guardados y sin parpadeo de valores por defecto.
  final results = await Future.wait([
    initializeDateFormatting('es_ES', null),
    SharedPreferences.getInstance(),
  ]);
  runApp(MyApp(prefs: results[1] as SharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  // Se construye una sola vez: GoogleFonts.poppinsTextTheme() genera 15 estilos
  // y cada uno dispara una resolución de fuente, así que no debe repetirse en cada build.
  static final ThemeData _theme = ThemeData(
    useMaterial3: true,
    // Usamos Poppins como fuente base para un look más moderno y limpio que Oswald
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPC TIU Virtual',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: VistaTIU(prefs: prefs),
    );
  }
}
