import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:capstone_project/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.3.2:1212/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userData = data;
        _namaController.text = data['nama'];
        _emailController.text = data['email'];
        _noHpController.text = data['no_hp'];
      });
    } else {
      print('Gagal mengambil profil');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout")),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('http://10.0.3.2:1212/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama': _namaController.text,
          'email': _emailController.text,
          'no_hp': _noHpController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => isEditing = false);
        fetchProfile(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui profil')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => isEditing = !isEditing),
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Icon(Icons.person, size: 100, color: Colors.teal),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _namaController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Email tidak valid'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _noHpController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(labelText: 'Nomor HP'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nomor HP wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Tanggal daftar
                    TextFormField(
                      readOnly: true,
                      decoration:
                          const InputDecoration(labelText: 'Tanggal Daftar'),
                      initialValue: userData!['tanggal_daftar'] != null
                          ? formatter.format(
                              DateTime.parse(userData!['tanggal_daftar']))
                          : '-',
                    ),
                    const SizedBox(height: 32),

                    if (isEditing)
                      ElevatedButton(
                        onPressed: _submitUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Simpan Perubahan'),
                      ),

                    if (!isEditing)
                      ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
