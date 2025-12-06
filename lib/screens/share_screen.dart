import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../services/data_service.dart'; // 确保引入了 DataService
import 'package:flutter_svg/flutter_svg.dart';

class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(objectBoxProvider).store;
    final maps = store.box<GameMap>().getAll();
    final grenades = store.box<Grenade>().getAll();
    final dataService = DataService(store);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("导入与分享"),
          actions: [
            // 导入按钮
            IconButton(
              icon: const Icon(Icons.file_download, color: Colors.greenAccent),
              tooltip: "导入数据",
              onPressed: () async {
                final result = await dataService.importData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor:
                          result.contains("成功") ? Colors.green : Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
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
        body: TabBarView(
          children: [
            // Tab 1: 分享单个道具
            _buildSingleGrenadeList(context, grenades, dataService),

            // Tab 2: 分享整张地图
            _buildMapList(context, maps, dataService),

            // Tab 3: 分享全部
            _buildAllDataView(context, grenades.length, dataService),
          ],
        ),
      ),
    );
  }

  // 1. 单个道具列表
  Widget _buildSingleGrenadeList(
      BuildContext context, List<Grenade> list, DataService service) {
    if (list.isEmpty) return const Center(child: Text("暂无道具数据"));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (ctx, index) {
        final g = list[index];
        return ListTile(
          title: Text(g.title),
          subtitle: Text(
              "${g.layer.target?.map.target?.name} - ${g.layer.target?.name}"),
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

  // 2. 地图列表
  Widget _buildMapList(
      BuildContext context, List<GameMap> maps, DataService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: maps.length,
      itemBuilder: (ctx, index) {
        final map = maps[index];
        // 计算该地图下的道具数量
        int count = 0;
        for (var layer in map.layers) {
          count += layer.grenades.length;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: SvgPicture.asset(map.iconPath,
                width: 40, height: 40 // 建议加上白色滤镜，更好看
                ),
            title: Text(map.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text("包含 $count 个道具",
                style: const TextStyle(color: Colors.grey)),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open, size: 16), // 图标改成文件夹
              label: const Text("导出"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                if (count == 0) return;
                // 调用新的导出方法
                await service.exportData(context, scopeType: 1, singleMap: map);
              },
            ),
          ),
        );
      },
    );
  }

  // 3. 全部数据
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
              await service.exportData(context, scopeType: 2); // 2: All
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
          )
        ],
      ),
    );
  }
}
