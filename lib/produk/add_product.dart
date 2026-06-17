// lib/screens/add_product_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pertemuan12/service/api_service.dart';
import 'package:pertemuan12/model/Product.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  File? imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _isImageChanged = false; // Track jika gambar diubah
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.descriptions;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            imageFile = null;
            _isImageChanged = true;
          });
        } else {
          setState(() {
            imageFile = File(image.path);
            _webImageBytes = null;
            _isImageChanged = true;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', Colors.red);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            imageFile = null;
            _isImageChanged = true;
          });
        } else {
          setState(() {
            imageFile = File(image.path);
            _webImageBytes = null;
            _isImageChanged = true;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e', Colors.red);
    }
  }

  void _removeImage() {
    setState(() {
      imageFile = null;
      _webImageBytes = null;
      _isImageChanged = true;
    });
  }

  // Preview image widget yang lebih baik
  Widget _buildImagePreview() {
    // Gambar baru yang dipilih (Web)
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Gambar baru yang dipilih (Mobile)
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Gambar lama dari server (saat edit)
    if (!_isImageChanged && widget.product?.imageUrl != null && widget.product!.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.product!.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ), // CircularProgressIndicator
          ); // Center
        },
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey)),
            ],
          ); // Column
        },
      ); // Image.network
    }

    // Placeholder jika tidak ada gambar
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Tap untuk pilih gambar',
          style: TextStyle(color: Colors.grey[600]),
        ), // Text
        const SizedBox(height: 4),
        Text(
          'Format: JPG, PNG',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ), // Text
      ],
    ); // Column
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ), // RoundedRectangleBorder
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ), // BoxDecoration
            ), // Container
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ), // ListTile
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ), // ListTile
            if (imageFile != null || _webImageBytes != null || (widget.product?.imageUrl != null && !_isImageChanged))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ), // ListTile
            const SizedBox(height: 8),
          ],
        ), // Column
      ), // SafeArea
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ), // SnackBar
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int price = int.parse(_priceController.text);
      final int stock = int.parse(_stockController.text);
      final String descriptions = _descriptionController.text.trim().isEmpty
          ? '-'
          : _descriptionController.text.trim();

      if (widget.product == null) {
        // 1. Create produk dulu (tanpa gambar)
        final newProduct = await ApiService.createProduct(
          name: _nameController.text.trim(),
          descriptions: descriptions,
          price: price,
          stock: stock,
        );

        // 2. Jika ada gambar, upload setelah produk terbuat
        if (imageFile != null) {
          await ApiService.uploadImage(newProduct.id, imageFile!);
        } else if (_webImageBytes != null && kIsWeb) {
          // Handle web image
          // Convert Uint8List ke File terlebih dahulu
        }

        if (mounted) {
          _showSnackBar('Produk berhasil ditambahkan', Colors.green);
          Navigator.pop(context, true);
        }
      } else {
        // UPDATE - Update produk existing
        await ApiService.updateProduct(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          descriptions: descriptions,
          price: price,
          stock: stock,
        );

        // Upload gambar baru jika ada
        if (_isImageChanged && imageFile != null) {
          await ApiService.uploadImage(widget.product!.id, imageFile!);
        }

        if (mounted) {
          _showSnackBar('Produk berhasil diperbarui', Colors.green);
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menyimpan produk: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ), // SizedBox
            ), // Padding
        ],
      ), // AppBar
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pilihan Gambar
                  GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ), // BoxDecoration
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildImagePreview(),
                            // Overlay icon edit di pojok kanan atas
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ), // BoxDecoration
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ), // Icon
                                ), // Padding
                              ), // Container
                            ), // Positioned
                          ],
                        ), // Stack
                      ), // ClipRRect
                    ), // Container
                  ), // GestureDetector
                  const SizedBox(height: 16),

                  // Nama Produk
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                      hintText: 'Contoh: Baju Batik Modern',
                    ), // InputDecoration
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama produk tidak boleh kosong';
                      }
                      if (value.length < 3) {
                        return 'Nama produk minimal 3 karakter';
                      }
                      return null;
                    },
                  ), // TextFormField
                  const SizedBox(height: 16),

                  // Deskripsi
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Deskripsi produk (opsional)',
                      alignLabelWithHint: true,
                    ), // InputDecoration
                    maxLines: 3,
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return Text(
                        '$currentLength/$maxLength',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ); // Text
                    },
                  ), // TextFormField
                  const SizedBox(height: 8),

                  // Harga
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'Rp ',
                      hintText: 'Contoh: 50000',
                    ), // InputDecoration
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga tidak boleh kosong';
                      }
                      final price = int.tryParse(value);
                      if (price == null) {
                        return 'Masukkan angka yang valid';
                      }
                      if (price < 0) {
                        return 'Harga tidak boleh negatif';
                      }
                      if (price == 0) {
                        return 'Harga tidak boleh 0';
                      }
                      return null;
                    },
                  ), // TextFormField
                  const SizedBox(height: 16),

                  // Stok
                  TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stok *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                      hintText: 'Contoh: 100',
                    ), // InputDecoration
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Stok tidak boleh kosong';
                      }
                      final stock = int.tryParse(value);
                      if (stock == null) {
                        return 'Masukkan angka yang valid';
                      }
                      if (stock < 0) {
                        return 'Stok tidak boleh negatif';
                      }
                      return null;
                    },
                  ), // TextFormField
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ), // RoundedRectangleBorder
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.product == null ? Icons.save : Icons.update),
                        const SizedBox(width: 8),
                        Text(
                          widget.product == null ? 'Simpan Produk' : 'Update Produk',
                          style: const TextStyle(fontSize: 16),
                        ), // Text
                      ],
                    ), // Row
                  ), // ElevatedButton
                  const SizedBox(height: 16),

                  // Informasi tambahan
                  if (widget.product != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ), // BoxDecoration
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Biarkan gambar kosong jika tidak ingin mengubah gambar',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                            ), // Text
                          ), // Expanded
                        ],
                      ), // Row
                    ), // Container
                ],
              ), // ListView
            ), // Form
    ); // Scaffold
  }
}