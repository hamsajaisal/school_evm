import 'package:flutter_test/flutter_test.dart';
import 'package:school_evm/services/election_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  test('Voters Excel Import Test', () async {
    final provider = ElectionProvider();
    await provider.db.init();

    // Reset database to be clean
    await provider.db.resetElection();

    // Load local Excel file
    final file = File('student_register.xlsx');
    expect(file.existsSync(), isTrue);
    final bytes = file.readAsBytesSync();

    // Call importVotersFromExcel
    final importedCount = await provider.importVotersFromExcel(bytes);
    expect(importedCount, equals(20)); // There are 20 data rows in student_register.xlsx

    // Verify database entries
    final voters = provider.db.voters;
    expect(voters.length, equals(20));

    expect(voters[0].serialNumber, equals('1'));
    expect(voters[0].admissionNumber, equals('1023'));
    expect(voters[0].fullName, equals('Aravind Krishnan Nair'));
    expect(voters[0].classLevel, equals('8'));
    expect(voters[0].division, equals('B'));

    expect(voters[1].serialNumber, equals('2'));
    expect(voters[1].admissionNumber, equals('1047'));
    expect(voters[1].fullName, equals('Devika Suresh Menon'));
    expect(voters[1].classLevel, equals('8'));
    expect(voters[1].division, equals('B'));
  });
}
