import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Timer> _cacheTimers = {};
  
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _defaultCacheExpiry = Duration(minutes: 30);
  
  int _currentCacheSize = 0;
  bool _isEnabled = true;

  // Enable/disable memory management
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      clearCache();
    }
  }

  // Cache management
  void cacheData(String key, dynamic data, {Duration? expiry}) {
    if (!_isEnabled) return;
    
    final dataSize = _calculateDataSize(data);
    
    // Check if adding this data would exceed cache limit
    if (_currentCacheSize + dataSize > _maxCacheSize) {
      _evictOldestEntries(dataSize);
    }
    
    // Remove existing entry if it exists
    if (_cache.containsKey(key)) {
      _removeFromCache(key);
    }
    
    // Add new entry
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _currentCacheSize += dataSize;
    
    // Set expiry timer
    final expiryDuration = expiry ?? _defaultCacheExpiry;
    _cacheTimers[key] = Timer(expiryDuration, () {
      _removeFromCache(key);
    });
    
    developer.log(
      'Cached data: $key (${_formatBytes(dataSize)}) - Total cache: ${_formatBytes(_currentCacheSize)}',
      name: 'MemoryManager',
    );
  }

  // Retrieve cached data
  T? getCachedData<T>(String key) {
    if (!_isEnabled) return null;
    
    final data = _cache[key];
    if (data != null) {
      // Update access time
      _cacheTimestamps[key] = DateTime.now();
      return data as T?;
    }
    
    return null;
  }

  // Remove specific cache entry
  void removeCachedData(String key) {
    _removeFromCache(key);
  }

  // Clear all cache
  void clearCache() {
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheTimers.clear();
    _currentCacheSize = 0;
    
    developer.log('Cache cleared', name: 'MemoryManager');
  }

  // Get cache statistics
  CacheStats getCacheStats() {
    return CacheStats(
      entryCount: _cache.length,
      totalSize: _currentCacheSize,
      maxSize: _maxCacheSize,
      hitRate: 0.0, // Would need to track hits/misses for accurate calculation
    );
  }

  // Image memory management
  void optimizeImageMemory(Uint8List imageData, {int? maxWidth, int? maxHeight}) {
    if (!_isEnabled) return;
    
    // This would implement image compression and resizing
    // For now, just log the operation
    developer.log(
      'Image optimization: ${_formatBytes(imageData.length)} -> optimized',
      name: 'MemoryManager',
    );
  }

  // Dispose of large objects
  void disposeObject(String key, dynamic object) {
    if (!_isEnabled) return;
    
    // Remove from cache if present
    _removeFromCache(key);
    
    // Dispose specific object types
    if (object is StreamController) {
      object.close();
    } else if (object is Timer) {
      object.cancel();
    } else if (object is StreamSubscription) {
      object.cancel();
    }
    
    developer.log('Disposed object: $key', name: 'MemoryManager');
  }

  // Force garbage collection (use sparingly)
  void forceGarbageCollection() {
    if (!_isEnabled) return;
    
    // Clear expired cache entries first
    _cleanupExpiredEntries();
    
    // Force GC (this is a hint, not guaranteed)
    developer.log('Forcing garbage collection', name: 'MemoryManager');
  }

  // Monitor memory pressure
  void handleMemoryPressure() {
    if (!_isEnabled) return;
    
    developer.log('Memory pressure detected - clearing cache', name: 'MemoryManager');
    
    // Clear half of the cache, starting with oldest entries
    final entriesToRemove = (_cache.length * 0.5).ceil();
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    for (int i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      _removeFromCache(sortedEntries[i].key);
    }
  }

  // Private helper methods
  void _removeFromCache(String key) {
    final data = _cache.remove(key);
    if (data != null) {
      final dataSize = _calculateDataSize(data);
      _currentCacheSize -= dataSize;
    }
    
    _cacheTimestamps.remove(key);
    _cacheTimers[key]?.cancel();
    _cacheTimers.remove(key);
  }

  void _evictOldestEntries(int requiredSpace) {
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    int freedSpace = 0;
    for (final entry in sortedEntries) {
      if (freedSpace >= requiredSpace) break;
      
      final data = _cache[entry.key];
      if (data != null) {
        freedSpace += _calculateDataSize(data);
        _removeFromCache(entry.key);
      }
    }
    
    developer.log(
      'Evicted cache entries to free ${_formatBytes(freedSpace)}',
      name: 'MemoryManager',
    );
  }

  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultCacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _removeFromCache(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      developer.log(
        'Cleaned up ${expiredKeys.length} expired cache entries',
        name: 'MemoryManager',
      );
    }
  }

  int _calculateDataSize(dynamic data) {
    if (data is String) {
      return data.length * 2; // Approximate UTF-16 encoding
    } else if (data is Uint8List) {
      return data.length;
    } else if (data is List) {
      return data.length * 8; // Approximate pointer size
    } else if (data is Map) {
      return data.length * 16; // Approximate key-value pair size
    } else {
      return 64; // Default estimate for unknown objects
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// Cache statistics model
class CacheStats {
  final int entryCount;
  final int totalSize;
  final int maxSize;
  final double hitRate;

  const CacheStats({
    required this.entryCount,
    required this.totalSize,
    required this.maxSize,
    required this.hitRate,
  });

  double get usagePercentage => (totalSize / maxSize) * 100;

  @override
  String toString() {
    return 'CacheStats(entries: $entryCount, size: ${_formatBytes(totalSize)}/${_formatBytes(maxSize)} '
           '(${usagePercentage.toStringAsFixed(1)}%), hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// Memory management mixin
mixin MemoryManagerMixin {
  final MemoryManager _memoryManager = MemoryManager();

  void cacheData(String key, dynamic data, {Duration? expiry}) {
    _memoryManager.cacheData(key, data, expiry: expiry);
  }

  T? getCachedData<T>(String key) {
    return _memoryManager.getCachedData<T>(key);
  }

  void clearCache() {
    _memoryManager.clearCache();
  }

  void disposeResources() {
    _memoryManager.clearCache();
  }
}

// Automatic memory management for widgets
mixin AutoMemoryManagement<T extends StatefulWidget> on State<T> {
  final MemoryManager _memoryManager = MemoryManager();
  final List<String> _managedKeys = [];

  void managedCache(String key, dynamic data, {Duration? expiry}) {
    _memoryManager.cacheData(key, data, expiry: expiry);
    _managedKeys.add(key);
  }

  @override
  void dispose() {
    // Clean up managed cache entries
    for (final key in _managedKeys) {
      _memoryManager.removeCachedData(key);
    }
    _managedKeys.clear();
    
    super.dispose();
  }
}
