import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import './screens/details_screen.dart';
import './screens/favorites_screen.dart';
import './screens/posts_screen.dart';
import './screens/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('favoritesBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manhwa Threads',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          brightness: Brightness.light,
        ).copyWith(primary: kPrimary, onPrimary: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
          color: Color(0xFFEEEEEE),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kPrimary),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: kPrimary,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PostsScreen(),
        '/details': (context) => const DetailsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}
