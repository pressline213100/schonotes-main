import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'providers/library_provider.dart';
import 'providers/cloud_sync_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => CloudSyncProvider()),
      ],
      child: const NotefulApp(),
    ),
  );
}

class NotefulApp extends StatelessWidget {
  const NotefulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schonotes',
      themeMode: ThemeMode.dark, // Defaulting to sleek dark mode
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF4A00E0), 
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6B11FF), 
        textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F1218),
        cardColor: const Color(0xFF1A1D24),
        dialogBackgroundColor: const Color(0xFF1A1D24),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A1D24),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
