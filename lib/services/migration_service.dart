import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

/// 迁移服务
class MigrationService {
  final Isar isar;
  const MigrationService(this.isar);

  /// 生成UUID
  Future<int> migrateGrenadeUuids() async {
    // 查找空ID
    final allGrenades = await isar.grenades.where().findAll();
    final grenadesNeedingUuid = allGrenades
        .where((g) => g.uniqueId == null || g.uniqueId!.isEmpty)
        .toList();

    if (grenadesNeedingUuid.isEmpty) return 0;

    const uuid = Uuid();
    await isar.writeTxn(() async {
      for (final g in grenadesNeedingUuid) {
        // 加载关联
        await g.layer.load();
        await g.steps.load();

        // 生成
        g.uniqueId = uuid.v4();

        // 保存
        await isar.grenades.put(g);

        // 保存关联
        await g.layer.save();
        await g.steps.save();
      }
    });

    return grenadesNeedingUuid.length;
  }
}
