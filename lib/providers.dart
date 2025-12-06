import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'objectbox.dart';
import 'models.dart';
import 'objectbox.g.dart';

// 全局数据库
final objectBoxProvider =
    Provider<ObjectBox>((ref) => throw UnimplementedError());

// --- 筛选状态 ---
final teamFilterProvider =
    StateProvider.autoDispose<int>((ref) => TeamType.all);
final onlyFavoritesProvider = StateProvider.autoDispose<bool>((ref) => false);
final typeFilterProvider = StateProvider.autoDispose<Set<int>>((ref) => <int>{
      GrenadeType.smoke,
      GrenadeType.flash,
      GrenadeType.molotov,
      GrenadeType.he
    });

// ==================== 核心修改开始 ====================

// 层级 1: 原始数据源 (Raw Data)
// 只负责从数据库取当前楼层的所有数据，不负责筛选。这个流非常稳定，不会频繁重启。
final _rawLayerGrenadesProvider =
    StreamProvider.autoDispose.family<List<Grenade>, int>((ref, layerId) {
  final box = ref.watch(objectBoxProvider).store.box<Grenade>();
  // 只查楼层，不查其他条件
  final query =
      box.query(Grenade_.layer.equals(layerId)).watch(triggerImmediately: true);
  return query.map((q) => q.find());
});

// 层级 2: 逻辑过滤器 (Logic Filter)
// 这是一个同步 Provider (注意是 Provider 不是 StreamProvider)
// 它返回的是 AsyncValue<List<Grenade>>，因为它依赖了上面的流
final filteredGrenadesProvider =
    Provider.autoDispose.family<AsyncValue<List<Grenade>>, int>((ref, layerId) {
  // 1. 监听原始数据流 (如果数据库变了，这里会更新)
  final rawAsync = ref.watch(_rawLayerGrenadesProvider(layerId));

  // 2. 监听筛选器状态 (如果用户点了按钮，这里会立即更新)
  final teamFilter = ref.watch(teamFilterProvider);
  final onlyFav = ref.watch(onlyFavoritesProvider);
  final selectedTypes = ref.watch(typeFilterProvider);

  print("⚡ 触发过滤逻辑: 类型集合=$selectedTypes"); // 这次你一定能看到这行日志

  // 3. 使用 whenData 进行安全的内存过滤
  return rawAsync.whenData((allGrenades) {
    return allGrenades.where((g) {
      // A. 类型筛选
      if (!selectedTypes.contains(g.type)) return false;

      // B. 阵营筛选
      if (teamFilter != TeamType.all && g.team != teamFilter) return false;

      // C. 收藏筛选
      if (onlyFav && !g.isFavorite) return false;

      return true;
    }).toList();
  });
});
// ==================== 核心修改结束 ====================
