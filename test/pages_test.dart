import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/models.dart';
import 'package:mobile/features/account/change_password_page.dart';
import 'package:mobile/features/account/edit_profile_page.dart';
import 'package:mobile/features/account/help_page.dart';
import 'package:mobile/features/auth/login_page.dart';
import 'package:mobile/features/entry/entry_category_page.dart';
import 'package:mobile/features/entry/entry_form_page.dart';
import 'package:mobile/features/entry/entry_subcategory_page.dart';
import 'package:mobile/features/history/history_detail_page.dart';
import 'package:mobile/features/iot/iot_page.dart';
import 'package:mobile/features/notifications/b3_alerts_page.dart';
import 'package:mobile/features/out/out_form_page.dart';
import 'package:mobile/features/processed/processed_form_page.dart';
import 'package:mobile/features/report/report_form_page.dart';
import 'package:mobile/features/shell/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Respons API diambil dari backend Laravel asli (lihat test/fixtures).
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

final b3Fixture = {
  'success': true,
  'data': [
    {
      'waste_code': 'B105d',
      'waste_name': 'Oli Bekas Mesin Genset',
      'retention_period_day': 90,
      'created_at': '2026-07-01 08:00:00',
      'sisa_hari': -9,
      'stock': 12.5,
      'unit': 'L',
      'status': 'expired',
    },
    {
      'waste_code': 'A102d',
      'waste_name': 'Aki Bekas',
      'retention_period_day': 30,
      'created_at': '2026-09-20 08:00:00',
      'sisa_hari': 2,
      'stock': 3,
      'unit': 'pcs',
      'status': 'critical',
    },
  ],
};

class FakeApi {
  final List<http.BaseRequest> requests = [];
  final Map<String, Map<String, dynamic>> overrides = {};
  Map<String, dynamic> Function(http.BaseRequest)? onPost;

  late final client = MockClient.streaming((request, bodyStream) async {
    requests.add(request);
    final body = await bodyStream.toBytes();
    final path = request.url.path.replaceFirst('/api/', '');
    Map<String, dynamic> res;
    var status = 200;

    if (request.method == 'POST') {
      res = onPost?.call(request) ?? {'success': true, 'message': 'Tersimpan (test)'};
      status = res['success'] == false ? 422 : 201;
      _lastBodies[path] = utf8.decode(body, allowMalformed: true);
    } else if (overrides.containsKey(path)) {
      res = overrides[path]!;
    } else {
      final name = switch (path) {
        final p when p.startsWith('sub-categories/') => 'sub-categories_1',
        final p when p.startsWith('laporan-harian/') => 'laporan-harian_1',
        final p when p.startsWith('laporan-kendala/') => 'laporan-kendala_1',
        final p when p.startsWith('processed-waste-data/') => 'processed-waste-data_1',
        final p when p.startsWith('waste-out/') => 'waste-out_detail',
        'iot/session' => 'iot_session',
        _ => path,
      };
      res = fixture(name);
    }
    return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(res))), status, headers: {'content-type': 'application/json'});
  });

  final Map<String, String> _lastBodies = {};
  String? bodyOf(String path) => _lastBodies[path];
  int postsTo(String path) => requests.where((r) => r.method == 'POST' && r.url.path.endsWith(path)).length;
}

const sizes = [Size(360, 690), Size(320, 568)];

