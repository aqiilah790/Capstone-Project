import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Transaksi extends StatefulWidget {
  final VoidCallback? onSelesai;
  const Transaksi({super.key, this.onSelesai});

  @override
  State<Transaksi> createState() => _TransaksiState();
}

class _TransaksiState extends State<Transaksi> {
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  DateTime? _tanggalTransaksi;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  int? _selectedKategoriId;
  bool _isLoading = false;

  List<Map<String, dynamic>> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    fetchKategori();
  }

  Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchKategori() async {
    final token = await ambilToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.3.2:1212/api/kategori'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _kategoriList = data.cast<Map<String, dynamic>>();
      });
    } else {
      print('Gagal mengambil kategori');
    }
  }

  Future<void> _submitTransaksi() async {
    final jumlah = _jumlahController.text;
    final keterangan = _keteranganController.text;
    final tanggal = _tanggalTransaksi;
    final kategoriId = _selectedKategoriId;

    if (jumlah.isEmpty || tanggal == null || kategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }

    final token = await ambilToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.3.2:1212/api/transaksi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_kategori': kategoriId,
          'jumlah': jumlah,
          'tanggal_transaksi': tanggal.toIso8601String(),
          'keterangan': keterangan,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
        );
        _jumlahController.clear();
        _keteranganController.clear();
        setState(() {
          _selectedKategoriId = null;
          _tanggalTransaksi = null;
          widget.onSelesai?.call(); 
          Navigator.pop(context); // Kembali ke dashboard
        });
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${data['message'] ?? 'Error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _tanggalTransaksi = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              value: _selectedKategoriId,
              items: _kategoriList.map((kategori) {
                return DropdownMenuItem<int>(
                  value: kategori['id_kategori'],
                  child: Text(kategori['nama_kategori']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedKategoriId = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_tanggalTransaksi != null
                  ? 'Tanggal: ${formatter.format(_tanggalTransaksi!)}'
                  : 'Pilih Tanggal Transaksi'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keteranganController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitTransaksi,
              icon: const Icon(Icons.save),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Transaksi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
