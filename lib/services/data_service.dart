import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';
import '../objectbox.g.dart';

class DataService {
  final Store store;
  DataService(this.store);

  // --- 导出 (分享) ---

  // scopeType: 0=SingleGrenade, 1=SingleMap, 2=All
  Future<void> exportData(BuildContext context,
      {required int scopeType,
      Grenade? singleGrenade,
      GameMap? singleMap}) async {
    final grenades = <Grenade>[];

    // 1. 确定要导出的数据范围
    if (scopeType == 0 && singleGrenade != null) {
      grenades.add(singleGrenade);
    } else if (scopeType == 1 && singleMap != null) {
      for (var layer in singleMap.layers) {
        grenades.addAll(layer.grenades);
      }
    } else {
      grenades.addAll(store.box<Grenade>().getAll());
    }

    if (grenades.isEmpty) return; // 无数据

    // 2. 构建 JSON 数据结构
    final List<Map<String, dynamic>> exportList = [];
    final Set<String> filesToZip = {}; // 需要打包的文件路径

    for (var g in grenades) {
      final stepsData = <Map<String, dynamic>>[];
      for (var s in g.steps) {
        final mediaData = <Map<String, dynamic>>[];
        for (var m in s.medias) {
          mediaData.add({
            'path': p.basename(m.localPath), // 只存文件名
            'type': m.type
          });
          filesToZip.add(m.localPath); // 记录绝对路径
        }
        stepsData.add({
          'title': s.title,
          'description': s.description,
          'index': s.stepIndex,
          'medias': mediaData,
        });
      }

      exportList.add({
        'mapName': g.layer.target?.map.target?.name ?? "Unknown", // 用于导入时匹配
        'layerName': g.layer.target?.name ?? "Default",
        'title': g.title,
        'type': g.type,
        'team': g.team,
        'x': g.xRatio,
        'y': g.yRatio,
        'steps': stepsData,
        'createdAt': g.createdAt.millisecondsSinceEpoch,
        'updatedAt': g.updatedAt.millisecondsSinceEpoch,
      });
    }

    // 3. 创建临时打包目录
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(tempDir.path, "export_temp"));
    if (exportDir.existsSync()) exportDir.deleteSync(recursive: true);
    exportDir.createSync();

    // 4. 写入 data.json
    final jsonFile = File(p.join(exportDir.path, "data.json"));
    jsonFile.writeAsStringSync(jsonEncode(exportList));

    // 5. 复制媒体文件
    for (var path in filesToZip) {
      final file = File(path);
      if (file.existsSync()) {
        file.copySync(p.join(exportDir.path, p.basename(path)));
      }
    }

    // 6. 压缩为 .cs2pkg (Zip)
    final encoder = ZipFileEncoder();
    final zipPath = p.join(tempDir.path, "share_data.cs2pkg");
    encoder.create(zipPath);
    encoder.addDirectory(exportDir);
    encoder.close();
    if (!context.mounted) return;

