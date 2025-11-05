import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/external_printer_model.dart';

/// 外接USB打印机服务
/// 专门用于管理通过USB接入的外接打印机设备
/// 与内置打印机（Sunmi）完全独立
class ExternalPrinterService extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.holox.ailand_pos/external_printer');

  // 已检测到的外接打印机列表
  final detectedPrinters = <ExternalPrinterDevice>[].obs;

  // 当前选中的打印机
  final Rx<ExternalPrinterDevice?> selectedPrinter = Rx<ExternalPrinterDevice?>(null);

  // 外接打印机状态
  final Rx<ExternalPrinterStatus> printerStatus = ExternalPrinterStatus.notConnected.obs;

  // 是否正在扫描设备
  final isScanning = false.obs;

  // 是否正在打印
  final isPrinting = false.obs;

  // 测试打印是否成功
  final testPrintSuccess = false.obs;

  // 调试日志
  final debugLogs = <String>[].obs;

  /// 初始化服务
  Future<ExternalPrinterService> init() async {
    _addLog('========== 初始化外接打印机服务 ==========');

    if (kIsWeb) {
      _addLog('Web平台：跳过外接打印机初始化');
      return this;
    }

    try {
      // 设置USB设备连接/断开监听
      _channel.setMethodCallHandler(_handleNativeCallback);
      _addLog('✓ 已设置USB设备监听');

      // 初始扫描一次USB设备
      await scanUsbPrinters();

      _addLog('========== 初始化完成 ==========');
      return this;
    } catch (e, stackTrace) {
      _addLog('✗ 初始化失败: $e');
      _addLog('堆栈: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      return this;
    }
  }

  /// 处理来自原生端的回调
  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    _addLog('收到原生回调: ${call.method}');

    switch (call.method) {
      case 'onUsbDeviceAttached':
        _addLog('USB设备已连接');
        await scanUsbPrinters();
        break;

      case 'onUsbDeviceDetached':
        _addLog('USB设备已断开');
        await scanUsbPrinters();
        break;

      default:
        _addLog('未知回调方法: ${call.method}');
    }
  }

  /// 扫描USB打印机设备
  Future<void> scanUsbPrinters() async {
    _addLog('========== 开始扫描USB打印机 ==========');
    isScanning.value = true;
    testPrintSuccess.value = false; // 重置测试状态

    try {
      if (kIsWeb) {
        _addLog('Web平台：返回模拟设备');
        detectedPrinters.value = [
          ExternalPrinterDevice(
            deviceId: 'web-mock-001',
            deviceName: 'Mock USB Printer',
            manufacturer: 'Mock Manufacturer',
            productName: 'Mock Thermal Printer',
            vendorId: 0x0001,
            productId: 0x0001,
            isConnected: true,
          ),
        ];
        isScanning.value = false;
        return;
      }

      final List<dynamic>? devices = await _channel.invokeMethod('scanUsbPrinters');
      _addLog('扫描结果: ${devices?.length ?? 0} 个设备');

      if (devices == null || devices.isEmpty) {
        _addLog('未检测到USB打印机设备');
        detectedPrinters.clear();
        printerStatus.value = ExternalPrinterStatus.notConnected;
      } else {
        final printers = devices
            .map((device) => ExternalPrinterDevice.fromMap(Map<String, dynamic>.from(device)))
            .toList();

        detectedPrinters.value = printers;

        for (var printer in printers) {
          _addLog('发现设备: ${printer.displayName}');
          _addLog('  厂商: ${printer.manufacturer}');
          _addLog('  USB ID: ${printer.usbIdentifier}');
          _addLog('  状态: ${printer.isConnected ? "已连接" : "未连接"}');
        }

        // 如果有设备连接，更新状态
        if (printers.any((p) => p.isConnected)) {
          printerStatus.value = ExternalPrinterStatus.connected;
        }
      }

      _addLog('========== 扫描完成 ==========');
    } on PlatformException catch (e) {
      _addLog('✗ 平台异常: ${e.message}');
      _addLog('代码: ${e.code}');
      detectedPrinters.clear();
    } catch (e, stackTrace) {
      _addLog('✗ 扫描失败: $e');
      _addLog('堆栈: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      detectedPrinters.clear();
    } finally {
      isScanning.value = false;
    }
  }

  /// 请求USB设备权限
  Future<bool> requestPermission(ExternalPrinterDevice device) async {
    _addLog('========== 请求USB设备权限 ==========');
    _addLog('设备: ${device.displayName}');

    try {
      if (kIsWeb) {
        _addLog('Web平台：模拟权限授予');
        return true;
      }

      final bool? result = await _channel.invokeMethod('requestPermission', {
        'deviceId': device.deviceId,
      });

      if (result == true) {
        _addLog('✓ 权限已授予');
        selectedPrinter.value = device;
        printerStatus.value = ExternalPrinterStatus.ready;
        return true;
      } else {
        _addLog('✗ 权限被拒绝');
        return false;
      }
    } on PlatformException catch (e) {
      _addLog('✗ 请求权限失败: ${e.message}');
      return false;
    } catch (e) {
      _addLog('✗ 请求权限异常: $e');
      return false;
    }
  }

  /// 测试打印
  Future<ExternalPrintResult> testPrint(ExternalPrinterDevice device) async {
    _addLog('========== 开始测试打印 ==========');
    _addLog('设备: ${device.displayName}');
    isPrinting.value = true;
    printerStatus.value = ExternalPrinterStatus.printing;

    try {
      if (kIsWeb) {
        _addLog('Web平台：模拟打印');
        await Future.delayed(const Duration(seconds: 2));
        _addLog('✓ 模拟打印完成');
        isPrinting.value = false;
        printerStatus.value = ExternalPrinterStatus.ready;
        return ExternalPrintResult(
          success: true,
          message: '打印测试成功（模拟）',
        );
      }

      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('testPrint', {
        'deviceId': device.deviceId,
        'testText': '外接打印机测试\n打印时间: ${DateTime.now()}\n测试成功',
      });

      if (result == null) {
        throw PlatformException(code: 'NULL_RESULT', message: '打印返回空结果');
      }

      final printResult = ExternalPrintResult.fromMap(Map<String, dynamic>.from(result));

      if (printResult.success) {
        _addLog('✓ 打印测试成功');
        printerStatus.value = ExternalPrinterStatus.ready;
      } else {
        _addLog('✗ 打印测试失败: ${printResult.message}');
        printerStatus.value = ExternalPrinterStatus.error;
      }

      _addLog('========== 测试打印完成 ==========');
      return printResult;
    } on PlatformException catch (e) {
      _addLog('✗ 平台异常: ${e.message}');
      printerStatus.value = ExternalPrinterStatus.error;
      return ExternalPrintResult(
        success: false,
        message: '打印失败: ${e.message}',
        errorCode: e.code,
      );
    } catch (e, stackTrace) {
      _addLog('✗ 打印异常: $e');
      _addLog('堆栈: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      printerStatus.value = ExternalPrinterStatus.error;
      return ExternalPrintResult(
        success: false,
        message: '打印异常: $e',
      );
    } finally {
      isPrinting.value = false;
    }
  }

  /// 添加调试日志
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugLogs.add('[$timestamp] $message');
    if (debugLogs.length > 50) {
      debugLogs.removeAt(0);
    }
    print('[ExternalPrinter] $message');
  }

  /// 清空调试日志
  void clearDebugLogs() {
    debugLogs.clear();
    _addLog('日志已清空');
  }

  @override
  void onClose() {
    _addLog('外接打印机服务已关闭');
    super.onClose();
  }
}

