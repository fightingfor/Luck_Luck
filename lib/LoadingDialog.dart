import 'package:flutter/material.dart';

class LoadingDialog {
  static BuildContext? _context;

  // 显示加载对话框
  static void show(BuildContext context) {
    if (_context != null) return; // 防止重复弹出

    showDialog(
      context: context,
      barrierDismissible: false, // 点击外部不关闭
      builder: (BuildContext context) {
        _context = context;
        return WillPopScope(
          onWillPop: () async => false, // 禁止返回按钮关闭
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  // 隐藏加载对话框
  static void hide() {
    if (_context != null) {
      Navigator.of(_context!).pop();
      _context = null;
    }
  }
}
