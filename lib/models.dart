import 'package:objectbox/objectbox.dart';

// --- 1. 常量定义 (修复报错的关键) ---

class GrenadeType {
  static const int smoke = 0;
  static const int flash = 1;
  static const int molotov = 2;
  static const int he = 3;
}

class TeamType {
  static const int all = 0;
  static const int ct = 1; // 警
  static const int t = 2;  // 匪
}

class MediaType {
  static const int image = 0;
  static const int video = 1;
}

// --- 2. 数据库实体定义 ---

@Entity()
class GameMap {
  @Id()
  int id = 0;

  String name;
  String backgroundPath; // 大图背景 (新增)
  String iconPath;       // 标志图标 (新增)

  @Backlink()
  final layers = ToMany<MapLayer>();

  GameMap({
    required this.name,
    this.backgroundPath = "", // 给个默认值防止旧数据报错
    this.iconPath = "",
  });
}

@Entity()
class MapLayer {
  @Id()
  int id = 0;

  String name;
  String assetPath;
  int sortOrder;

  final map = ToOne<GameMap>();

  @Backlink()
  final grenades = ToMany<Grenade>();

  MapLayer({
    required this.name,
    required this.assetPath,
    required this.sortOrder,
  });
}

@Entity()
class Grenade {
  @Id()
  int id = 0;

  String title;
  int type; // 对应 GrenadeType
  int team; // 对应 TeamType
  bool isFavorite;

  // --- 新增字段 ---
  bool isNewImport; // 是否为新导入 (红点)
  DateTime createdAt; // 创建时间
  DateTime updatedAt; // 最后编辑时间

  // 坐标 (0.0 ~ 1.0)
  double xRatio;
  double yRatio;

  final layer = ToOne<MapLayer>();

  @Backlink()
  final steps = ToMany<GrenadeStep>();

  Grenade({
    required this.title,
    required this.type,
    this.team = 0,
    this.isFavorite = false,
    this.isNewImport = false,
    required this.xRatio,
    required this.yRatio,
    DateTime? created,
    DateTime? updated,
  })  : createdAt = created ?? DateTime.now(),
        updatedAt = updated ?? DateTime.now();
}

@Entity()
class GrenadeStep {
  @Id()
  int id = 0;

  String title; // 步骤标题 (如: 站位)
  String description;
  int stepIndex; // 排序用

  // 关联多个媒体文件 (实现单一步骤多图)
  @Backlink()
  final medias = ToMany<StepMedia>();

  final grenade = ToOne<Grenade>();

  GrenadeStep({
    this.title = "", // 默认为空
    required this.description,
    required this.stepIndex,
  });
}

@Entity()
class StepMedia {
  @Id()
  int id = 0;

  String localPath; // 本地路径
  int type; // 0:Image, 1:Video (对应 MediaType)

  final step = ToOne<GrenadeStep>();

  StepMedia({
    required this.localPath,
    required this.type,
  });
}