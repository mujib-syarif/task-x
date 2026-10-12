import '../utils/json_utils.dart';

class CategoryUsage {
  const CategoryUsage({required this.name, required this.bytes, required this.count});

  final String name;
  final int bytes;
  final int count;

  factory CategoryUsage.fromMap(Map<String, dynamic> m) => CategoryUsage(
        name: asString(m['name']) ?? '—',
        bytes: asInt(m['bytes']) ?? 0,
        count: asInt(m['count']) ?? 0,
      );
}

class LargeFile {
  const LargeFile({required this.name, required this.size, required this.mime, required this.uri});

  final String name;
  final int size;
  final String mime;
  final String uri;

  factory LargeFile.fromMap(Map<String, dynamic> m) => LargeFile(
        name: asString(m['name']) ?? '—',
        size: asInt(m['size']) ?? 0,
        mime: asString(m['mime']) ?? '*/*',
        uri: asString(m['uri']) ?? '',
      );
}

class ScanResult {
  const ScanResult({
    required this.totalBytes,
    required this.fileCount,
    required this.truncated,
    required this.categories,
    required this.files,
  });

  final int totalBytes;
  final int fileCount;
  final bool truncated;
  final List<CategoryUsage> categories;
  final List<LargeFile> files;

  factory ScanResult.fromMap(Map<String, dynamic> m) => ScanResult(
        totalBytes: asInt(m['totalBytes']) ?? 0,
        fileCount: asInt(m['fileCount']) ?? 0,
        truncated: m['truncated'] == true,
        categories: asMapList(m['categories']).map(CategoryUsage.fromMap).toList(),
        files: asMapList(m['files']).map(LargeFile.fromMap).toList(),
      );
}
