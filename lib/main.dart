import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talehive/pages/user/author_dashboard.dart';
import 'package:talehive/pages/user/user_home.dart';

// Import main pages
import 'pages/main_home_page/main_page.dart';
import 'user_authentication/login.dart';
import 'admin_authentication/admin_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables or use hardcoded values
    try {
      await dotenv.load(fileName: ".env");
      print('✅ Environment loaded from .env');
    } catch (e) {
      print('⚠️ No .env file found, using hardcoded values');
    }
    
    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL', // Replace if needed
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY', // Replace if needed
    );
    print('✅ Supabase initialized');
    
  } catch (e) {
    print('❌ Initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaaleHive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/user_home': (context) => const UserHomePage(),
        '/author_dashboard': (context) => const AuthorDashboardPage(),
      },
    );
  }
}
