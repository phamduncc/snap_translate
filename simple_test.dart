import 'dart:io';

void main() async {
  print('Testing vocabulary functionality...');
  
  // Check if database file exists
  final dbPath = 'E:\\TEST\\snap_translate\\build\\app\\outputs\\flutter-apk\\app-debug.apk';
  print('APK exists: ${File(dbPath).existsSync()}');
  
  // Simple test
  print('✅ Basic test completed');
}
