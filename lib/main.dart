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

import 'admin_authentication/admin_login.dart';



class myapp extends StatelessWidget {
  const myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,

        home: AdminDashboardPage() ,);
  }
}

void main() {
  runApp(const myapp());
}
