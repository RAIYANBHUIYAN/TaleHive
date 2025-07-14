import 'package:flutter/material.dart';
import 'package:library_management_app/pages/club/book_club.dart';
import 'package:library_management_app/pages/user/author_dashboard.dart';
import 'package:library_management_app/pages/user/book_details.dart';
import 'package:library_management_app/pages/user/user_dashboard.dart';
import 'package:library_management_app/pages/user/user_home.dart';
import 'package:library_management_app/user_authentication/login.dart';

class myapp extends StatelessWidget {
  const myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,

        home: UserDashboardPage(onMyBooksTap: () {  }, onEditProfileTap: () {  },));
  }
}

void main() {
  runApp(const myapp());
}
