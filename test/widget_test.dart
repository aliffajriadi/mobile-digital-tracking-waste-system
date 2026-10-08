import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/core/widgets/form_widgets.dart';
import 'package:mobile/data/models.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('Fmt.parseDecimal', () {
    test('menerima koma dan titik sebagai desimal', () {
      expect(Fmt.parseDecimal('1,5'), 1.5);
      expect(Fmt.parseDecimal('1.5'), 1.5);
      expect(Fmt.parseDecimal(' 12 '), 12);
    });

    test('mengembalikan null untuk input tidak valid', () {
      expect(Fmt.parseDecimal(''), isNull);
      expect(Fmt.parseDecimal('abc'), isNull);
      expect(Fmt.parseDecimal(null), isNull);
    });
  });

  test('Fmt.qty memakai format Indonesia', () {
    expect(Fmt.qty(1250.5), '1.250,5');
    expect(Fmt.qty(3), '3');
    expect(Fmt.qtyUnit(2.25, null), '2,25 kg');
  });

  group('QuantityField.validate', () {
    test('menolak nol, negatif, dan non-angka', () {
      expect(QuantityField.validate('0'), isNotNull);
      expect(QuantityField.validate('-1'), isNotNull);
      expect(QuantityField.validate('x'), isNotNull);
      expect(QuantityField.validate('2,5'), isNull);
    });

    test('menolak jumlah melebihi stok', () {
      expect(QuantityField.validate('11', maxStock: 10), contains('Melebihi stok'));
      expect(QuantityField.validate('10', maxStock: 10), isNull);
    });
  });

  test('StockItem membedakan sampah mentah dan hasil olahan', () {
    final raw = StockItem.fromJson({'id': 5, 'name': 'Botol', 'category': 'Anorganik', 'stock': 12.5, 'unit': 'kg', 'type': 'raw'});
    final processed = StockItem.fromJson({'id': 'p_3', 'name': 'Kompos', 'stock': '4', 'unit': 'kg', 'type': 'processed'});
    expect(raw.isProcessed, isFalse);
    expect(raw.rawId, 5);
    expect(processed.isProcessed, isTrue);
    expect(processed.rawId, 3);
    expect(processed.stock, 4.0);
  });

  test('WasteOutMethod membaca flag penjualan dari server', () {
    expect(WasteOutMethod.fromJson({'id': 1, 'name': 'Landfill', 'is_selling': false}).isSelling, isFalse);
    expect(WasteOutMethod.fromJson({'id': 2, 'name': 'Bank sampah', 'is_selling': true}).isSelling, isTrue);
    // Server lama tanpa flag: tebak dari nama
    expect(WasteOutMethod.fromJson({'id': 3, 'name': 'Dijual ke pengepul'}).isSelling, isTrue);
  });

  test('ApiException mengambil pesan error per field', () {
    const e = ApiException('Data tidak valid', statusCode: 422, errors: {
      'items': ['Stok Botol tidak cukup.'],
      'raw_materials.0.measured_qty': ['Berat harus lebih dari 0.'],
    });
    expect(e.fieldError('items'), 'Stok Botol tidak cukup.');
    expect(e.fieldError('raw_materials'), 'Berat harus lebih dari 0.');
    expect(e.fullMessage, contains('Stok Botol tidak cukup.'));
  });

  testWidgets('QuantityField menampilkan stok tersedia', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: QuantityField(controller: controller, unit: 'kg', maxStock: 7.5)),
    ));
    expect(find.text('Stok tersedia: 7,5 kg'), findsOneWidget);
  });
}
