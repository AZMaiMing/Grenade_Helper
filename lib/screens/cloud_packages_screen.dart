import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cloud_package.dart';
import '../services/cloud_package_service.dart';
import '../services/data_service.dart';
import '../providers.dart';

class CloudPackagesScreen extends ConsumerStatefulWidget {
  const CloudPackagesScreen({super.key});

  @override
  ConsumerState<CloudPackagesScreen> createState() =>
      _CloudPackagesScreenState();
}

class _CloudPackagesScreenState extends ConsumerState<CloudPackagesScreen> {
  List<CloudPackage>? _packages;
  bool _isLoading = true;
  String? _error;
  String _selectedMap = 'all'; // 'all' = 全部
  final Set<String> _downloadingIds = {};
  final Map<String, String?> _lastImportedDates = {};

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final index = await CloudPackageService.fetchIndex();
    if (index != null) {
      // 获取每个包的上次导入版本
      for (final pkg in index.packages) {
        _lastImportedDates[pkg.id] =
            await CloudPackageService.getLastImportedVersion(pkg.id);
      }
      setState(() {
        _packages = index.packages;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = '无法连接到云端仓库';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndImport(CloudPackage pkg) async {
    setState(() => _downloadingIds.add(pkg.id));

    try {
      // 下载文件
      final filePath = await CloudPackageService.downloadPackage(pkg.url);
      if (filePath == null) {
        _showMessage('下载失败');
        return;
      }

      // 导入
      final isar = ref.read(isarProvider);
      final dataService = DataService(isar);
      final resultMsg = await dataService.importFromPath(filePath);

      // 标记已导入（保存版本号）
      await CloudPackageService.markPackageImported(pkg.id, pkg.version);
      _lastImportedDates[pkg.id] = pkg.version;

      _showMessage(resultMsg);
    } catch (e) {
      _showMessage('导入失败: $e');
    } finally {
      setState(() => _downloadingIds.remove(pkg.id));
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  List<CloudPackage> get _filteredPackages {
    if (_packages == null) return [];
    return CloudPackageService.filterByMap(_packages!, _selectedMap);
  }

  List<String> get _availableMaps {
    if (_packages == null) return [];
    return ['all', ...CloudPackageService.getAvailableMaps(_packages!)];
  }

  String _getMapDisplayName(String map) {
    if (map == 'all') return '全部地图';
    return map[0].toUpperCase() + map.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线道具库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadPackages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildPackageList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPackages,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList() {
    final filtered = _filteredPackages;

    return Column(
      children: [
        // 地图筛选器
        if (_availableMaps.length > 1)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableMaps.length,
              itemBuilder: (ctx, i) {
                final map = _availableMaps[i];
                final isSelected = _selectedMap == map;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: FilterChip(
                    label: Text(_getMapDisplayName(map)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedMap = map),
                    selectedColor: Colors.orange.withOpacity(0.3),
                    checkmarkColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
        // 包列表
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('暂无道具包', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildPackageCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(CloudPackage pkg) {
    final isDownloading = _downloadingIds.contains(pkg.id);
    final lastImportedVersion = _lastImportedDates[pkg.id];
    // 使用版本号比较
    final isUpToDate = lastImportedVersion != null &&
        CloudPackageService.compareVersion(lastImportedVersion, pkg.version) >=
            0;
    final hasUpdate = lastImportedVersion != null && !isUpToDate;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 地图图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                pkg.map == null ? Icons.public : Icons.map,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pkg.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (hasUpdate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '有更新',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pkg.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag(Icons.person, pkg.author),
                      const SizedBox(width: 8),
                      _buildTag(Icons.tag, 'v${pkg.version}'),
                      const SizedBox(width: 8),
                      _buildTag(Icons.update, pkg.updated),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 下载按钮
            isDownloading
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: () => _downloadAndImport(pkg),
                    icon: Icon(
                      isUpToDate ? Icons.check_circle : Icons.download,
                      color: isUpToDate ? Colors.green : Colors.orange,
                    ),
                    tooltip: isUpToDate ? '已是最新' : '下载',
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
