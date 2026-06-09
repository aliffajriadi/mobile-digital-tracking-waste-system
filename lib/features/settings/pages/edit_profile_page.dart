import 'package:flutter/material.dart';
import 'package:mobile/features/settings/services/profile_service.dart';
import 'package:mobile/features/settings/widgets/profile_header.dart';
import 'package:mobile/features/settings/widgets/profile_input_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileService = ProfileService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _userNik = '...';
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    // Supaya widget Header mendengarkan update teks nama secara real-time
    _nameController.addListener(() => setState(() {}));
  }

  void _fetchProfileData() async {
    final localData = await _profileService.getLocalProfile();
    setState(() {
      _nameController.text = localData['name'] ?? '';
      _emailController.text = localData['email'] ?? '';
      _phoneController.text = localData['phone'] ?? '';
      _userNik = localData['nik'] ?? '-';
      _profileImageUrl = localData['image'];
      _isLoading = false;
    });
  }

  void _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Nama dan Email tidak boleh kosong!', Colors.redAccent);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF14A38B)),
      ),
    );

    try {
      await _profileService.updateRemoteProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );

      if (mounted) Navigator.pop(context); // Tutup loading dialog
      _showSnackBar('Profil berhasil diperbarui!', Colors.green);
      if (mounted) Navigator.pop(context); // Kembali ke halaman sebelumnya
    } catch (errorMessage) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        _showSnackBar(errorMessage.toString(), Colors.redAccent);
      }
    }
  }

  void _handlePhotoUploadSimulation() {
    setState(() {
      _profileImageUrl = "https://avatar.iran.liara.run/public/30";
    });
    _showSnackBar('Simulasi: Foto profil berhasil diperbarui!', const Color(0xFF14A38B));
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const bgLightColor = Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 14.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
    
        title: Padding(
          padding: const EdgeInsets.only(top: 14.0),
          child: Text(
            'Profil Saya',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(height: 40, width: double.infinity, color: primaryColor),
                  
                  // Komponen Header Hasil Pemisahan Widget
                  ProfileHeader(
                    name: _nameController.text,
                    nik: _userNik,
                    imageUrl: _profileImageUrl,
                    onPhotoTap: _handlePhotoUploadSimulation,
                  ),

                  // Kontainer Form Utama Berbentuk Card Melengkung
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileInputField(
                            label: "NAMA LENGKAP",
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          ProfileInputField(
                            label: "ALAMAT EMAIL",
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          ProfileInputField(
                            label: "NOMOR HANDPHONE",
                            controller: _phoneController,
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}