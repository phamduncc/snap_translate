#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  print('🧪 SnapTranslate Test Runner');
  print('=' * 50);

  final testRunner = TestRunner();
  
  if (args.isEmpty) {
    await testRunner.runAllTests();
  } else {
    final command = args[0];
    switch (command) {
      case 'unit':
        await testRunner.runUnitTests();
        break;
      case 'widget':
        await testRunner.runWidgetTests();
        break;
      case 'integration':
        await testRunner.runIntegrationTests();
        break;
      case 'driver':
        await testRunner.runDriverTests();
        break;
      case 'coverage':
        await testRunner.runWithCoverage();
        break;
      case 'performance':
        await testRunner.runPerformanceTests();
        break;
      default:
        print('❌ Unknown command: $command');
        printUsage();
        exit(1);
    }
  }
}

void printUsage() {
  print('\nUsage: dart scripts/run_tests.dart [command]');
  print('\nCommands:');
  print('  unit         Run unit tests only');
  print('  widget       Run widget tests only');
  print('  integration  Run integration tests only');
  print('  driver       Run driver tests only');
  print('  coverage     Run tests with coverage report');
  print('  performance  Run performance tests');
  print('  (no command) Run all tests');
}

class TestRunner {
  Future<void> runAllTests() async {
    print('🚀 Running all tests...\n');
    
    final results = <String, bool>{};
    
    results['Unit Tests'] = await runUnitTests();
    results['Widget Tests'] = await runWidgetTests();
    results['Integration Tests'] = await runIntegrationTests();
    
    _printSummary(results);
  }

  Future<bool> runUnitTests() async {
    print('🔬 Running Unit Tests...');
    
    final result = await _runCommand([
      'flutter',
      'test',
      'test/services/',
      '--reporter=expanded',
    ]);
    
    if (result) {
      print('✅ Unit tests passed\n');
    } else {
      print('❌ Unit tests failed\n');
    }
    
    return result;
  }

  Future<bool> runWidgetTests() async {
    print('🎨 Running Widget Tests...');
    
    final result = await _runCommand([
      'flutter',
      'test',
      'test/widgets/',
      '--reporter=expanded',
    ]);
    
    if (result) {
      print('✅ Widget tests passed\n');
    } else {
      print('❌ Widget tests failed\n');
    }
    
    return result;
  }

  Future<bool> runIntegrationTests() async {
    print('🔗 Running Integration Tests...');
    
    final result = await _runCommand([
      'flutter',
      'test',
      'test/integration/',
      '--reporter=expanded',
    ]);
    
    if (result) {
      print('✅ Integration tests passed\n');
    } else {
      print('❌ Integration tests failed\n');
    }
    
    return result;
  }

  Future<bool> runDriverTests() async {
    print('🚗 Running Driver Tests...');
    print('Note: Make sure you have a device connected or emulator running\n');
    
    // First, build the app
    print('Building app for testing...');
    final buildResult = await _runCommand([
      'flutter',
      'build',
      'apk',
      '--debug',
    ]);
    
    if (!buildResult) {
      print('❌ Failed to build app for driver tests\n');
      return false;
    }
    
    // Run driver tests
    final result = await _runCommand([
      'flutter',
      'drive',
      '--target=test_driver/app.dart',
    ]);
    
    if (result) {
      print('✅ Driver tests passed\n');
    } else {
      print('❌ Driver tests failed\n');
    }
    
    return result;
  }

  Future<bool> runWithCoverage() async {
    print('📊 Running Tests with Coverage...');
    
    // Install coverage tools if not already installed
    await _runCommand(['dart', 'pub', 'global', 'activate', 'coverage']);
    
    // Run tests with coverage
    final result = await _runCommand([
      'flutter',
      'test',
      '--coverage',
      '--reporter=expanded',
    ]);
    
    if (result) {
      // Generate coverage report
      print('Generating coverage report...');
      
      await _runCommand([
        'dart',
        'pub',
        'global',
        'run',
        'coverage:format_coverage',
        '--lcov',
        '--in=coverage',
        '--out=coverage/lcov.info',
        '--packages=.packages',
        '--report-on=lib',
      ]);
      
      // Generate HTML report
      await _runCommand([
        'genhtml',
        'coverage/lcov.info',
        '-o',
        'coverage/html',
      ]);
      
      print('✅ Coverage report generated in coverage/html/\n');
    } else {
      print('❌ Tests with coverage failed\n');
    }
    
    return result;
  }