    // 弹出底部菜单让用户选
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2D33), // 深色背景适配你的主题
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Text("选择导出方式",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // 选项 1：系统分享
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blueAccent),
              title: const Text("系统分享 (微信/QQ)",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx); // 关闭弹窗
                // 原来的分享逻辑移到这里
                Share.shareXFiles([XFile(zipPath)], text: "CS2 道具数据分享");
              },
            ),
            // 选项 2：保存到文件夹
            ListTile(
              leading:
                  const Icon(Icons.folder_open, color: Colors.orangeAccent),
              title:
                  const Text("保存到手机文件夹", style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx); // 关闭弹窗
                // 调用下面定义的新方法
                await _saveToFolder(context, zipPath);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 导入 ---

  Future<String> importData() async {
    // 1. 选择文件
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择要导入的 .cs2pkg 文件',
    );
    if (result == null) return "取消导入";

    final filePath = result.files.single.path!;

    // 检查文件扩展名
    if (!filePath.toLowerCase().endsWith('.cs2pkg')) {
      return "请选择 .cs2pkg 格式的文件";
    }

    final file = File(filePath);
    final appDocDir = await getApplicationDocumentsDirectory();

    // 2. 解压
    final bytes = file.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    List<dynamic> jsonData = [];
    final Map<String, List<int>> memoryImages = {}; // 文件名 -> 字节数据

    for (var file in archive) {
      // 处理目录前缀问题：export_temp/data.json -> data.json
      final fileName = p.basename(file.name);
      if (fileName == "data.json") {
        jsonData = jsonDecode(utf8.decode(file.content as List<int>));
      } else {
        if (file.isFile && file.content != null) {
          memoryImages[fileName] = file.content as List<int>;
        }
      }
    }

    if (jsonData.isEmpty) return "文件格式错误或无数据";

    // 3. 写入数据库
    int count = 0;
    int skipped = 0;
    final mapBox = store.box<GameMap>();
    final grenadeBox = store.box<Grenade>();

    store.runInTransaction(TxMode.write, () {
      for (var item in jsonData) {
        // A. 匹配地图与楼层
        final mapName = item['mapName'];
        final layerName = item['layerName'];

        // 简单匹配：按名字找地图，找不到就跳过 (为了安全)
        final mapQuery = mapBox.query(GameMap_.name.equals(mapName)).build();
        final map = mapQuery.findFirst();
        mapQuery.close();

        if (map == null) continue; // 没这地图就不导入

        final layer = map.layers.firstWhere((l) => l.name == layerName,
            orElse: () => map.layers.first);

        // B. 检查是否已存在相同道具 (根据标题、楼层、坐标判断)
        final title = item['title'] as String;
        final xRatio = item['x'] as double;
        final yRatio = item['y'] as double;

        final existingQuery = grenadeBox
            .query(Grenade_.title
                .equals(title)
                .and(Grenade_.layer.equals(layer.id))
                .and(Grenade_.xRatio.between(xRatio - 0.01, xRatio + 0.01))
                .and(Grenade_.yRatio.between(yRatio - 0.01, yRatio + 0.01)))
            .build();
        final existing = existingQuery.findFirst();
        existingQuery.close();

        if (existing != null) {
          skipped++;
          continue; // 已存在相同道具，跳过
        }

        // C. 创建 Grenade
        final g = Grenade(
          title: title,
          type: item['type'],
          team: item['team'],
          xRatio: xRatio,
          yRatio: yRatio,
          isNewImport: true, // 标记为新导入
          created: DateTime.fromMillisecondsSinceEpoch(item['createdAt']),
          updated: DateTime.now(), // 导入时间为更新时间
        );
        g.layer.target = layer;

        // D. 创建 Steps & Medias
        final stepsList = item['steps'] as List;
        for (var sItem in stepsList) {
          final step = GrenadeStep(
            title: sItem['title'] ?? "",
            description: sItem['description'],
            stepIndex: sItem['index'],
          );

          final mediasList = sItem['medias'] as List;
          for (var mItem in mediasList) {
            final fileName = mItem['path'];
            if (memoryImages.containsKey(fileName)) {
              // 将内存图片写入本地
              final savePath = p.join(appDocDir.path,
                  "${DateTime.now().millisecondsSinceEpoch}_$fileName");
              File(savePath).writeAsBytesSync(memoryImages[fileName]!);

              step.medias
                  .add(StepMedia(localPath: savePath, type: mItem['type']));
            }
          }
          g.steps.add(step);
        }
        grenadeBox.put(g);
        count++;
      }
    });

    if (count == 0 && skipped > 0) {
      return "所有 $skipped 个道具已存在，无需导入";
    } else if (skipped > 0) {
      return "成功导入 $count 个道具，跳过 $skipped 个已存在";
    }
    return "成功导入 $count 个道具";
  }

  Future<void> _saveToFolder(BuildContext context, String sourcePath) async {
    // 1. 调起系统文件选择器，让用户选目录
    String? outputDirectory =
        await FilePicker.platform.getDirectoryPath(dialogTitle: "请选择保存位置");

    if (outputDirectory == null) {
      return; // 用户取消了
    }

    try {
      // 2. 生成目标文件名 (带时间戳防止重名)
      final fileName =
          "cs2_tactics_backup_${DateTime.now().millisecondsSinceEpoch}.cs2pkg";
      final destination = p.join(outputDirectory, fileName);

      // 3. 复制文件
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destination);

      // 4. 提示成功
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("文件已保存至:\n$destination"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      // 5. 提示失败
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("保存失败: $e"), backgroundColor: Colors.red));
      }
    }
  }
}
