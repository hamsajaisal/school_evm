import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:school_evm/services/election_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '.';
  @override
  Future<String?> getApplicationSupportPath() async => '.';
  @override
  Future<String?> getLibraryPath() async => '.';
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
  @override
  Future<String?> getExternalStoragePath() async => '.';
  @override
  Future<List<String>?> getExternalCachePaths() async => ['.'];
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => ['.'];
  @override
  Future<String?> getDownloadsPath() async => '.';
}

void main() {
  // Use standard test instead of testWidgets to avoid FakeAsync issues with Hive / async I/O
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  test('Voters Excel Import Test', () async {
    final provider = ElectionProvider();
    await provider.db.init();

    // Reset database to be clean
    await provider.db.resetElection();

    // Create an excel workbook in memory
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    // Header row
    sheet.appendRow([
      TextCellValue('Serial'),
      TextCellValue('Admission No'),
      TextCellValue('Full Name'),
      TextCellValue('Class'),
      TextCellValue('Division'),
    ]);
    // Data rows
    sheet.appendRow([
      TextCellValue('1'),
      TextCellValue('ADM001'),
      TextCellValue('Alice Johnson'),
      TextCellValue('8'),
      TextCellValue('A'),
    ]);
    sheet.appendRow([
      TextCellValue('2'),
      TextCellValue('ADM002'),
      TextCellValue('Bob Smith'),
      TextCellValue('8'),
      TextCellValue('B'),
    ]);
    sheet.appendRow([
      TextCellValue('3'),
      TextCellValue('ADM003'),
      TextCellValue('Charlie Brown'),
      TextCellValue('9'),
      TextCellValue('A'),
    ]);

    final bytes = excel.save();
    expect(bytes, isNotNull);

    // Call importVotersFromExcel
    final importedCount = await provider.importVotersFromExcel(bytes!);
    expect(importedCount, equals(3));

    // Verify database entries
    final voters = provider.db.voters;
    expect(voters.length, equals(3));

    expect(voters[0].serialNumber, equals('1'));
    expect(voters[0].admissionNumber, equals('ADM001'));
    expect(voters[0].fullName, equals('Alice Johnson'));
    expect(voters[0].classLevel, equals('8'));
    expect(voters[0].division, equals('A'));

    expect(voters[1].serialNumber, equals('2'));
    expect(voters[1].admissionNumber, equals('ADM002'));
    expect(voters[1].fullName, equals('Bob Smith'));
    expect(voters[1].classLevel, equals('8'));
    expect(voters[1].division, equals('B'));

    expect(voters[2].serialNumber, equals('3'));
    expect(voters[2].admissionNumber, equals('ADM003'));
    expect(voters[2].fullName, equals('Charlie Brown'));
    expect(voters[2].classLevel, equals('9'));
    expect(voters[2].division, equals('A'));
  });
}
