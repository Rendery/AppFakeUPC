import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTACIÓN NECESARIA PARA LA BARRA DE NAVEGACIÓN
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'vista_tiu.dart';

void main() async {
  // Aseguramos la inicialización de widgets para las fuentes, localización y SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // CONFIGURACIÓN DE BARRA DE NAVEGACIÓN DEL SISTEMA (NAV-BAR) TRANSPARENTE
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, // Barra de navegación transparente
    statusBarColor: Colors.transparent, // Barra de estado transparente si se desea
    systemNavigationBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
    statusBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
  ));

  // Inicializamos el formato de fecha en español
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPC TIU Virtual',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Usamos Poppins como fuente base para un look más moderno y limpio que Oswald
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const VistaTIU(),
    );
  }
}