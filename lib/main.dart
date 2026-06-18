import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/inventario_provider.dart';
import 'router/app_router.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChinaBusinessApp());
}

class ChinaBusinessApp extends StatelessWidget {
  const ChinaBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..inicializarParaPruebas(),
        ),
        ChangeNotifierProvider(
          create: (_) => InventarioProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appNombre,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.rojo,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.rojo,
            foregroundColor: AppColors.blanco,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rojo,
              foregroundColor: AppColors.blanco,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.rojo,
                width: 2,
              ),
            ),
          ),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}