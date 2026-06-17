// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pertemuan12/produk/add_product.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../model/Product.dart';
import '../service/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  bool _isProcessing = false;
  bool _dateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initializeDateFormat();
  }

  // Method untuk inisialisasi format tanggal
  Future<void> _initializeDateFormat() async {
    try {
      await initializeDateFormatting('id_ID', null);
      if (mounted) {
        setState(() {
          _dateFormatInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing date format: $e');
      if (mounted) {
        setState(() {
          _dateFormatInitialized = true; // Tetap set true meskipun error
        });
      }
    }
  }

  // Method untuk format tanggal dengan aman
  String _formatDate(DateTime date) {
    if (!_dateFormatInitialized) {
      // Fallback format manual jika belum terinisialisasi
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    try {
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      // Fallback jika format gagal
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    }
  }

  Future<void> _refreshProduct() async {
    try {
      final refreshedProduct = await ApiService.getProductById(_product.id);
      if (mounted) {
        setState(() {
          _product = refreshedProduct;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal refresh: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ), // SnackBar
        );
      }
    }
  }

  Future<void> _reduceStock() async {
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Kurangi Stok'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan jumlah produk yang akan dikurangi:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: 5',
                ), // InputDecoration
                keyboardType: TextInputType.number,
                autofocus: true,
              ), // TextField
              const SizedBox(height: 8),
              Text(
                'Stok saat ini: ${_product.stock}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ), // Text
            ],
          ), // Column
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Batal'),
            ), // TextButton
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.pop(dialogContext, value);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan jumlah yang valid'),
                      duration: Duration(seconds: 2),
                    ), // SnackBar
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Kurangi'),
            ), // TextButton
          ],
        ); // AlertDialog
      },
    );

    if (quantity == null || quantity <= 0) return;

    if (_product.stock < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak mencukupi! Tersisa: ${_product.stock}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ), // SnackBar
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final updatedProduct = await ApiService.reduceStock(_product.id, quantity);
      if (mounted) {
        setState(() {
          _product = updatedProduct;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok berhasil dikurangi sebanyak $quantity'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ), // SnackBar
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengurangi stok: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ), // SnackBar
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${_product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ), // TextButton
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ), // TextButton
        ],
      ), // AlertDialog
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ApiService.deleteProduct(_product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ), // SnackBar
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus produk: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ), // SnackBar
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: _product),
      ), // MaterialPageRoute
    );

    if (result == true) {
      await _refreshProduct();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _product.name,
          overflow: TextOverflow.ellipsis,
        ), // Text
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isProcessing ? null : _navigateToEdit,
            tooltip: 'Edit produk',
          ), // IconButton
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isProcessing ? null : _deleteProduct,
            tooltip: 'Hapus produk',
          ), // IconButton
        ],
      ), // AppBar
      body: RefreshIndicator(
        onRefresh: _refreshProduct,
        child: _isProcessing || !_dateFormatInitialized
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(),
                    _buildProductInfo(),
                  ],
                ), // Column
              ), // SingleChildScrollView
      ), // RefreshIndicator
    ); // Scaffold
  }

  Widget _buildProductImage() {
    final imageUrl = _product.imageUrl;

    print('----------- DEBUG GAMBAR -----------');
    print('Path di DB: ${_product.image}');
    print('URL yang digunakan: $imageUrl');
    print('====================================');

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Hero(
        tag: 'product_image_${_product.id}',
        child: SizedBox(
          height: 300,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Memuat gambar...'),
                  ],
                ), // Column
              ), // Center
            ), // Container
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.grey[600]),
                  ), // Text
                  const SizedBox(height: 4),
                  Text(
                    'Path: ${_product.image ?? 'null'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ), // Text
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Coba Lagi'),
                  ), // ElevatedButton
                ],
              ), // Column
            ), // Container
          ), // CachedNetworkImage
        ), // SizedBox
      ); // Hero
    } else {
      return Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada gambar',
              style: TextStyle(color: Colors.grey[600]),
            ), // Text
            if (_product.image != null && _product.image!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Path: ${_product.image}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ), // Text
              ), // Padding
          ],
        ), // Column
      ); // Container
    }
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ), // Text
          const SizedBox(height: 8),
          Text(
            _product.formattedPrice,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ), // Text
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _product.stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _product.stockColor),
            ), // BoxDecoration
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory,
                  color: _product.stockColor,
                  size: 20,
                ), // Icon
                const SizedBox(width: 8),
                Text(
                  '${_product.stockStatus} (${_product.stock} pcs)',
                  style: TextStyle(
                    color: _product.stockColor,
                    fontWeight: FontWeight.w500,
                  ),
                ), // Text
              ],
            ), // Row
          ), // Container
          const SizedBox(height: 24),
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ), // Text
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ), // BoxDecoration
            child: Text(
              (_product.descriptions ?? '').isNotEmpty
                  ? _product.descriptions!
                  : 'Tidak ada deskripsi',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ), // Text
          ), // Container
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // RoundedRectangleBorder
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.code,
                    'ID Produk',
                    '#${_product.id}',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.access_time,
                    'Dibuat',
                    _formatDate(_product.createdAt),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.update,
                    'Diperbarui',
                    _formatDate(_product.updatedAt),
                  ),
                ],
              ), // Column
            ), // Padding
          ), // Card
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _product.stock > 0 ? _reduceStock : null,
                  icon: const Icon(Icons.remove_shopping_cart),
                  label: const Text('Kurangi Stok'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ), // RoundedRectangleBorder
                  ),
                ), // ElevatedButton.icon
              ), // Expanded
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToEdit,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Tambah Gambar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ), // RoundedRectangleBorder
                  ),
                ), // OutlinedButton.icon
              ), // Expanded
            ],
          ), // Row
        ],
      ), // Column
    ); // Padding
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ), // Text
          ), // SizedBox
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ), // Text
          ), // Expanded
        ],
      ), // Row
    ); // Padding
  }
}