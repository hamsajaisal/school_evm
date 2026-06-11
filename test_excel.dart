import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

void main() {
  final file = File('student_register.xlsx');
  if (!file.existsSync()) {
    print('File does not exist!');
    return;
  }
  final bytes = file.readAsBytesSync();
  print('File size: ${bytes.length} bytes');
  
  try {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes);
    print('Tables: ${decoder.tables.keys}');
    for (var table in decoder.tables.keys) {
      final sheet = decoder.tables[table];
      if (sheet == null) {
        print('Sheet $table is null');
        continue;
      }
      print('Sheet $table: maxRows=${sheet.maxRows}, maxCols=${sheet.maxCols}');
      
      // Print first 10 rows
      final limit = sheet.maxRows > 10 ? 10 : sheet.maxRows;
      for (int i = 0; i < limit; i++) {
        final row = sheet.rows[i];
        print('Row $i: $row');
      }
    }
  } catch (e, stack) {
    print('Error decoding: $e');
    print(stack);
  }
}
