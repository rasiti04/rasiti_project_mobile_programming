import 'package:flutter/material.dart';
import 'produk/list_product.dart';
import 'pages/map_page.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),

      home: const MainNavigation(),
    );
  }
}

// --- WIDGET NAVIGASI UTAMA ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Index halaman yang aktif (0 untuk Produk, 1 untuk Map)
  int _currentIndex = 1;

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _pages = [
    const ProductListScreen(),
    const MapDirectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan berubah otomatis sesuai index yang dipilih
      body: _pages[_currentIndex],

      // Membuat bar navigasi di bagian bawah layar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Mengubah halaman saat icon diklik
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produk',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
