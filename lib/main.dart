import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_ui/screens/auth/auth_gate.dart';
import 'package:flutter_chat_ui/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat UI',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        final scale = (width / 390.0).clamp(0.85, 1.0);
        final scaledChild = Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: child ?? const SizedBox.shrink(),
        );
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: scaledChild,
        );
      },
      theme: ThemeData(
        primaryColor: Colors.red,
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFFEF9EB)),
      ),
      home: const AuthGate(),
    );
  }
}
