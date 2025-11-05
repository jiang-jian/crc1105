import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes/router_config.dart';

class HomeController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final username = ''.obs;
  final merchantCode = ''.obs;
  final cashierNumber = 'NO.00000'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  void loadUserInfo() {
    final storedUsername = _storage.getString(StorageKeys.username);
    username.value = storedUsername ?? 'Guest';
    merchantCode.value =
        _storage.getString(StorageKeys.merchantCode) ?? '100000';
  }

  void onMenuTap(String? path) {
    if (path == null || path.isEmpty) {
      print('Menu path is null or empty, no navigation');
      return;
    }
    AppRouter.push(path);
  }

  void goToComponentsDemo() {
    AppRouter.push('/components-demo');
  }

  void goToDeviceSetup() {
    AppRouter.push('/device-setup');
  }
}
