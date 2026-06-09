import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart'; // Sesuaikan path constants projectmu
import 'package:mobile/core/widgets/ruler_picker_modal.dart';

class FormInputOlahanPage extends StatefulWidget {
  final Map<String, dynamic> selectedOlahan; // Menerima data olahan dari halaman sebelumnya

  const FormInputOlahanPage({super.key, required this.selectedOlahan});

  @override
  State<FormInputOlahanPage> createState() => _FormInputOlahanPageState();
}

class _FormInputOlahanPageState extends State<FormInputOlahanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _kuantitasController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  DateTime _waktuTerpilih = DateTime.now();
  bool _isSaving = false;

  double _sliderKuantitasValue = 0.0;
  double _sliderBahanValue = 0.0;

  // Variabel Fitur Dropdown Jenis Sampah Dinamis
  List<dynamic> _subcategoriesList = [];
  String? _selectedSubcategoryName;
  int? _selectedSubcategoryId;
  bool _isLoadingSubcategories = true;

  List<Map<String, dynamic>> _daftarItemSampah = [];

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
  }

  // --- AMBIL DATA SUBKATEGORI UNTUK DROPDOWN ---
  Future<void> _fetchSubcategories() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/waste-subcategories'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data is Map && data.containsKey('data')) {
            _subcategoriesList = data['data'] ?? [];
          } else if (data is List) {
            _subcategoriesList = data;
          } 
          _isLoadingSubcategories = false;
        });
      } else {
        setState(() => _isLoadingSubcategories = false);
      }
    } catch (e) {
      setState(() => _isLoadingSubcategories = false);
    }
  }

  // --- FUNGSI TANGGAL & WAKTU ---
  Future<void> _pilihWaktu(BuildContext context) async {
    final DateTime? tanggalPicked = await showDatePicker(
      context: context,
      initialDate: _waktuTerpilih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (tanggalPicked != null) {
      final TimeOfDay? waktuPicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_waktuTerpilih),
      );
      if (waktuPicked != null) {
        setState(() {
          _waktuTerpilih = DateTime(
            tanggalPicked.year,
            tanggalPicked.month,
            tanggalPicked.day,
            waktuPicked.hour,
            waktuPicked.minute,
          );
        });
      }
    }
  }

  // --- FUNGSI KIRIM DATA (POST) KE LARAVEL ---
  Future<void> _simpanDataOlahan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 1. Ambil token login PIC dari Shared Preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 2. Siapkan Endpoint URL (Gunakan variabel global)
      var url = Uri.parse('${ApiConstants.baseUrl}/processed-waste-data');

      String kuantitas = _kuantitasController.text.replaceAll(',', '.');

      // 3. Format tanggal ke format standar database MySQL (YYYY-MM-DD HH:MM:SS)
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(_waktuTerpilih);

      // 4. Lakukan Request POST JSON biasa (karena tidak ada upload file gambar)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // Mengirim identitas PIC lewat token login
        },
        body: json.encode({
          'id_processed_waste': widget.selectedOlahan['id'].toString(),
          'measured_qty': _kuantitasController.text,
          'notes': _catatanController.text.isEmpty ? null : _catatanController.text,
          'created_at': formattedDate,
          'raw_materials': json.encode(_daftarItemSampah.map((item) => {
             'id_waste_sub_category': item['id_sub_category'],
             'measured_qty': item['quantity']
          }).toList()),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Data olahan berhasil disimpan!')),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true); // Balik ke halaman sebelumnya & bawa sinyal true (untuk refresh)
        });
      } else {
        String pesanError = responseData['message'] ?? 'Gagal menyimpan data';
        _showErrorDialog(pesanError);
      }
    } catch (e) {
      _showErrorDialog('Terjadi masalah koneksi atau error system: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gagal Menyimpan'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _tambahItemKeDaftar() {
    if (_selectedSubcategoryName == null || _catatanController.text.isNotEmpty && false /*just to satisfy linter wait actually no need*/ ) {} 
    // The above is dummy, real check below
    if (_selectedSubcategoryName == null || _selectedSubcategoryId == null) return;
    
    // We reuse _catatanController? No we need a new controller for quantity in modal! 
    // Wait, I should add TextEditingController _qtyBahanController.
    // Let me add it in _bukaModalTambahItem since it's local, or add to class state.
  }

  // A local controller for modal
  final TextEditingController _qtyBahanController = TextEditingController();

  void _prosesTambahItem() {
    if (_selectedSubcategoryName == null || _qtyBahanController.text.isEmpty || _selectedSubcategoryId == null) return;

    setState(() {
      _daftarItemSampah.add({
        'id_sub_category': _selectedSubcategoryId,
        'name': _selectedSubcategoryName,
        'quantity': double.tryParse(_qtyBahanController.text) ?? 0.0,
        'unit': 'kg'
      });
    });

    _qtyBahanController.clear();
    setState(() {
      _selectedSubcategoryName = null;
      _selectedSubcategoryId = null;
      _sliderBahanValue = 0.0;
    });
    Navigator.pop(context);
  }

  // --- MODAL POPUP INPUT DENGAN DROPDOWN JENIS SAMPAH ---
  void _bukaModalTambahItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, 
              left: 20, right: 20, top: 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),
                
                _isLoadingSubcategories
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(color: Color(0xFF14A38B)),
                      ))
                    : _subcategoriesList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Data jenis sampah kosong di database API', style: TextStyle(color: Colors.red, fontSize: 13)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSubcategoryName,
                                hint: const Text('Pilih Sampah (Bahan)'),
                                isExpanded: true,
                                items: _subcategoriesList.map((item) {
                                  final nameStr = (item['name'] ?? item['nama'] ?? '-').toString();
                                  return DropdownMenuItem<String>(
                                    value: nameStr,
                                    child: Text(nameStr),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  final selectedItem = _subcategoriesList.firstWhere(
                                    (item) => (item['name'] ?? item['nama'] ?? '-').toString() == val,
                                    orElse: () => null,
                                  );

                                  if (selectedItem != null) {
                                    setModalState(() {
                                      _selectedSubcategoryName = val;
                                      _selectedSubcategoryId = selectedItem['id'];
                                    });
                                    setState(() {
                                      _selectedSubcategoryName = val;
                                      _selectedSubcategoryId = selectedItem['id'];
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: TextField(
                          controller: _qtyBahanController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(hintText: 'Kuantitas Digunakan', suffixText: 'kg', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFF14A38B),
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      shadowColor: const Color(0xFF14A38B).withOpacity(0.4),
                      child: InkWell(
                        onTap: () async {
                          double currentVal = double.tryParse(_qtyBahanController.text.replaceAll(',', '.')) ?? 0.0;
                          final result = await showRulerPickerModal(
                            context,
                            initialValue: currentVal,
                            max: 500.0,
                            unit: 'kg',
                          );
                          if (result != null) {
                            setModalState(() {
                              _qtyBahanController.text = result.toStringAsFixed(1);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Icon(Icons.straighten_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14A38B)),
                    onPressed: _prosesTambahItem,
                    child: const Text('Masukkan ke Daftar', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    
    // Mengambil simbol satuan dari data relasi database, default ke 'kg' jika null
    String unitSymbol = 'kg';
    if (widget.selectedOlahan['unit_measured'] != null) {
      unitSymbol = widget.selectedOlahan['unit_measured']['symbol'] ?? 'kg';
    } else if (widget.selectedOlahan['unit'] != null) {
      unitSymbol = widget.selectedOlahan['unit']['symbol'] ?? 'kg';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Input ${widget.selectedOlahan['name'] ?? 'Olahan'}', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CARD INFO JENIS OLAHAN ---
              Card(
                elevation: 0,
                color: primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedOlahan['name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF264653)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.selectedOlahan['description'] ?? 'Hasil pengolahan sampah.',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT KUANTITAS ---
              const Text('Kuantitas Hasil Olahan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: TextFormField(
                        controller: _kuantitasController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          suffixText: unitSymbol,
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Kuantitas tidak boleh kosong';
                          if (double.tryParse(val) == null) return 'Masukkan angka yang valid';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 2,
                    shadowColor: primaryColor.withOpacity(0.4),
                    child: InkWell(
                      onTap: () async {
                        double currentVal = double.tryParse(_kuantitasController.text.replaceAll(',', '.')) ?? 0.0;
                        final result = await showRulerPickerModal(
                          context,
                          initialValue: currentVal,
                          max: 500.0,
                          unit: unitSymbol,
                        );
                        if (result != null) {
                          setState(() {
                            _kuantitasController.text = result.toStringAsFixed(1);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.straighten_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- INPUT WAKTU / TANGGAL ---
              const Text('Waktu Pengolahan Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pilihWaktu(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy, HH:mm').format(_waktuTerpilih), style: const TextStyle(fontSize: 15)),
                      const Icon(Icons.calendar_month, color: primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT CATATAN ---
              const Text('Catatan Tambahan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Masukkan catatan jika ada...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- SEKSI DAFTAR BAHAN BAKU ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: primaryColor, size: 18),
                    label: const Text('Tambah Bahan', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    onPressed: _bukaModalTambahItem,
                  )
                ],
              ),
              const SizedBox(height: 8),

              _daftarItemSampah.isEmpty
                  ? Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Belum ada bahan baku yang dimasukkan.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                    )
                  : ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: _daftarItemSampah.length,
                      itemBuilder: (context, idx) {
                        final item = _daftarItemSampah[idx];
                        return Card(
                          color: Colors.white, 
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: ListTile(
                            leading: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _daftarItemSampah.removeAt(idx))),
                            title: Text(item['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            trailing: Text('${item['quantity']} ${item['unit']}', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 40),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _simpanDataOlahan,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Data Olahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}