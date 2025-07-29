import 'package:flutter/material.dart';
import 'pages/club/book_club.dart';
import 'pages/user/author_dashboard.dart';
import 'pages/user/book_details.dart';
import 'pages/user/user_dashboard.dart';
import 'pages/user/user_home.dart';
import 'user_authentication/login.dart';

class myapp extends StatelessWidget {
  const myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,

        home: BookClubPage(),
    );
  }
}

void main() {
  runApp(const myapp());
}
