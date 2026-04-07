import 'dart:io';
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
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'schonotes_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (outputFile != null) {
        final File file = File(outputFile);
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
      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final data = await file.readAsString();
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
