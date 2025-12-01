import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HIS System',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        useMaterial3: true,
        fontFamily: 'Arial'
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, 
        GlobalWidgetsLocalizations.delegate, 
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [Locale('ar', 'AE')], 
      locale: const Locale('ar', 'AE'),
      home: const LoginScreen(),
    );
  }
}
