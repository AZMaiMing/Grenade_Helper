import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:isar_community/isar.dart';
import '../models.dart';
import '../providers.dart';
import '../services/data_service.dart';
import 'import_history_detail_screen.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isImporting = false;
  DataService? _dataService;
  List<ImportHistory> _histories = [];
  late TabController _tabController;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final isar = ref.read(isarProvider);
    _dataService = DataService(isar);
    _loadHistories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistories() async {
    final isar = ref.read(isarProvider);
    final histories =
        await isar.importHistorys.where().sortByImportedAtDesc().findAll();
    setState(() => _histories = histories);
  }

  Future<void> _handleImport() async {
    if (_dataService == null) return;

    setState(() => _isImporting = true);
    final result = await _dataService!.importData();
    setState(() => _isImporting = false);

    await _loadHistories(); // 刷新历史列表

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

    await _loadHistories(); // 刷新历史列表
    setState(() => _isImporting = false);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("导入"),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "导入文件"),
              Tab(text: "导入历史"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildImportTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab() {
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

    return body;
  }

  Widget _buildHistoryTab() {
    if (_histories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("暂无导入记录", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _histories.length,
      itemBuilder: (context, index) {
        final history = _histories[index];
        final total = history.newCount + history.updatedCount;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder_zip, color: Colors.green),
            ),
            title: Text(
              history.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(history.importedAt),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (history.newCount > 0)
                      _buildBadge("新增 ${history.newCount}", Colors.green),
                    if (history.updatedCount > 0)
                      _buildBadge("更新 ${history.updatedCount}", Colors.orange),
                  ],
                ),
              ],
            ),
            trailing: Text(
              "$total 个",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ImportHistoryDetailScreen(historyId: history.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
