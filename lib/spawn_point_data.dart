/// 出生点数据模型和内置数据

/// 单个出生点
class SpawnPoint {
  final int id; // 编号 1-5
  final double x; // X比例坐标 (0-1)
  final double y; // Y比例坐标 (0-1)

  const SpawnPoint(this.id, this.x, this.y);
}

/// 地图出生点配置
class MapSpawnConfig {
  final List<SpawnPoint> ctSpawns; // CT方出生点列表
  final List<SpawnPoint> tSpawns; // T方出生点列表

  const MapSpawnConfig({
    required this.ctSpawns,
    required this.tSpawns,
  });
}

/// 内置出生点数据
///
/// 使用 tools/spawn_picker.html 工具生成数据后粘贴到这里
/// 键名应与地图名称匹配（小写）
const Map<String, MapSpawnConfig> spawnPointData = {
  // 示例数据（请使用坐标拾取工具替换为实际数据）
  'mirage': MapSpawnConfig(
    ctSpawns: [
      SpawnPoint(1, 0.2842, 0.7247),
      SpawnPoint(2, 0.2808, 0.6816),
      SpawnPoint(3, 0.2873, 0.7022),
      SpawnPoint(4, 0.2989, 0.6797),
      SpawnPoint(5, 0.2995, 0.725)
    ],
    tSpawns: [
      SpawnPoint(1, 0.8821, 0.4047),
      SpawnPoint(2, 0.8809, 0.3127),
      SpawnPoint(3, 0.8659, 0.3263),
      SpawnPoint(4, 0.8662, 0.3539),
      SpawnPoint(5, 0.8659, 0.3805),
      SpawnPoint(6, 0.8659, 0.4039),
      SpawnPoint(7, 0.8512, 0.3805),
      SpawnPoint(8, 0.8507, 0.3639),
      SpawnPoint(9, 0.8504, 0.3387),
      SpawnPoint(10, 0.8507, 0.3166)
    ],
  ),
};
