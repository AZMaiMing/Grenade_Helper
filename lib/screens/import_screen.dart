import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../providers.dart';
import '../services/data_service.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isDragging = false;
  bool _isImporting = false;
  DataService? _dataService;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    final isar = ref.read(isarProvider);
    _dataService = DataService(isar);
  }

  Future<void> _handleImport() async {
    if (_dataService == null) return;

    setState(() => _isImporting = true);
    final result = await _dataService!.importData();
    setState(() => _isImporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: result.contains("成功") ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleFileDrop(List<String> filePaths) async {
    if (_dataService == null) return;

    setState(() => _isImporting = true);

    for (final filePath in filePaths) {
      if (filePath.toLowerCase().endsWith('.cs2pkg')) {
        final result = await _dataService!.importFromPath(filePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor:
                  result.contains("成功") ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    }

    setState(() => _isImporting = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_download,
              size: 100,
              color: Colors.greenAccent.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            const Text(
              "导入道具数据",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _isDesktop
                  ? "点击下方按钮选择文件，或直接拖拽 .cs2pkg 文件到此页面"
                  : "点击下方按钮选择 .cs2pkg 文件进行导入",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _handleImport,
              icon: const Icon(Icons.folder_open),
              label: const Text("选择文件", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "支持的文件格式",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          ".cs2pkg",
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 桌面端添加拖拽支持
    if (_isDesktop) {
      body = DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) async {
          setState(() => _isDragging = false);
          await _handleFileDrop(details.files.map((f) => f.path).toList());
        },
        child: Stack(
          children: [
            body,
            if (_isDragging)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_download,
                        size: 80,
                        color: Colors.orange.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '释放以导入 .cs2pkg 文件',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isImporting)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        '正在导入...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (_isImporting) {
      // 移动端显示加载遮罩
      body = Stack(
        children: [
          body,
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    '正在导入...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("导入")),
      body: body,
    );
  }
}
