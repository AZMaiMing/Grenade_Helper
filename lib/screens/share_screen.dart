import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../models.dart';
import '../providers.dart';
import '../services/data_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  // 缓存数据，避免在 build 中使用同步查询
  List<GameMap> _maps = [];
  List<Grenade> _grenades = [];
  DataService? _dataService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 直接在 initState 中初始化数据服务
    final isar = ref.read(isarProvider);
    _dataService = DataService(isar);
    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final isar = ref.read(isarProvider);
    setState(() {
      _maps = isar.gameMaps.where().findAllSync();
      _grenades = isar.grenades.where().findAllSync();
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果还未初始化完成，显示加载指示器
    if (!_isInitialized || _dataService == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("分享")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 不再在 build 中使用 findAllSync()，使用缓存的数据
    final body = TabBarView(
      children: [
        _buildSingleGrenadeList(context, _grenades, _dataService!),
        _buildMapList(context, _maps, _dataService!),
        _buildAllDataView(context, _grenades.length, _dataService!),
      ],
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("分享"),
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "单个道具"),
              Tab(text: "整张地图"),
              Tab(text: "全部数据"),
            ],
          ),
        ),
        body: body,
      ),
    );
  }

  Widget _buildSingleGrenadeList(
      BuildContext context, List<Grenade> list, DataService service) {
    if (list.isEmpty) {
      return _buildEmptyWithDragHint("暂无道具数据");
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          Divider(color: Theme.of(context).dividerColor),
      itemBuilder: (ctx, index) {
        final g = list[index];
        g.layer.loadSync();
        g.layer.value?.map.loadSync();
        final mapName = g.layer.value?.map.value?.name ?? "";
        final layerName = g.layer.value?.name ?? "";
        return ListTile(
          title: Text(g.title),
          subtitle: Text("$mapName - $layerName"),
          trailing: IconButton(
            icon: const Icon(Icons.share, color: Colors.blueAccent),
            onPressed: () async {
              await service.exportData(context, scopeType: 0, singleGrenade: g);
            },
          ),
        );
      },
    );
  }

  Widget _buildMapList(
      BuildContext context, List<GameMap> maps, DataService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: maps.length,
      itemBuilder: (ctx, index) {
        final map = maps[index];
        map.layers.loadSync();
        int count = 0;
        for (var layer in map.layers) {
          layer.grenades.loadSync();
          count += layer.grenades.length;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: SvgPicture.asset(map.iconPath, width: 40, height: 40),
            title: Text(map.name,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text("包含 $count 个道具",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text("导出"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (count == 0) return;
                await service.exportData(context, scopeType: 1, singleMap: map);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllDataView(
      BuildContext context, int count, DataService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.backup, size: 80, color: Colors.greenAccent),
          const SizedBox(height: 20),
          Text("数据库中共有 $count 个道具", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              if (count == 0) return;
              await service.exportData(context, scopeType: 2);
            },
            icon: const Icon(Icons.share),
            label: const Text("一键分享全部数据 (.cs2pkg)",
                style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "这将打包所有地图、所有楼层的所有道具及图片视频，生成一个备份文件。",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWithDragHint(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}
