import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'objectbox.g.dart'; // 运行 build_runner 后生成的文件

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store);

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // ObjectBox 数据库存储路径
    final store = await openStore(directory: p.join(docsDir.path, "cs2-helper-db"));
    return ObjectBox._create(store);
  }
}