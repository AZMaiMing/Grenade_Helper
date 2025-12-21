/// 云端道具包模型
class CloudPackage {
  final String id;
  final String name;
  final String description;
  final String author;
  final String? map; // null = 全图
  final int count;
  final String updated; // 最后更新日期
  final String url; // 相对于仓库根目录的路径
  final String? size;

  CloudPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    this.map,
    required this.count,
    required this.updated,
    required this.url,
    this.size,
  });

  factory CloudPackage.fromJson(Map<String, dynamic> json) {
    return CloudPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? '未知',
      map: json['map'] as String?,
      count: json['count'] as int? ?? 0,
      updated: json['updated'] as String? ?? '',
      url: json['url'] as String,
      size: json['size'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'author': author,
        'map': map,
        'count': count,
        'updated': updated,
        'url': url,
        'size': size,
      };
}

/// 云端仓库索引
class CloudPackageIndex {
  final int version;
  final List<CloudPackage> packages;

  CloudPackageIndex({
    required this.version,
    required this.packages,
  });

  factory CloudPackageIndex.fromJson(Map<String, dynamic> json) {
    return CloudPackageIndex(
      version: json['version'] as int? ?? 1,
      packages: (json['packages'] as List<dynamic>?)
              ?.map((e) => CloudPackage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
