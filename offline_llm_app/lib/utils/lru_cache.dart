// lru_cache.dart
// Simple LRU cache for instant chat switching
// Keeps recent chats in memory for zero-latency access

import 'dart:collection';

class LRUCache<K, V> {
  final int _capacity;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  
  LRUCache(this._capacity);
  
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    // Move to end (most recently used)
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }
  
  void put(K key, V value) {
    // Remove if exists (will re-add at end)
    _cache.remove(key);
    
    // Add to end
    _cache[key] = value;
    
    // Evict oldest if over capacity
    if (_cache.length > _capacity) {
      _cache.remove(_cache.keys.first);
    }
  }
  
  bool contains(K key) => _cache.containsKey(key);
  
  void remove(K key) => _cache.remove(key);
  
  void clear() => _cache.clear();
  
  int get length => _cache.length;
}
