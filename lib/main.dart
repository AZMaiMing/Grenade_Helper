import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'objectbox.dart';
import 'models.dart';
import 'providers.dart';
import 'screens/home_screen.dart'; // 引用首页

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化数据库
  final objectBox = await ObjectBox.create();

  // 2. 检查并预填充地图数据
  await _initMapData(objectBox.store);

  runApp(
    // 3. 注入 Riverpod 和 ObjectBox
    ProviderScope(
      overrides: [
        objectBoxProvider.overrideWithValue(objectBox),
      ],
      child: const MyApp(),
    ),
  );
}

/// 数据预填充逻辑：支持多楼层
Future<void> _initMapData(store) async {
  final mapBox = store.box<GameMap>();

  // 如果数据库为空，则写入默认数据
  if (mapBox.isEmpty()) {
    print("检测到首次运行，正在写入地图数据...");

    final mapsConfig = [
      {
        "name": "Mirage",
        "key": "mirage", // 用于拼接文件名的 key
        "floors": ["mirage.png"], // 平面图文件名
        "floorNames": ["Default"]
      },
      {
        "name": "Inferno",
        "key": "inferno",
        "floors": ["inferno.png"],
        "floorNames": ["Default"]
      },
      {
        "name": "Dust 2",
        "key": "dust2",
        "floors": ["dust2.png"],
        "floorNames": ["Default"]
      },
      {
        "name": "Overpass",
        "key": "overpass",
        "floors": ["overpass.png"],
        "floorNames": ["Default"]
      },
      {
        "name": "Ancient",
        "key": "ancient",
        "floors": ["ancient.png"],
        "floorNames": ["Default"]
      },
      {
        "name": "Anubis",
        "key": "anubis",
        "floors": ["anubis.png"],
        "floorNames": ["Default"]
      },
      {
        "name": "Train",
        "key": "train",
        "floors": ["train.png"],
        "floorNames": ["Default"]
      },
      // --- 多楼层地图 ---
      {
        "name": "Nuke",
        "key": "nuke",
        "floors": ["nuke_lower.png", "nuke_upper.png"],
        "floorNames": ["B Site (Lower)", "A Site (Upper)"]
      },
      {
        "name": "Vertigo",
        "key": "vertigo",
        "floors": ["vertigo_lower.png", "vertigo_upper.png"],
        "floorNames": ["Level 50 (Lower)", "Level 51 (Upper)"]
      },
    ];

    for (var config in mapsConfig) {
      final key = config['key'] as String;
      final map = GameMap(
          name: config['name'] as String,
          backgroundPath: 'assets/backgrounds/${key}_bg.png',
          iconPath: 'assets/icons/${key}_icon.svg');
      final files = config['floors'] as List<String>;
      final layerNames = config['layerNames'] as List<String>?;

      for (int i = 0; i < files.length; i++) {
        final layer = MapLayer(
          // 如果没有自定义层名，就叫 "默认"
          name: layerNames != null ? layerNames[i] : "默认",
          assetPath: "assets/maps/${files[i]}",
          sortOrder: i,
        );
        // 建立关联
        map.layers.add(layer);
      }
      mapBox.put(map);
    }
    print("地图数据写入完成！");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grenade Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF1B1E23),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141619),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(), // 指向首页
    );
  }
}