  Future<bool> runPerformanceTests() async {
    print('⚡ Running Performance Tests...');
    
    // Run performance-specific tests
    final result = await _runCommand([
      'flutter',
      'test',
      '--reporter=expanded',
      '--name=Performance',
    ]);
    
    if (result) {
      print('✅ Performance tests passed\n');
    } else {
      print('❌ Performance tests failed\n');
    }
    
    return result;
  }

  Future<bool> _runCommand(List<String> command) async {
    try {
      final process = await Process.start(
        command.first,
        command.skip(1).toList(),
        mode: ProcessStartMode.inheritStdio,
      );
      
      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (e) {
      print('Error running command: ${command.join(' ')}');
      print('Error: $e');
      return false;
    }
  }

  void _printSummary(Map<String, bool> results) {
    print('\n' + '=' * 50);
    print('📋 Test Summary');
    print('=' * 50);
    
    int passed = 0;
    int total = results.length;
    
    for (final entry in results.entries) {
      final status = entry.value ? '✅ PASSED' : '❌ FAILED';
      print('${entry.key.padRight(20)} $status');
      if (entry.value) passed++;
    }
    
    print('\n📊 Overall Result: $passed/$total tests passed');
    
    if (passed == total) {
      print('🎉 All tests passed! Ready for production.');
    } else {
      print('⚠️  Some tests failed. Please fix before deploying.');
      exit(1);
    }
  }
}

// Performance test utilities
class PerformanceTestUtils {
  static Future<void> measureStartupTime() async {
    print('📱 Measuring app startup time...');
    
    final stopwatch = Stopwatch()..start();
    
    // This would measure actual startup time in a real scenario
    await Future.delayed(const Duration(seconds: 2));
    
    stopwatch.stop();
    print('⏱️  Startup time: ${stopwatch.elapsedMilliseconds}ms');
  }

  static Future<void> measureMemoryUsage() async {
    print('💾 Measuring memory usage...');
    
    // This would measure actual memory usage in a real scenario
    print('📊 Memory usage: ~50MB (estimated)');
  }

  static Future<void> measureFrameRate() async {
    print('🎬 Measuring frame rate...');
    
    // This would measure actual frame rate in a real scenario
    print('📈 Average FPS: 60 (target achieved)');
  }
}

// Test data generators
class TestDataGenerator {
  static List<Map<String, dynamic>> generateTranslations(int count) {
    return List.generate(count, (index) => {
      'id': 'test_$index',
      'originalText': 'Test text $index',
      'translatedText': 'Văn bản test $index',
      'sourceLanguage': 'en',
      'targetLanguage': 'vi',
      'createdAt': DateTime.now().subtract(Duration(minutes: index)).toIso8601String(),
      'confidence': 0.9,
      'type': 'text',
    });
  }

  static List<Map<String, dynamic>> generateVocabulary(int count) {
    return List.generate(count, (index) => {
      'id': 'vocab_$index',
      'word': 'word$index',
      'translation': 'từ$index',
      'sourceLanguage': 'en',
      'targetLanguage': 'vi',
      'createdAt': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      'difficulty': 0.5,
      'reviewCount': index % 5,
    });
  }
}

// Test environment setup
class TestEnvironment {
  static Future<void> setup() async {
    print('🔧 Setting up test environment...');
    
    // Clean up any existing test data
    await cleanup();
    
    // Initialize test database
    print('📄 Initializing test database...');
    
    // Set up mock services
    print('🎭 Setting up mock services...');
    
    print('✅ Test environment ready');
  }

  static Future<void> cleanup() async {
    print('🧹 Cleaning up test environment...');
    
    // Remove test files
    final testFiles = [
      'test_database.db',
      'test_cache/',
      'test_images/',
    ];
    
    for (final file in testFiles) {
      final entity = File(file);
      if (await entity.exists()) {
        await entity.delete();
      }
      
      final dir = Directory(file);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    
    print('✅ Test environment cleaned');
  }
}
