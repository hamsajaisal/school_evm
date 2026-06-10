import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_evm/main.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  testWidgets('App branding smoke test', (WidgetTester tester) async {
    final provider = ElectionProvider();
    
    // Run async provider initialization in the real async zone
    await tester.runAsync(() async {
      await provider.init();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => provider,
        child: const MyApp(),
      ),
    );

    // Let the database initialization settle
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the title text exists
    expect(find.text('School EVM Pro'), findsOneWidget);
  });
}
