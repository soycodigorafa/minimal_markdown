import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/models/recent_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

final recentFilesProvider =
    StateNotifierProvider<RecentFilesNotifier, List<RecentFile>>(
  (ref) => RecentFilesNotifier(),
);

class RecentFilesNotifier extends StateNotifier<List<RecentFile>> {
  RecentFilesNotifier() : super([]) {
    _loadRecentFiles();
  }

  static const String _prefsKey = 'recent_files';
  static const int _maxRecentFiles = 10;

  Future<void> _loadRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFilesJson = prefs.getStringList(_prefsKey) ?? [];
      
      final recentFiles = recentFilesJson
          .map((fileJson) => RecentFile.fromJson(fileJson))
          .toList();
      
      // Sort by most recently opened
      recentFiles.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      
      state = recentFiles;
    } catch (e) {
      debugPrint('Error loading recent files: $e');
      state = [];
    }
  }

  Future<void> _saveRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFilesJson = state.map((file) => file.toJson()).toList();
      await prefs.setStringList(_prefsKey, recentFilesJson);
    } catch (e) {
      debugPrint('Error saving recent files: $e');
    }
  }

  Future<void> addRecentFile(String filePath) async {
    if (filePath.isEmpty) return;

    final fileName = path.basename(filePath);
    final now = DateTime.now();

    // Check if file already exists in recent files
    final existingIndex = state.indexWhere((file) => file.path == filePath);
    
    if (existingIndex >= 0) {
      // Update existing entry with new timestamp
      final updatedList = List<RecentFile>.from(state);
      updatedList[existingIndex] = updatedList[existingIndex].copyWith(
        lastOpened: now,
      );
      state = updatedList;
    } else {
      // Add new entry
      final newFile = RecentFile(
        path: filePath,
        name: fileName,
        lastOpened: now,
      );
      
      final updatedList = [newFile, ...state];
      
      // Limit to max number of recent files
      if (updatedList.length > _maxRecentFiles) {
        updatedList.removeLast();
      }
      
      state = updatedList;
    }
    
    await _saveRecentFiles();
  }

  Future<void> removeRecentFile(String filePath) async {
    state = state.where((file) => file.path != filePath).toList();
    await _saveRecentFiles();
  }

  Future<void> clearRecentFiles() async {
    state = [];
    await _saveRecentFiles();
  }
}
