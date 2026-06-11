import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

import '../model/Product.dart';

class ApiService {
  static const String baseUrl =
      'http://10.19.75.224/rest-api/public/api';
  static const String storageUrl =
      'http://10.19.75.224/rest-api/public/storage';

  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    String cleanPath = imagePath;

    // Hapus public/ jika ada
    if (cleanPath.startsWith('public/')) {
      cleanPath = cleanPath.substring(7);
    }

    // Hapus products/products/ berlebih
    while (cleanPath.contains('products/products/')) {
      cleanPath =
          cleanPath.replaceAll('products/products/', 'products/');
    }

    print('Cleaning image path:');
    print('Original: $imagePath');
    print('Cleaned: $cleanPath');

    String base =
        storageUrl.endsWith('/') ? storageUrl : '$storageUrl/';
    String path =
        cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;

    final String finalUrl = base + path;

    print('Final Url: $finalUrl');

    return finalUrl;
  }

  // GET PRODUCTS
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          print(
              'Response adalah List dengan ${decoded.length} item');

          return decoded
              .map((json) => Product.fromJson(json))
              .toList();
        } else if (decoded is Map<String, dynamic>) {
          print(
              'Response adalah Map dengan keys: ${decoded.keys}');

          if (decoded.containsKey('data') &&
              decoded['data'] is List) {
            return (decoded['data'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          } else if (decoded.containsKey('products') &&
              decoded['products'] is List) {
            return (decoded['products'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          } else if (decoded.containsKey('result') &&
              decoded['result'] is List) {
            return (decoded['result'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          } else {
            print(
                'Response adalah object tunggal, membungkus ke dalam list');
            return [Product.fromJson(decoded)];
          }
        } else {
          throw Exception(
              'Format response tidak dikenali: ${decoded.runtimeType}');
        }
      } else if (response.statusCode == 404) {
        throw Exception(
            'Endpoint tidak ditemukan: $baseUrl/products');
      } else {
        throw Exception(
            'Gagal memuat produk: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getProducts: $e');
      throw Exception('Error: $e');
    }
  }

  // GET PRODUCT BY ID
  static Future<Product> getProductById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print(
          'Get Product By ID Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') &&
              decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }

          return Product.fromJson(decoded);
        } else {
          throw Exception(
              'Format response tidak dikenali');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Produk tidak ditemukan');
      } else {
        throw Exception(
            'Gagal memuat produk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // REDUCE STOCK
  static Future<Product> reduceStock(
      int productId, int quantity) async {
    try {
      final response = await http.patch(
        Uri.parse(
            '$baseUrl/products/$productId/reduce-stock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': quantity}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') &&
              decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }

          return Product.fromJson(decoded);
        }

        throw Exception('Format response tidak dikenali');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Stok tidak mencukupi');
      } else {
        throw Exception(
            'Gagal mengurangi stok: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // DELETE PRODUCT
  static Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        throw Exception(
            'Gagal menghapus produk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // CREATE PRODUCT
  static Future<Product> createProduct({
    required String name,
    required String descriptions,
    required int price,
    required int stock,
    Uint8List? imageBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'descriptions': descriptions,
          'price': price,
          'stock': stock,
        }),
      );

      print(
          'Create Product Response Status: ${response.statusCode}');
      print(
          'Create Product Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') &&
              decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }

          return Product.fromJson(decoded);
        }

        throw Exception('Format response tidak dikenali');
      } else {
        try {
          final error = json.decode(response.body);

          throw Exception(
              error['message'] ?? 'Gagal membuat produk');
        } catch (_) {
          throw Exception(
              'Gagal membuat produk: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Create Product Error: $e');
      throw Exception('Error: $e');
    }
  }
    // UPDATE PRODUCT
  static Future<Product> updateProduct({
    required int id,
    String? name,
    String? descriptions,
    int? price,
    int? stock,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/$id'),
      );

      request.fields['_method'] = 'PUT';

      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }

      if (descriptions != null) {
        request.fields['descriptions'] = descriptions;
      }

      if (price != null) {
        request.fields['price'] = price.toString();
      }

      if (stock != null) {
        request.fields['stock'] = stock.toString();
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );
      } else if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename:
                'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final response = await request.send();
      final responseBody =
          await response.stream.bytesToString();

      print(
          'Update Product Response Status: ${response.statusCode}');
      print(
          'Update Product Response Body: $responseBody');

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') &&
              decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }

          return Product.fromJson(decoded);
        }

        throw Exception('Format response tidak dikenali');
      } else {
        try {
          final error = json.decode(responseBody);

          throw Exception(
            error['message'] ?? 'Gagal update produk',
          );
        } catch (e) {
          throw Exception(
            'Gagal update produk: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('Update Product Error: $e');
      throw Exception('Error: $e');
    }
  }

  // DEBUG: Test API Response
  static Future<void> testApiResponse() async {
    try {
      print('Testing API Response...');

      final response = await http
          .get(
            Uri.parse('$baseUrl/products'),
          )
          .timeout(const Duration(seconds: 10));

      print('Status Code: ${response.statusCode}');
      print('Response Type: ${response.runtimeType}');
      print('Response Body: ${response.body}');

      final decoded = json.decode(response.body);

      print('Decoded Type: ${decoded.runtimeType}');

      if (decoded is List) {
        print(
            'Response adalah List dengan ${decoded.length} item');
      } else if (decoded is Map) {
        print(
            'Response adalah Map dengan keys: ${decoded.keys}');

        if (decoded.containsKey('data')) {
          print(
            'Key "data" ditemukan dengan tipe: ${decoded['data'].runtimeType}',
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Upload Image - VERSI BYTES
  static Future<String> uploadImage(
    int productId,
    File imageFile,
  ) async {
    try {
      print('========== UPLOAD DEBUG ==========');
      print('Product ID: $productId');
      print('File path: ${imageFile.path}');

      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final bytes = await imageFile.readAsBytes();
      final fileSize = bytes.length;

      print(
        'File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)',
      );

      if (fileSize > 2 * 1024 * 1024) {
        throw Exception('File terlalu besar (max 2MB)');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/products/$productId/upload-image',
        ),
      );

      request.headers['Accept'] = 'application/json';

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename:
            'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      print('Request URL: ${request.url}');
      print(
          'Request files count: ${request.files.length}');
      print(
          'File name: product_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final response = await request.send();
      final responseBody =
          await response.stream.bytesToString();

      print(
          'Upload Response Status: ${response.statusCode}');
      print('Upload Response Body: $responseBody');

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);

        return decoded['image_url'] ?? '';
      } else {
        throw Exception(
          'Upload gagal: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      print('Upload image error: $e');
      throw Exception('Gagal upload gambar: $e');
    }
  }
}