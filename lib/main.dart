import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:talehive/pages/admin/admin_dashboard.dart';
import 'package:talehive/pages/admin/books/books_and_club_management.dart';
import 'package:talehive/pages/admin/catalog/all_users_books_reqst_Catalog_management.dart';
import 'package:talehive/pages/admin/users/user_management.dart';
import 'package:talehive/pages/club/book_club.dart';
import 'package:talehive/pages/user/author_dashboard.dart';
import 'package:talehive/pages/user/book_details.dart';
import 'package:talehive/pages/user/user_books.dart';
import 'package:talehive/pages/user/user_dashboard.dart';
import 'package:talehive/pages/user/user_home.dart';
import 'package:talehive/user_authentication/login.dart';

import 'admin_authentication/admin_login.dart';



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaleHive',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Login(), // Start with login page
      routes: {
        '/login': (context) => const Login(),

        '/user-home': (context) => const UserHomePage(),

      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
