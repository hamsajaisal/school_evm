import 'server_interface.dart';
import 'server_stub.dart' if (dart.library.io) 'server_io.dart';

BoothServer createServer() => BoothServerImpl();
