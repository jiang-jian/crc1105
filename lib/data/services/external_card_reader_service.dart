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

  // 调试日志面板是否展开
  final debugLogExpanded = false.obs;

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

      case 'onPermissionGranted':
        _addLog('✓ USB权限已授予');
        // 权限授予后，重新扫描设备以更新连接状态
        final deviceId = call.arguments as Map<dynamic, dynamic>?;
        if (deviceId != null) {
          _addLog('设备 ${deviceId["deviceId"]} 权限已授予，正在更新状态...');
        }
        // 延迟一下让系统完成权限授予流程
        await Future.delayed(const Duration(milliseconds: 500));
        // 🔧 FIX: 重新扫描设备，强制更新 selectedReader 为新的已授权设备对象
        await scanUsbReaders(forceUpdateSelected: true);
        break;

      case 'onPermissionDenied':
        _addLog('✗ USB权限被拒绝');
        readerStatus.value = ExternalCardReaderStatus.error;
        lastError.value = 'USB权限被拒绝，请在系统设置中允许USB访问';
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
  /// [forceUpdateSelected] - 强制更新 selectedReader（用于权限授予后）
  Future<void> scanUsbReaders({bool forceUpdateSelected = false}) async {
    _addLog('========== 开始扫描USB读卡器 ==========');
    if (forceUpdateSelected) {
      _addLog('🔧 强制更新模式：将重新选择已授权设备');
    }
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
        cardData.value = null;  // 🔧 清除卡片数据
        lastError.value = null;  // 🔧 清除错误信息
        _stopAutoRead(); // 停止自动读卡
      } else {
        // 解析设备列表
        final readers = result
            .map((item) => ExternalCardReaderDevice.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();

        detectedReaders.value = readers;
        _addLog('✓ 检测到 ${readers.length} 个USB设备');
        
        // 🔧 FIX: 打印所有设备的详细信息，帮助识别正确的读卡器
        for (var i = 0; i < readers.length; i++) {
          final reader = readers[i];
          _addLog('  设备 ${i + 1}:');
          _addLog('    名称: ${reader.deviceName}');
          _addLog('    产品: ${reader.productName}');
          _addLog('    厂商: ${reader.manufacturer}');
          _addLog('    USB ID: ${reader.usbIdentifier}');
          _addLog('    授权: ${reader.isConnected ? "是" : "否"}');
          if (reader.usbPath != null) {
            _addLog('    路径: ${reader.usbPath}');
          }
        }

        // 🔧 FIX: 智能选择读卡器设备（过滤USB Hub）
        ExternalCardReaderDevice? selectedDevice;
        
        if (readers.isNotEmpty) {
          // 优先选择名称包含读卡器关键词的设备
          final cardReaderKeywords = ['reader', 'card', 'nfc', 'rfid', 'acr', 'acs'];
          final hubKeywords = ['hub'];
          
          // 过滤并排序设备
          final sortedReaders = List<ExternalCardReaderDevice>.from(readers);
          sortedReaders.sort((a, b) {
            final aName = '${a.productName} ${a.deviceName}'.toLowerCase();
            final bName = '${b.productName} ${b.deviceName}'.toLowerCase();
            
            // 检查是否包含Hub关键词（降低优先级）
            final aIsHub = hubKeywords.any((keyword) => aName.contains(keyword));
            final bIsHub = hubKeywords.any((keyword) => bName.contains(keyword));
            
            if (aIsHub && !bIsHub) return 1;  // a是Hub，b不是 → b优先
            if (!aIsHub && bIsHub) return -1; // a不是Hub，b是 → a优先
            
            // 检查是否包含读卡器关键词（提高优先级）
            final aScore = cardReaderKeywords.where((keyword) => aName.contains(keyword)).length;
            final bScore = cardReaderKeywords.where((keyword) => bName.contains(keyword)).length;
            
            return bScore.compareTo(aScore); // 分数高的优先
          });
          
          selectedDevice = sortedReaders.first;
          _addLog('✓ 智能选择设备: ${selectedDevice.displayName}');
          
          // 如果选中的是Hub，给出警告
          final selectedName = '${selectedDevice.productName} ${selectedDevice.deviceName}'.toLowerCase();
          if (hubKeywords.any((keyword) => selectedName.contains(keyword))) {
            _addLog('⚠️ 警告: 选中的设备可能是USB Hub，不是读卡器');
            _addLog('⚠️ 如果读卡失败，请检查是否接入了正确的读卡器设备');
          }
          
          final firstReader = selectedDevice;
          
          // 🔧 FIX: 如果是强制更新模式（权限授予后），无条件更新 selectedReader
          if (forceUpdateSelected) {
            selectedReader.value = firstReader;
            _addLog('✓ 强制更新选中设备: ${firstReader.displayName}');
            _addLog('  设备授权状态: ${firstReader.isConnected ? "已授权" : "未授权"}');
            
            // 权限授予后的设备应该是已授权的，直接启动自动读卡
            if (firstReader.isConnected) {
              _addLog('✓ 设备已授权，启动自动读卡');
              readerStatus.value = ExternalCardReaderStatus.connected;
              _startAutoRead();
            } else {
              _addLog('⚠️ 警告: 设备仍未授权，继续等待');
              readerStatus.value = ExternalCardReaderStatus.connecting;
            }
          } else {
            // 正常模式：首次扫描或手动扫描
            selectedReader.value = firstReader;
            _addLog('✓ 已选择设备: ${firstReader.displayName}');
            
            // 检查是否有权限，没有则请求
            if (!firstReader.isConnected) {
              _addLog('设备未授权，正在请求USB权限...');
              readerStatus.value = ExternalCardReaderStatus.connecting;
              await requestPermission(firstReader.deviceId);
            } else {
              _addLog('✓ 设备已授权，准备启动自动读卡');
              readerStatus.value = ExternalCardReaderStatus.connected;
              _startAutoRead(); // 启动自动读卡
            }
          }
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
      cardData.value = null;  // 🔧 清除卡片数据
      lastError.value = '扫描失败: $e';  // 🔧 设置错误信息
    } finally {
      isScanning.value = false;
      _addLog('========== 扫描完成 ==========');
    }
  }

  /// 请求USB设备权限
  Future<bool> requestPermission(String deviceId) async {
    _addLog('========== 请求USB权限 ==========');
    _addLog('设备ID: $deviceId');
    
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestPermission',
        {'deviceId': deviceId},
      );
      
      if (result == true) {
        _addLog('✓ 权限请求已发送，等待用户确认...');
        return true;
      } else {
        _addLog('✗ 权限请求发送失败');
        return false;
      }
    } catch (e) {
      _addLog('✗ 请求权限异常: $e');
      return false;
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

      // 调用原生方法读卡（增加超时控制）
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readCard',
        {'deviceId': device.deviceId},
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // 超时不记录日志，避免刷屏
          return null;
        },
      );

      if (result != null) {
        final cardResult = CardReadResult.fromMap(Map<String, dynamic>.from(result));

        if (cardResult.success && cardResult.cardData != null) {
          // 只有在卡片数据变化时才更新
          final newUid = cardResult.cardData!['uid'];
          final currentUid = cardData.value?['uid'];
          
          if (newUid != currentUid && newUid != 'Unknown') {
            cardData.value = cardResult.cardData;
            testReadSuccess.value = true;
            lastError.value = null;
            _addLog('✓ 检测到新卡片');
            _addLog('  UID: $newUid');
            _addLog('  类型: ${cardResult.cardData!["type"]}');
          }
        } else if (cardResult.errorCode == 'NO_CARD') {
          // 无卡片时不记录日志，避免刷屏
        } else {
          // 其他错误才记录（但限制频率）
          if (lastError.value != cardResult.message) {
            lastError.value = cardResult.message;
            _addLog('读卡错误: ${cardResult.message}');
          }
        }
      }
    } catch (e) {
      // 静默失败，只在错误变化时记录
      if (lastError.value != e.toString()) {
        lastError.value = e.toString();
        _addLog('读卡异常: $e');
      }
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
