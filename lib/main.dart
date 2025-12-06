import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'providers.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Isar 数据库
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      GameMapSchema,
      MapLayerSchema,
      GrenadeSchema,
      GrenadeStepSchema,
      StepMediaSchema
    ],
    directory: dir.path,
  );

  // 2. 检查并预填充地图数据
  await _initMapData(isar);

  runApp(
    // 3. 注入 Riverpod 和 Isar
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const MyApp(),
    ),
  );
}

/// 数据预填充逻辑：支持多楼层
Future<void> _initMapData(Isar isar) async {
  // 如果数据库为空，则写入默认数据
  if (await isar.gameMaps.count() == 0) {
    print("检测到首次运行，正在写入地图数据...");

    final mapsConfig = [
      {
        "name": "Mirage",
        "key": "mirage",
        "floors": ["mirage.png"],
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

    await isar.writeTxn(() async {
      for (var config in mapsConfig) {
        final key = config['key'] as String;
        final map = GameMap(
          name: config['name'] as String,
          backgroundPath: 'assets/backgrounds/${key}_bg.png',
          iconPath: 'assets/icons/${key}_icon.svg',
        );
        await isar.gameMaps.put(map);

        final floors = config['floors'] as List<String>;
        final floorNames = config['floorNames'] as List<String>;

        for (int i = 0; i < floors.length; i++) {
          final layer = MapLayer(
            name: floorNames[i],
            assetPath: "assets/maps/${floors[i]}",
            sortOrder: i,
          );
          await isar.mapLayers.put(layer);

          // 建立关联
          map.layers.add(layer);
        }
        await map.layers.save();
      }
    });
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
      home: const HomeScreen(),
    );
  }
}
