import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudSyncProvider extends ChangeNotifier {
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  CloudSyncProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('lastSyncTime');
    if (lastSyncStr != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncStr);
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastSyncTime != null) {
      await prefs.setString('lastSyncTime', _lastSyncTime!.toIso8601String());
    }
  }

  Future<bool> exportBackup(String jsonData) async {
    _isSyncing = true;
    notifyListeners();
    try {
      if (kIsWeb) {
         print('Export is not fully supported on web yet without dart:html');
         _isSyncing = false;
         notifyListeners();
         return false; // Skip for now so it compiles
      }
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'schonotes_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (outputFile != null) {
        final file = io.File(outputFile);
        await file.writeAsString(jsonData);
        _lastSyncTime = DateTime.now();
        _saveState();
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Export error: $e');
    }
    _isSyncing = false;
    notifyListeners();
    return false;
  }

  Future<String?> importBackup() async {
    _isSyncing = true;
    notifyListeners();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        String data = '';
        if (kIsWeb) {
           final bytes = result.files.single.bytes;
           if (bytes != null) {
              data = utf8.decode(bytes);
           } else {
             throw Exception("No bytes found in web file picker");
           }
        } else {
           if (result.files.single.path != null) {
              final file = io.File(result.files.single.path!);
              data = await file.readAsString();
           } else {
             throw Exception("No path found in file picker");
           }
        }
        _lastSyncTime = DateTime.now();
        _saveState();
        _isSyncing = false;
        notifyListeners();
        return data;
      }
    } catch (e) {
      print('Import error: $e');
    }
    _isSyncing = false;
    notifyListeners();
    return null;
  }
}
