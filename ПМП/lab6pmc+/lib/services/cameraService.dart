import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> takePhoto() async {
    try {
      // Запрашиваем разрешение на камеру
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return null;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Используем фронтальную камеру
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      return photo?.path;
    } catch (e) {
      print("Camera error: $e");
      return null;
    }
  }
}