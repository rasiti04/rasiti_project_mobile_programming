import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pertemuan12/model/Product.dart';
import 'package:pertemuan12/produk/add_product.dart';
import 'package:pertemuan12/produk/detail_product.dart';
import 'package:intl/intl.dart';
import 'package:pertemuan12/service/api_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ApiService.getProducts();

      setState(() {
        _products = products;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> refreshProducts() async {
    setState(() {
      _isRefreshing = true;
    });

    await _fetchProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Menghapus produk...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        await ApiService.deleteProduct(product.id);

        setState(() {
          _products.removeWhere((p) => p.id == product.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil dihapus'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  String formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Color getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }

  String getStockText(int stock) {
    if (stock <= 0) return 'Habis';
    if (stock < 10) return 'Terbatas';
    return 'Tersedia';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Daftar Produk'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchProducts,
            tooltip: 'Refresh',
          ),

          if (_products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_products.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );

          if (result == true) {
            _fetchProducts();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Produk',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat daftar produk...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),

            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah produk',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshProducts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );

          if (result == true) {
            _fetchProducts();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(product),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      formatPrice(product.price),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: getStockColor(
                              product.stock,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory,
                                size: 14,
                                color: getStockColor(product.stock),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${getStockText(product.stock)} : ${product.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: getStockColor(product.stock),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddProductScreen(product: product),
                        ),
                      );

                      if (result == true) {
                        _fetchProducts();
                      }
                    },
                    tooltip: 'Edit produk',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                  const SizedBox(height: 4),

                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                    onPressed: () => _deleteProduct(product),
                    tooltip: 'Hapus produk',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: product.imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,

          placeholder: (context, url) => Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),

          errorWidget: (context, url, error) => Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 30, color: Colors.grey[400]),
                const SizedBox(height: 4),
                Text(
                  'Error',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 35, color: Colors.grey[400]),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
