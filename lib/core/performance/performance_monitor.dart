import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _metrics = {};
  bool _isEnabled = kDebugMode;

  // Enable/disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  // Start timing an operation
  void startTimer(String operation) {
    if (!_isEnabled) return;
    
    _timers[operation] = Stopwatch()..start();
  }

  // Stop timing an operation and record the result
  void stopTimer(String operation) {
    if (!_isEnabled) return;
    
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      _metrics[operation] ??= [];
      _metrics[operation]!.add(duration);
      
      // Log if operation is slow
      if (duration > 1000) {
        developer.log(
          'Slow operation detected: $operation took ${duration}ms',
          name: 'PerformanceMonitor',
        );
      }
      
      _timers.remove(operation);
    }
  }

  // Record a custom metric
  void recordMetric(String name, int value) {
    if (!_isEnabled) return;
    
    _metrics[name] ??= [];
    _metrics[name]!.add(value);
  }

  // Get performance statistics
  Map<String, PerformanceStats> getStats() {
    final stats = <String, PerformanceStats>{};
    
    for (final entry in _metrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        values.sort();
        final avg = values.reduce((a, b) => a + b) / values.length;
        final min = values.first;
        final max = values.last;
        final p95 = values[(values.length * 0.95).floor()];
        
        stats[entry.key] = PerformanceStats(
          operation: entry.key,
          count: values.length,
          average: avg,
          minimum: min,
          maximum: max,
          p95: p95,
        );
      }
    }
    
    return stats;
  }

  // Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _timers.clear();
  }

  // Log performance summary
  void logSummary() {
    if (!_isEnabled) return;
    
    final stats = getStats();
    if (stats.isEmpty) return;
    
    developer.log('=== Performance Summary ===', name: 'PerformanceMonitor');
    
    for (final stat in stats.values) {
      developer.log(
        '${stat.operation}: avg=${stat.average.toStringAsFixed(1)}ms, '
        'min=${stat.minimum}ms, max=${stat.maximum}ms, '
        'p95=${stat.p95}ms, count=${stat.count}',
        name: 'PerformanceMonitor',
      );
    }
  }

  // Monitor memory usage
  Future<MemoryInfo> getMemoryInfo() async {
    if (!_isEnabled) return MemoryInfo.empty();
    
    try {
      final info = await SystemChannels.platform.invokeMethod<Map>('getMemoryInfo');
      if (info != null) {
        return MemoryInfo(
          totalMemory: info['totalMemory'] ?? 0,
          availableMemory: info['availableMemory'] ?? 0,
          usedMemory: info['usedMemory'] ?? 0,
        );
      }
    } catch (e) {
      developer.log('Failed to get memory info: $e', name: 'PerformanceMonitor');
    }
    
    return MemoryInfo.empty();
  }

  // Monitor frame rendering performance
  void startFrameMonitoring() {
    if (!_isEnabled) return;
    
    WidgetsBinding.instance.addTimingsCallback(_onFrameRendered);
  }

  void stopFrameMonitoring() {
    WidgetsBinding.instance.removeTimingsCallback(_onFrameRendered);
  }

  void _onFrameRendered(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration.inMilliseconds;
      final rasterDuration = timing.rasterDuration.inMilliseconds;
      
      recordMetric('frame_build', buildDuration);
      recordMetric('frame_raster', rasterDuration);
      
      // Log slow frames
      if (buildDuration > 16 || rasterDuration > 16) {
        developer.log(
          'Slow frame: build=${buildDuration}ms, raster=${rasterDuration}ms',
          name: 'PerformanceMonitor',
        );
      }
    }
  }

  // Monitor network requests
  void recordNetworkRequest(String endpoint, int duration, bool success) {
    if (!_isEnabled) return;
    
    recordMetric('network_${endpoint}_duration', duration);
    recordMetric('network_${endpoint}_${success ? 'success' : 'failure'}', 1);
  }

  // Monitor database operations
  void recordDatabaseOperation(String operation, int duration) {
    if (!_isEnabled) return;
    
    recordMetric('db_${operation}_duration', duration);
  }

  // Monitor image processing
  void recordImageProcessing(String operation, int duration, int imageSize) {
    if (!_isEnabled) return;
    
    recordMetric('image_${operation}_duration', duration);
    recordMetric('image_${operation}_size', imageSize);
  }

  // Get performance recommendations
  List<String> getRecommendations() {
    final recommendations = <String>[];
    final stats = getStats();
    
    // Check for slow operations
    for (final stat in stats.values) {
      if (stat.average > 2000) {
        recommendations.add(
          'Operation "${stat.operation}" is slow (avg: ${stat.average.toStringAsFixed(1)}ms). Consider optimization.',
        );
      }
      
      if (stat.maximum > 5000) {
        recommendations.add(
          'Operation "${stat.operation}" has very slow instances (max: ${stat.maximum}ms). Check for edge cases.',
        );
      }
    }
    
    // Check frame performance
    final frameBuildStats = stats['frame_build'];
    if (frameBuildStats != null && frameBuildStats.p95 > 16) {
      recommendations.add(
        'Frame building is slow (p95: ${frameBuildStats.p95}ms). Consider reducing widget complexity.',
      );
    }
    
    final frameRasterStats = stats['frame_raster'];
    if (frameRasterStats != null && frameRasterStats.p95 > 16) {
      recommendations.add(
        'Frame rasterization is slow (p95: ${frameRasterStats.p95}ms). Consider reducing visual effects.',
      );
    }
    
    return recommendations;
  }
}

// Performance statistics model
class PerformanceStats {
  final String operation;
  final int count;
  final double average;
  final int minimum;
  final int maximum;
  final int p95;

  const PerformanceStats({
    required this.operation,
    required this.count,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.p95,
  });

  @override
  String toString() {
    return 'PerformanceStats(operation: $operation, count: $count, '
           'avg: ${average.toStringAsFixed(1)}ms, min: ${minimum}ms, '
           'max: ${maximum}ms, p95: ${p95}ms)';
  }
}

// Memory information model
class MemoryInfo {
  final int totalMemory;
  final int availableMemory;
  final int usedMemory;

  const MemoryInfo({
    required this.totalMemory,
    required this.availableMemory,
    required this.usedMemory,
  });

  factory MemoryInfo.empty() {
    return const MemoryInfo(
      totalMemory: 0,
      availableMemory: 0,
      usedMemory: 0,
    );
  }

  double get usagePercentage {
    if (totalMemory == 0) return 0.0;
    return (usedMemory / totalMemory) * 100;
  }

  @override
  String toString() {
    return 'MemoryInfo(total: ${totalMemory}MB, available: ${availableMemory}MB, '
           'used: ${usedMemory}MB, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}

// Performance monitoring mixin
mixin PerformanceMonitorMixin {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  void startPerformanceTimer(String operation) {
    _monitor.startTimer(operation);
  }

  void stopPerformanceTimer(String operation) {
    _monitor.stopTimer(operation);
  }

  void recordPerformanceMetric(String name, int value) {
    _monitor.recordMetric(name, value);
  }
}

// Performance monitoring wrapper for functions
T monitorPerformance<T>(String operation, T Function() function) {
  final monitor = PerformanceMonitor();
  monitor.startTimer(operation);
  
  try {
    return function();
  } finally {
    monitor.stopTimer(operation);
  }
}

// Async performance monitoring wrapper
Future<T> monitorPerformanceAsync<T>(String operation, Future<T> Function() function) async {
  final monitor = PerformanceMonitor();
  monitor.startTimer(operation);
  
  try {
    return await function();
  } finally {
    monitor.stopTimer(operation);
  }
}
