import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/TrangChu.dart';

import 'LoginPage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Shop Admin',
      theme: ThemeData(
        primaryColor: const Color(0xFF0066CC),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


