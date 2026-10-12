import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './app_config.dart';
import './app_palette.dart';
import './screens/details_screen.dart';
import './screens/discover_screen.dart';
import './screens/favorites_screen.dart';
import './screens/posts_screen.dart';
import './screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(favoritesBoxName);
  await Hive.openBox(recommendationsBoxName);
  await Hive.openBox(settingsBoxName);
  _seedRecommendations();
  runApp(const MyApp());
}

void _seedRecommendations() {
  final box = Hive.box(recommendationsBoxName);
  if (box.isNotEmpty) return;
  const stories = [
    {'title': 'The Wave', 'genre': 'Fantasy', 'author': 'mira.draws', 'body': 'A quiet lighthouse keeper hears a voice in the tide. A beautiful, slow-burn fantasy with incredible colors.', 'cover': 0, 'likes': 280, 'comments': [{'author': '@inkandtea', 'text': 'The colors in this one are unreal!'}]},
    {'title': 'Body Rental', 'genre': 'Thriller', 'author': 'panelhopper', 'body': 'A body-swapping mystery that keeps changing what you think you know. The final panel of chapter one!', 'cover': 1, 'likes': 194, 'comments': [{'author': '@mira.draws', 'text': 'That chapter one twist got me too.'}]},
    {'title': 'Something About You', 'genre': 'Romance', 'author': 'hana_reads', 'body': 'Two strangers share a notebook on the train. Soft art, warm characters, and a very sweet slow burn.', 'cover': 2, 'likes': 156, 'comments': []},
    {'title': 'Moonlit Contract', 'genre': 'Fantasy', 'author': 'inkandtea', 'body': 'A runaway princess signs a deal with the moon’s last guardian. Great world-building and a strong heroine.', 'cover': 3, 'likes': 121, 'comments': []},
  ];
  for (var i = 0; i < stories.length; i++) {
    box.put(i + 1, {...stories[i], 'id': i + 1, 'createdAt': DateTime.now().millisecondsSinceEpoch - i * 3600000});
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const blue = Color(0xFF1267C9);
  static const darkBlue = Color(0xFF084699);
  static const pink = Color(0xFFFF6D91);
  static const accent = pink;
  static const ink = Color(0xFF202433);

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF111722) : const Color(0xFFF4F7FB);
    final surface = isDark ? const Color(0xFF1B2432) : Colors.white;
    final foreground = isDark ? const Color(0xFFF3F5FA) : ink;
    final outline = isDark ? const Color(0xFF303B4A) : const Color(0xFFE7ECF3);
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
      primary: isDark ? const Color(0xFF73AEFF) : blue,
      secondary: pink,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: foreground, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -0.6),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(bodyColor: foreground, displayColor: foreground),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: outline)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: isDark ? const Color(0xFF9AA8BA) : const Color(0xFF8994A4)),
        prefixIconColor: isDark ? const Color(0xFF9AA8BA) : const Color(0xFF8994A4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: isDark ? const Color(0xFF0B1A2D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      )),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box(settingsBoxName);
    return ValueListenableBuilder(
      valueListenable: settings.listenable(keys: const ['darkMode']),
      builder: (context, Box settings, _) {
        final dark = settings.get('darkMode', defaultValue: false) as bool;
        return MaterialApp(
          title: 'Manhwa Threads',
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const PostsScreen(),
            '/details': (context) => const PostDetailsScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/discover': (context) => const DiscoverScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}






