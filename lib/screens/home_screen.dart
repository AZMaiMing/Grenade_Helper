import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'map_screen.dart';
import 'grenade_detail_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'share_screen.dart';

// 全局搜索逻辑
class GlobalSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  GlobalSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) return const SizedBox();

    final store = ref.read(objectBoxProvider).store;
    // 模糊搜索：标题包含 query
    final results = store.box<Grenade>().getAll().where((g) {
      return g.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, index) {
        final g = results[index];
        final mapName = g.layer.target?.map.target?.name ?? "";
        return ListTile(
          leading: const Icon(Icons.ads_click),
          title: Text(g.title),
          subtitle: Text(mapName,
              style: const TextStyle(color: Colors.orange)), // 地图名后缀
          onTap: () {
            // 直接跳转详情
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GrenadeDetailScreen(
                        grenadeId: g.id, isEditing: false)));
          },
        );
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(objectBoxProvider).store;
    final maps = store.box<GameMap>().getAll();

    return Scaffold(
      // --- 1. 搜索栏 (作为 Appbar Title) ---
      appBar: AppBar(
        title: GestureDetector(
          onTap: () =>
              showSearch(context: context, delegate: GlobalSearchDelegate(ref)),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 8),
                Text("搜索道具...",
                    style: TextStyle(color: Colors.grey, fontSize: 14))
              ],
            ),
          ),
        ),
      ),
      // --- 2. 侧边栏 ---
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
                child: Center(
                    child: Text("Grenade Helper",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)))),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text("分享 / 导入"), // 修改文案
              onTap: () {
                Navigator.pop(context); // 收起侧边栏
                // 跳转到新的分享页面
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ShareScreen()));
              },
            ),
          ],
        ),
      ),
      // --- 3. 地图大图卡片 ---
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: maps.length,
        itemBuilder: (ctx, index) {
          final map = maps[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MapScreen(gameMap: map))),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage(map.backgroundPath), // 使用大图背景
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4), BlendMode.darken),
                )),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        map.iconPath,
                        width: 40,
                        height: 40,
                      ), // 地图 Logo
                      const SizedBox(width: 16),
                      Text(map.name,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
