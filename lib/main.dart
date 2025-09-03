import 'package:chw_tb/config/router.dart';
import 'package:chw_tb/controllers/providers/app_providers.dart';
import 'package:chw_tb/controllers/services/auth_gate.dart';
import 'package:chw_tb/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // run `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: AppRouter.navigatorKey,
        initialRoute: '/', // 👈 set splash as default
        onGenerateRoute: AppRouter.generateRoute, // 👈 use our custom router
        theme: MadadgarTheme.lightTheme,
        // darkTheme: MadadgarTheme.darkTheme,
        // themeMode: ThemeMode.system,
        builder: (context, child) {
          return AuthGate(child: child ?? const SizedBox());
        },
      ),
    );
  }
}
