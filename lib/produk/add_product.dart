import 'package:flutter/material.dart';
import '../model/Product.dart';

class AddProductScreen extends StatelessWidget {
  final Product? product;

  const AddProductScreen({
    super.key,
    this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          product == null
              ? 'Tambah Produk'
              : 'Edit Produk',
        ),
      ),
      body: const Center(
        child: Text('Halaman Add Product'),
      ),
    );
  }
}