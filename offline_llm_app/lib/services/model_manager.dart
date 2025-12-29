// model_manager.dart
// Manages model downloads, storage, and lifecycle
// Handles downloading models from Hugging Face and storing them locally

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/model_info.dart';

/// Manages model downloads, storage, and deletion
class ModelManager extends ChangeNotifier {
  static ModelManager? _instance;
  static ModelManager get instance => _instance ??= ModelManager._();
  
  ModelManager._();
  
  String? _modelsDirectory;
  final Map<String, DownloadProgress> _downloadProgress = {};
  final Set<String> _downloadedModels = {};
  String? _activeModelId;
  http.Client? _httpClient;
  
  String? get modelsDirectory => _modelsDirectory;
  String? get activeModelId => _activeModelId;
  Set<String> get downloadedModels => Set.unmodifiable(_downloadedModels);

  /// Initialize the model manager
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _modelsDirectory = path.join(appDir.path, 'models');
    
    // Create models directory if it doesn't exist
    final dir = Directory(_modelsDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // Scan for existing models
    await _scanExistingModels();
    
    // Load active model preference
    final prefs = await SharedPreferences.getInstance();
    _activeModelId = prefs.getString('active_model_id');
    
    notifyListeners();
  }

  /// Scan the models directory for existing downloads
  Future<void> _scanExistingModels() async {
    _downloadedModels.clear();
    
    final dir = Directory(_modelsDirectory!);
    if (!await dir.exists()) return;
    
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.gguf')) {
        final fileName = path.basename(entity.path);
        // Find model by filename
        for (final model in AvailableModels.models) {
          if (model.fileName == fileName) {
            _downloadedModels.add(model.id);
            _downloadProgress[model.id] = DownloadProgress(
              modelId: model.id,
              downloadedBytes: await entity.length(),
              totalBytes: await entity.length(),
              status: ModelStatus.downloaded,
            );
            break;
          }
        }
      }
    }
  }

  /// Get the download progress for a model
  DownloadProgress getProgress(String modelId) {
    return _downloadProgress[modelId] ?? DownloadProgress(
      modelId: modelId,
      status: ModelStatus.notDownloaded,
    );
  }

  /// Check if a model is downloaded
  bool isModelDownloaded(String modelId) {
    return _downloadedModels.contains(modelId);
  }

  /// Get the path to a downloaded model
  String? getModelPath(String modelId) {
    if (!isModelDownloaded(modelId)) return null;
    
    final model = AvailableModels.getById(modelId);
    if (model == null) return null;
    
    return path.join(_modelsDirectory!, model.fileName);
  }

  /// Download a model from Hugging Face
  Future<void> downloadModel(String modelId) async {
    final model = AvailableModels.getById(modelId);
    if (model == null) {
      throw ArgumentError('Unknown model: $modelId');
    }
    
    if (_downloadProgress[modelId]?.status == ModelStatus.downloading) {
      return; // Already downloading
    }
    
    _downloadProgress[modelId] = DownloadProgress(
      modelId: modelId,
      status: ModelStatus.downloading,
    );
    notifyListeners();
    
    final filePath = path.join(_modelsDirectory!, model.fileName);
    final tempPath = '$filePath.download';
    
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await _httpClient!.send(request);
      
      if (response.statusCode != 200) {
        throw HttpException('Download failed: ${response.statusCode}');
      }
      
      final int totalBytes = response.contentLength ?? model.sizeBytes;
      var downloadedBytes = 0;
      
      final file = File(tempPath);
      final sink = file.openWrite();
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        _downloadProgress[modelId] = DownloadProgress(
          modelId: modelId,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          status: ModelStatus.downloading,
        );
        notifyListeners();
      }
      
      await sink.close();
      
      // Rename temp file to final name
      await File(tempPath).rename(filePath);
      
      _downloadedModels.add(modelId);
      _downloadProgress[modelId] = DownloadProgress(
        modelId: modelId,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        status: ModelStatus.downloaded,
      );
      notifyListeners();
      
    } catch (e) {
      // Clean up temp file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      _downloadProgress[modelId] = DownloadProgress(
        modelId: modelId,
        status: ModelStatus.error,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }
  }

  /// Cancel an ongoing download
  void cancelDownload(String modelId) {
    _httpClient?.close();
    _httpClient = null;
    
    _downloadProgress[modelId] = DownloadProgress(
      modelId: modelId,
      status: ModelStatus.notDownloaded,
    );
    notifyListeners();
    
    // Clean up temp file
    final model = AvailableModels.getById(modelId);
    if (model != null) {
      final tempPath = path.join(_modelsDirectory!, '${model.fileName}.download');
      File(tempPath).delete().ignore();
    }
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String modelId) async {
    final modelPath = getModelPath(modelId);
    if (modelPath == null) return;
    
    final file = File(modelPath);
    if (await file.exists()) {
      await file.delete();
    }
    
    _downloadedModels.remove(modelId);
    _downloadProgress[modelId] = DownloadProgress(
      modelId: modelId,
      status: ModelStatus.notDownloaded,
    );
    
    // Clear active model if it was deleted
    if (_activeModelId == modelId) {
      _activeModelId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_model_id');
    }
    
    notifyListeners();
  }

  /// Set the active model
  Future<void> setActiveModel(String? modelId) async {
    _activeModelId = modelId;
    
    final prefs = await SharedPreferences.getInstance();
    if (modelId != null) {
      await prefs.setString('active_model_id', modelId);
    } else {
      await prefs.remove('active_model_id');
    }
    
    notifyListeners();
  }

  /// Get total storage used by models
  Future<int> getTotalStorageUsed() async {
    int total = 0;
    
    for (final modelId in _downloadedModels) {
      final modelPath = getModelPath(modelId);
      if (modelPath != null) {
        final file = File(modelPath);
        if (await file.exists()) {
          total += await file.length();
        }
      }
    }
    
    return total;
  }
}
