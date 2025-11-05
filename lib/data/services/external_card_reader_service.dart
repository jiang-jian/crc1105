import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/external_card_reader_model.dart';

/// 外接USB读卡器服务
/// 专门用于管理通过USB接入的外接读卡器设备
/// 支持自动读卡：当设备连接后自动监听卡片
class ExternalCardReaderService extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.holox.ailand_pos/external_card_reader');

  // 已检测到的外接读卡器列表
  final detectedReaders = <ExternalCardReaderDevice>[].obs;

  // 当前选中的读卡器
  final Rx<ExternalCardReaderDevice?> selectedReader = Rx<ExternalCardReaderDevice?>(null);

  // 外接读卡器状态
  final Rx<ExternalCardReaderStatus> readerStatus = ExternalCardReaderStatus.notConnected.obs;

  // 是否正在扫描设备
  final isScanning = false.obs;

  // 是否正在读卡
  final isReading = false.obs;

  // 读卡测试是否成功
  final testReadSuccess = false.obs;

  // 最新读取的卡片数据
  final Rx<Map<String, dynamic>?> cardData = Rx<Map<String, dynamic>?>(null);

  // 最后一次错误信息
  final Rx<String?> lastError = Rx<String?>(null);

  // 调试日志
  final debugLogs = <String>[].obs;

  // 自动读卡定时器
  Timer? _autoReadTimer;

  /// 初始化服务
  Future<ExternalCardReaderService> init() async {
    _addLog('========== 初始化外接读卡器服务 ==========');

    if (kIsWeb) {
      _addLog('Web平台：跳过外接读卡器初始化');
      return this;
    }

    try {
      // 设置USB设备连接/断开监听
      _channel.setMethodCallHandler(_handleNativeCallback);
      _addLog('✓ 已设置USB设备监听');

      // 初始扫描一次USB设备
      await scanUsbReaders();

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
        await scanUsbReaders();
        break;

      case 'onUsbDeviceDetached':
        _addLog('USB设备已断开');
        await scanUsbReaders();
        break;

      case 'onCardDetected':
        _addLog('检测到卡片');
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          _handleCardData(Map<String, dynamic>.from(data));
        }
        break;

      default:
        _addLog('未知回调方法: ${call.method}');
    }
  }

  /// 扫描USB读卡器设备
  Future<void> scanUsbReaders() async {
    _addLog('========== 开始扫描USB读卡器 ==========');
    isScanning.value = true;
    testReadSuccess.value = false; // 重置测试状态
    cardData.value = null; // 清除卡片数据

    try {
      if (kIsWeb) {
        _addLog('Web平台：返回模拟设备');
        detectedReaders.value = [
          ExternalCardReaderDevice(
            deviceId: 'web-mock-reader-001',
            deviceName: 'Mock USB Card Reader',
            manufacturer: 'Mock Manufacturer',
            productName: 'Mock IC Card Reader',
            model: 'MCR-2000',
            specifications: 'ISO 14443 Type A/B',
            vendorId: 0x0001,
            productId: 0x0001,
            isConnected: true,
            serialNumber: 'MOCK-SN-123456',
          ),
        ];
        
        if (detectedReaders.isNotEmpty) {
          selectedReader.value = detectedReaders.first;
          readerStatus.value = ExternalCardReaderStatus.connected;
          _addLog('✓ 模拟设备已就绪');
          _startAutoRead(); // 启动自动读卡
        }
        
        isScanning.value = false;
        return;
      }

      // 调用原生方法扫描USB读卡器
      final result = await _channel.invokeMethod<List<dynamic>>('scanUsbReaders');
      _addLog('原生返回: $result');

      if (result == null || result.isEmpty) {
        _addLog('未检测到USB读卡器');
        detectedReaders.clear();
        selectedReader.value = null;
        readerStatus.value = ExternalCardReaderStatus.notConnected;
        _stopAutoRead(); // 停止自动读卡
      } else {
        // 解析设备列表
        final readers = result
            .map((item) => ExternalCardReaderDevice.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();

        detectedReaders.value = readers;
        _addLog('✓ 检测到 ${readers.length} 个读卡器');

        // 自动选择第一个设备
        if (readers.isNotEmpty) {
          selectedReader.value = readers.first;
          readerStatus.value = ExternalCardReaderStatus.connected;
          _addLog('✓ 已选择设备: ${readers.first.displayName}');
          _startAutoRead(); // 启动自动读卡
        } else {
          _stopAutoRead(); // 停止自动读卡
        }
      }
    } catch (e, stackTrace) {
      _addLog('✗ 扫描失败: $e');
      _addLog('堆栈: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      detectedReaders.clear();
      selectedReader.value = null;
      readerStatus.value = ExternalCardReaderStatus.error;
    } finally {
      isScanning.value = false;
      _addLog('========== 扫描完成 ==========');
    }
  }

  /// 测试读卡
  Future<CardReadResult> testReadCard() async {
    _addLog('========== 开始测试读卡 ==========');
    
    if (selectedReader.value == null) {
      _addLog('✗ 错误: 未选择读卡器');
      return CardReadResult(
        success: false,
        message: '未选择读卡器设备',
        errorCode: 'NO_DEVICE',
      );
    }

    isReading.value = true;
    testReadSuccess.value = false;
    cardData.value = null;
    readerStatus.value = ExternalCardReaderStatus.reading;

    try {
      if (kIsWeb) {
        _addLog('Web平台：返回模拟卡片数据');
        await Future.delayed(const Duration(seconds: 2));
        
        final mockData = {
          'uid': '04:A1:B2:C3:D4:E5:F6',
          'type': 'Mifare Classic 1K',
          'capacity': '1KB',
          'timestamp': DateTime.now().toIso8601String(),
          'isValid': true,
        };
        
        cardData.value = mockData;
        testReadSuccess.value = true;
        readerStatus.value = ExternalCardReaderStatus.connected;
        _addLog('✓ 模拟读卡成功');
        
        return CardReadResult(
          success: true,
          message: '读卡成功',
          cardData: mockData,
        );
      }

      final device = selectedReader.value!;
      _addLog('请求读卡: ${device.displayName}');

      // 调用原生方法读卡
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readCard',
        {'deviceId': device.deviceId},
      );

      _addLog('原生返回: $result');

      if (result == null) {
        throw Exception('读卡返回空数据');
      }

      final cardResult = CardReadResult.fromMap(Map<String, dynamic>.from(result));

      if (cardResult.success && cardResult.cardData != null) {
        cardData.value = cardResult.cardData;
        testReadSuccess.value = true;
        readerStatus.value = ExternalCardReaderStatus.connected;
        lastError.value = null;
        _addLog('✓ 读卡成功');
      } else {
        readerStatus.value = ExternalCardReaderStatus.error;
        lastError.value = cardResult.message;
        _addLog('✗ 读卡失败: ${cardResult.message}');
      }

      return cardResult;
    } catch (e, stackTrace) {
      _addLog('✗ 读卡异常: $e');
      _addLog('堆栈: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      readerStatus.value = ExternalCardReaderStatus.error;
      lastError.value = '读卡失败: $e';
      
      return CardReadResult(
        success: false,
        message: '读卡失败: $e',
        errorCode: 'READ_ERROR',
      );
    } finally {
      isReading.value = false;
      _addLog('========== 测试读卡结束 ==========');
    }
  }

  /// 处理卡片数据（来自原生回调）
  void _handleCardData(Map<String, dynamic> data) {
    _addLog('处理卡片数据: $data');
    cardData.value = data;
    testReadSuccess.value = true;
    readerStatus.value = ExternalCardReaderStatus.connected;
  }

  /// 清除卡片数据
  void clearCardData() {
    cardData.value = null;
    testReadSuccess.value = false;
    _addLog('已清除卡片数据');
  }

  /// 添加日志
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    final logMessage = '[$timestamp] $message';
    debugLogs.insert(0, logMessage);
    
    // 限制日志数量
    if (debugLogs.length > 100) {
      debugLogs.removeRange(100, debugLogs.length);
    }
    
    if (kDebugMode) {
      print('[ExternalCardReader] $message');
    }
  }

  /// 清空日志
  void clearLogs() {
    debugLogs.clear();
    _addLog('日志已清空');
  }

  /// 启动自动读卡（当设备连接时）
  void _startAutoRead() {
    if (_autoReadTimer != null && _autoReadTimer!.isActive) {
      return; // 已经在运行
    }

    _addLog('启动自动读卡监听');
    _autoReadTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      // 只有在设备连接且不在读卡中时才尝试读卡
      if (selectedReader.value != null &&
          readerStatus.value == ExternalCardReaderStatus.connected &&
          !isReading.value) {
        await _silentReadCard();
      }
    });
  }

  /// 停止自动读卡
  void _stopAutoRead() {
    if (_autoReadTimer != null) {
      _autoReadTimer!.cancel();
      _autoReadTimer = null;
      _addLog('停止自动读卡监听');
    }
  }

  /// 静默读卡（不显示错误提示）
  Future<void> _silentReadCard() async {
    if (selectedReader.value == null || isReading.value) {
      return;
    }

    isReading.value = true;

    try {
      if (kIsWeb) {
        // Web平台模拟
        await Future.delayed(const Duration(milliseconds: 100));
        isReading.value = false;
        return;
      }

      final device = selectedReader.value!;

      // 调用原生方法读卡
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readCard',
        {'deviceId': device.deviceId},
      );

      if (result != null) {
        final cardResult = CardReadResult.fromMap(Map<String, dynamic>.from(result));

        if (cardResult.success && cardResult.cardData != null) {
          // 只有在卡片数据变化时才更新
          final newUid = cardResult.cardData!['uid'];
          final currentUid = cardData.value?['uid'];
          
          if (newUid != currentUid) {
            cardData.value = cardResult.cardData;
            testReadSuccess.value = true;
            _addLog('✓ 检测到新卡片: $newUid');
          }
        }
      }
    } catch (e) {
      // 静默失败，不打印日志（避免日志刷屏）
    } finally {
      isReading.value = false;
    }
  }

  @override
  void onClose() {
    _stopAutoRead();
    _addLog('服务关闭');
    super.onClose();
  }
}
