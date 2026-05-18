import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// 收據照片：選/拍 + 存到 App 私有目錄
class ReceiptService {
  final _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (picked == null) return null;
    return _copyToReceiptsDir(picked);
  }

  Future<String?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (picked == null) return null;
    return _copyToReceiptsDir(picked);
  }

  Future<String> _copyToReceiptsDir(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(dir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final ext = p.extension(file.path).toLowerCase().isEmpty
        ? '.jpg'
        : p.extension(file.path).toLowerCase();
    final name = '${const Uuid().v4()}$ext';
    final dest = File(p.join(receiptsDir.path, name));
    await dest.writeAsBytes(await file.readAsBytes());
    return dest.path;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {/* ignore */}
  }
}