Future<void> pumpPage(WidgetTester tester, Widget page, {Size size = const Size(360, 690), double textScale = 1.0}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF14A38B)),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: page,
  ));
  // Biarkan request tiruan & animasi selesai
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Gulir ke widget (list dibangun malas) lalu ketuk.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable);
  if (finder.evaluate().isEmpty && scrollable.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(finder, 150, scrollable: scrollable.first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  late FakeApi api;

  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'token': 'test-token',
      'user_id': 2,
      'user_name': 'PIC User 1',
      'user_nik': '12345678901',
      'user_email': 'pic1@gmail.com',
    });
    api = FakeApi();
    ApiClient.client = api.client;
  });

  final category = WasteCategory.fromJson(fixture('categories')['data'][0]);
  final subCategory = WasteSubCategory.fromJson(fixture('sub-categories_1')['data'][0]);

  final pages = <String, Widget Function()>{
    'login': () => const LoginPage(),
    'shell (beranda/stok/riwayat/akun)': () => const MainShell(),
    'kategori masuk': () => const EntryCategoryPage(),
    'sub-kategori masuk': () => EntrySubcategoryPage(category: category),
    'form masuk': () => EntryFormPage(category: category, subCategory: subCategory),
    'form olahan': () => const ProcessedFormPage(),
    'form keluar': () => const OutFormPage(),
    'form kendala': () => const ReportFormPage(),
    'detail masuk': () => const HistoryDetailPage(type: 'input_masuk', id: 21),
    'detail keluar': () => const HistoryDetailPage(type: 'input_keluar', id: 16),
    'detail olahan': () => const HistoryDetailPage(type: 'olahan', id: 11),
    'detail kendala': () => const HistoryDetailPage(type: 'kendala', id: 1),
    'peringatan b3': () => const B3AlertsPage(),
    'iot': () => const IotPage(),
    'edit profil': () => const EditProfilePage(),
    'ubah sandi': () => const ChangePasswordPage(),
    'bantuan': () => const HelpPage(),
  };

  for (final size in sizes) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} dirender tanpa error di ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        api.overrides['waste-b3-notifications'] = b3Fixture;
        await pumpPage(tester, entry.value(), size: size);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final entry in pages.entries) {
    testWidgets('${entry.key} tetap rapi dengan teks diperbesar 130%', (tester) async {
      await pumpPage(tester, entry.value(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('beranda menampilkan ringkasan berat hari ini dari API', (tester) async {
    await pumpPage(tester, const MainShell());
    expect(find.text('12,5'), findsWidgets); // berat_masuk
    await tester.scrollUntilVisible(find.text('Sisa Makanan'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Sisa Makanan'), findsWidgets); // entri terbaru
  });

  testWidgets('stok minus dari data lama tetap ditampilkan', (tester) async {
    await pumpPage(tester, const MainShell());
    await tapOn(tester, find.text('Stok'));
    await tester.pump(const Duration(milliseconds: 300));
    await tapOn(tester, find.text('Sembunyikan stok kosong'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Sisa Makanan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form masuk tidak mengirim jika lokasi, berat & foto kosong', (tester) async {
    await pumpPage(tester, EntryFormPage(category: category, subCategory: subCategory));
    await tapOn(tester, find.text('Simpan Sampah Masuk'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lengkapi isian yang ditandai merah.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Foto bukti wajib dilampirkan'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Foto bukti wajib dilampirkan'), findsOneWidget);
    expect(api.postsTo('waste-entry'), 0);
  });

  testWidgets('form keluar menolak jumlah melebihi stok sebelum dikirim', (tester) async {
    await pumpPage(tester, const OutFormPage());
    await tapOn(tester, find.text('Landfill'));
    await tester.pump();
    await tapOn(tester, find.text('Tambahkan item sampah'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Botol Plastik').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '99999');
    await tapOn(tester, find.text('Simpan Sampah Keluar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Maks'), findsOneWidget);
    expect(api.postsTo('waste-out'), 0);
  });

  testWidgets('metode penjualan mewajibkan pembeli', (tester) async {
    await pumpPage(tester, const OutFormPage());
    await tapOn(tester, find.text('Penjualan'));
    await tester.pump();
    expect(find.text('Pembeli'), findsOneWidget);
    expect(find.text('Total pendapatan'), findsOneWidget);
  });

  testWidgets('form keluar valid mengirim item dengan desimal koma sebagai angka', (tester) async {
    await pumpPage(tester, const OutFormPage());
    await tapOn(tester, find.text('Landfill'));
    await tester.pump();
    await tapOn(tester, find.text('Tambahkan item sampah'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Botol Plastik').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '1,5');
    await tapOn(tester, find.text('Simpan Sampah Keluar'));
    await tester.pumpAndSettle();

    expect(api.postsTo('waste-out'), 1);
    final body = api.bodyOf('waste-out')!;
    expect(body, contains('"quantity":1.5'));
    expect(body, contains('name="id_waste_out_method"'));
  });

  testWidgets('form olahan mengirim bahan baku sebagai JSON', (tester) async {
    await pumpPage(tester, const ProcessedFormPage());
    await tapOn(tester, find.text('Pilih jenis olahan'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Pupuk Kompos').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '2');
    await tapOn(tester, find.text('Tambahkan bahan baku'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Daun Kering').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '3');
    await tapOn(tester, find.text('Simpan Hasil Olahan'));
    await tester.pumpAndSettle();

    expect(api.postsTo('processed-waste-data'), 1);
    final body = jsonDecode(api.bodyOf('processed-waste-data')!) as Map<String, dynamic>;
    expect(body['measured_qty'], 2);
    expect(jsonDecode(body['raw_materials']), [
      {'id_waste_sub_category': 2, 'measured_qty': 3.0},
    ]);
  });

  testWidgets('pesan error validasi server ditampilkan ke pengguna', (tester) async {
    api.onPost = (_) => {
          'success': false,
          'message': 'Stok Botol Plastik tidak cukup.',
          'errors': {
            'items': ['Stok Botol Plastik tidak cukup (tersedia 2 kg, diminta 3 kg).'],
          },
        };
    await pumpPage(tester, const OutFormPage());
    await tapOn(tester, find.text('Landfill'));
    await tester.pump();
    await tapOn(tester, find.text('Tambahkan item sampah'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Botol Plastik').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '1');
    await tapOn(tester, find.text('Simpan Sampah Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('Stok Botol Plastik tidak cukup (tersedia 2 kg, diminta 3 kg).'), findsOneWidget);
  });

  testWidgets('keluar dari form yang sudah diisi meminta konfirmasi', (tester) async {
    await pumpPage(tester, Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportFormPage())),
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tapOn(tester, find.text('buka'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Timbangan rusak');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pengisian?'), findsOneWidget);
  });

  testWidgets('peringatan b3 menampilkan status lewat batas', (tester) async {
    api.overrides['waste-b3-notifications'] = b3Fixture;
    await pumpPage(tester, const B3AlertsPage());
    expect(find.text('Lewat 9 hari'), findsOneWidget);
    expect(find.text('Sisa 2 hari'), findsOneWidget);
  });

  testWidgets('sesi kedaluwarsa (401) memanggil handler logout', (tester) async {
    var called = false;
    ApiClient.onUnauthorized = (_) async => called = true;
    ApiClient.client = MockClient((_) async => http.Response(jsonEncode({'success': false, 'message': 'Sesi berakhir'}), 401));
    await pumpPage(tester, const EntryCategoryPage());
    expect(called, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), isNull);
    ApiClient.onUnauthorized = null;
  });
}
