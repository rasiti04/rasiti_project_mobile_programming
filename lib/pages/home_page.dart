import 'package:flutter/material.dart';
import 'package:pertemuan12/produk/list_product.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage2> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ProductListScreen());
  }
}
