import 'package:flutter/material.dart';
import 'produk/list_product.dart';       // Import halaman daftar produk kamu
import 'service/api_service.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manajemen Produk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProductListScreen(),
    );
  }
}