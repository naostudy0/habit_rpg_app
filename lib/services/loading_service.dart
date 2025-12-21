import 'package:flutter/material.dart';

/// ローディング状態管理サービス
class LoadingService extends ChangeNotifier {
  static final LoadingService _instance = LoadingService._internal();
  factory LoadingService() => _instance;
  LoadingService._internal();

  // 各操作のローディング状態を管理（キーは操作名）
  final Map<String, bool> _loadingStates = {};

  // グローバルなローディング状態
  bool _isGlobalLoading = false;

  /// グローバルなローディング状態を取得
  bool get isGlobalLoading => _isGlobalLoading;

  /// 特定の操作がローディング中かどうかを取得
  bool isLoading(String operation) {
    return _loadingStates[operation] ?? false;
  }

  /// いずれかの操作がローディング中かどうかを取得
  bool get isAnyLoading {
    return _isGlobalLoading || _loadingStates.values.any((loading) => loading);
  }

  /// グローバルなローディング状態を設定
  void setGlobalLoading(bool loading) {
    if (_isGlobalLoading != loading) {
      _isGlobalLoading = loading;
      notifyListeners();
    }
  }

  /// 特定の操作のローディング状態を設定
  void setLoading(String operation, bool loading) {
    if (_loadingStates[operation] != loading) {
      _loadingStates[operation] = loading;
      notifyListeners();
    }
  }

  /// すべてのローディング状態をクリア
  void clearAll() {
    _loadingStates.clear();
    _isGlobalLoading = false;
    notifyListeners();
  }

  /// 特定の操作のローディング状態をクリア
  void clear(String operation) {
    if (_loadingStates.containsKey(operation)) {
      _loadingStates.remove(operation);
      notifyListeners();
    }
  }
}
