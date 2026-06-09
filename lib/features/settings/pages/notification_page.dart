import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final _notificationService = NotificationService();
  List<dynamic> _notificationList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifikasiB3();
  }

  Future<void> _fetchNotifikasiB3() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final notifications = await _notificationService.fetchWasteB3Notifications();
      setState(() {
        _notificationList = notifications;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        // Menurunkan posisi ikon kembali
        leading: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Menurunkan posisi teks judul halaman
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            "Peringatan Masa Simpan B3",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(height: 10, width: double.infinity, color: primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!, 
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500), 
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchNotifikasiB3,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      )
                    : _notificationList.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.gpp_good_rounded, size: 64, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aman! Tidak ada limbah B3 yang mendekati batas waktu penyimpanan.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchNotifikasiB3,
                            color: primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: _notificationList.length,
                              itemBuilder: (context, index) {
                                return NotificationCard(data: _notificationList[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}