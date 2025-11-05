/// 移动平台的打印机服务实现
/// 严格参照Demo实现: /FlutterPrinterSample_1020 2/example/
/// 确保SDK对接100%正确

import 'package:flutter/services.dart';
import 'package:sunmi_flutter_plugin_printer/bean/printer.dart';
import 'package:sunmi_flutter_plugin_printer/common/global_utils.dart';
import 'package:sunmi_flutter_plugin_printer/enum/printer_info.dart';
import 'package:sunmi_flutter_plugin_printer/style/base_style.dart';
import 'package:sunmi_flutter_plugin_printer/style/text_style.dart' as printer;
import 'package:sunmi_flutter_plugin_printer/sunmi_flutter_plugin_printer.dart';

import 'sunmi_printer_service.dart';

/// 平台特定接口
abstract class SunmiPrinterServicePlatform {
  factory SunmiPrinterServicePlatform.create() => _MobileImpl();
  
  Future<bool> checkAvailability();
  Future<PrinterDetailInfo?> getPrinterDetails(Function(String) log);
  Future<PrinterStatusInfo> getPrinterStatus(PrinterDetailInfo? detailInfo, Function(String) log);
  Future<bool> testPrintText(Function(String) log);
  Future<bool> printTextReceipt(String content);
  void dispose();
}

/// 移动平台的真实实现
/// 严格按照Demo的Global.mPrinter方式管理打印机实例
class _MobileImpl implements SunmiPrinterServicePlatform {
  // 对应Demo的Global.mPrinter
  Printer? _mPrinter;

  @override
  Future<bool> checkAvailability() async {
    try {
      GlobalUtils.logger.d("========== 初始化打印机 ==========");
      
      // 对应Demo: 初始化打印服务并获取打印机列表
      final List<Printer>? printers = await SunmiPrinter.initPrinter();
      GlobalUtils.logger.d("收到打印机列表: ${printers?.length ?? 0}台");
      
      if (printers == null || printers.isEmpty) {
        GlobalUtils.logger.d("未找到打印机");
        return false;
      }

      // 对应Demo: 选择第一个打印机作为当前打印机
      _mPrinter = printers.first;
      GlobalUtils.logger.d("已选择打印机 ID: ${_mPrinter?.printerId}");
      GlobalUtils.logger.d("========== 打印机初始化完成 ==========");
      
      return true;
    } catch (e) {
      GlobalUtils.logger.d("初始化打印机失败: $e");
      return false;
    }
  }

  @override
  Future<PrinterDetailInfo?> getPrinterDetails(Function(String) log) async {
    // 对应Demo的printer_info_page.dart中的_getPrinterInfo()方法
    log('========== 获取打印机详情 ==========');
    
    try {
      if (_mPrinter == null) {
        log('✗ 打印机未初始化');
        GlobalUtils.logger.d("打印机实例为null");
        return null;
      }

      String? name;
      String? status;
      String? type;
      String? paper;

      // 严格按照Demo的顺序和方式调用
      try {
        // 第1步：获取打印机名称（对应Demo第36行）
        log('步骤1: queryApi.getInfo(PrinterInfo.NAME)');
        name = await _mPrinter?.queryApi.getInfo(PrinterInfo.NAME);
        log('✓ 打印机名称: $name');
        GlobalUtils.logger.d("打印机名称: $name");

        // 第2步：获取打印机状态（对应Demo第37行）
        log('步骤2: queryApi.getStatus()?.name');
        final statusEnum = await _mPrinter?.queryApi.getStatus();
        status = statusEnum?.name;  // 关键：使用.name而不是toString()
        log('✓ 打印机状态: $status');
        GlobalUtils.logger.d("打印机状态: $status");

        // 第3步：获取打印机类型（对应Demo第38行）
        log('步骤3: queryApi.getInfo(PrinterInfo.TYPE)');
        type = await _mPrinter?.queryApi.getInfo(PrinterInfo.TYPE);
        log('✓ 打印机类型: $type');
        GlobalUtils.logger.d("打印机类型: $type");

        // 第4步：获取打印机纸张规格（对应Demo第39行）
        log('步骤4: queryApi.getInfo(PrinterInfo.PAPER)');
        paper = await _mPrinter?.queryApi.getInfo(PrinterInfo.PAPER);
        log('✓ 打印机规格: $paper');
        GlobalUtils.logger.d("打印机规格: $paper");

      } on PlatformException catch (e) {
        log('✗ PlatformException: $e');
        GlobalUtils.logger.d("PlatformException: $e");
      } catch (e) {
        log('✗ Exception: $e');
        GlobalUtils.logger.d("Exception: $e");
      }

      // 对应Demo：获取打印机ID
      final printerId = _mPrinter?.printerId;
      log('打印机ID: $printerId');
      GlobalUtils.logger.d("打印机ID: $printerId");

      final detailInfo = PrinterDetailInfo(
        printerId: printerId,
        printerName: name,
        printerStatus: status,
        printerType: type,
        printerPaper: paper,
      );

      log('========== 打印机详情获取完成 ==========');
      GlobalUtils.logger.d("详情: $detailInfo");
      
      return detailInfo;
    } catch (e) {
      log('✗ 获取详情失败: $e');
      GlobalUtils.logger.d("获取详情失败: $e");
      return null;
    }
  }

  @override
  Future<PrinterStatusInfo> getPrinterStatus(PrinterDetailInfo? detailInfo, Function(String) log) async {
    try {
      if (_mPrinter == null) {
        log('✗ 打印机未初始化');
        throw Exception('打印机未初始化');
      }

      // 获取打印机状态枚举
      log('调用 queryApi.getStatus()');
      final statusEnum = await _mPrinter?.queryApi.getStatus();
      final statusName = statusEnum?.name ?? 'UNKNOWN';  // 使用.name获取状态名称
      log('✓ 状态枚举: $statusName');
      GlobalUtils.logger.d("状态枚举: $statusName");

      // 解析状态
      return _parsePrinterStatus(statusName, detailInfo, log);
    } catch (e) {
      log('✗ 获取状态失败: $e');
      GlobalUtils.logger.d("获取状态失败: $e");
      return PrinterStatusInfo(
        status: PrinterStatus.error,
        message: '获取状态失败: $e',
        rawStatus: 'ERROR',
      );
    }
  }

  /// 解析打印机状态
  /// 参数statusName是Status枚举的name属性值
  PrinterStatusInfo _parsePrinterStatus(String statusName, PrinterDetailInfo? detailInfo, Function(String) log) {
    log('解析状态名称: $statusName');
    GlobalUtils.logger.d("解析状态: $statusName");

    // 根据枚举名称映射到我们的状态
    // 参考商米SDK文档中Status枚举的定义
    PrinterStatus status;
    String message;
    String rawStatus = statusName;

    if (statusName.contains('READY') || statusName == 'READY') {
      status = PrinterStatus.ready;
      message = '打印机已准备好，可正常打印';
    } else if (statusName.contains('PRINTING') || statusName == 'PRINTING') {
      status = PrinterStatus.ready;
      message = '打印机正在打印';
    } else if (statusName.contains('LOW_PAPER') || statusName == 'WARN_LOW_PAPER') {
      status = PrinterStatus.warning;
      message = '打印纸即将用完';
    } else if (statusName.contains('NO_PAPER') || statusName == 'ERR_PAPER_OUT') {
      status = PrinterStatus.error;
      message = '打印机缺纸';
    } else if (statusName.contains('OVERHEATED') || statusName == 'ERR_OVERHEATED') {
      status = PrinterStatus.error;
      message = '打印机过热';
    } else if (statusName.contains('COVER_OPEN') || statusName == 'ERR_COVER_OPEN') {
      status = PrinterStatus.error;
      message = '打印机盖子打开';
    } else if (statusName.contains('CUTTER') || statusName == 'ERR_CUTTER') {
      status = PrinterStatus.error;
      message = '切刀错误';
    } else if (statusName.contains('OFFLINE') || statusName == 'OFFLINE') {
      status = PrinterStatus.error;
      message = '打印机离线/故障';
    } else {
      status = PrinterStatus.unknown;
      message = '未识别的状态: $statusName';
    }

    log('✓ 状态映射: ${status.name} - $message');
    GlobalUtils.logger.d("状态映射: ${status.name} - $message");

    return PrinterStatusInfo(
      status: status,
      message: message,
      rawStatus: rawStatus,
      detailInfo: detailInfo,
    );
  }

  @override
  Future<bool> testPrintText(Function(String) log) async {
    // 严格对应Demo的print_ticket_page.dart中的_printText()方法（第109-131行）
    log('========== 打印文本测试 ==========');
    
    try {
      if (_mPrinter == null) {
        log('✗ 打印机未初始化');
        throw Exception('打印机未初始化');
      }

      // 获取lineApi（对应Demo第28行）
      final lineApi = _mPrinter?.lineApi;
      if (lineApi == null) {
        log('✗ lineApi为null');
        throw Exception('lineApi未初始化');
      }

      // 严格按照Demo的_printText()方法实现
      try {
        // 第1步：初始化行（对应Demo第111行）
        log('步骤1: lineApi.initLine(BaseStyle.getStyle())');
        lineApi.initLine(BaseStyle.getStyle());
        log('✓ 行初始化完成');

        // 第2步：直接打印整行内容（对应Demo第112行）
        log('步骤2: lineApi.printText("这行内容将直接打印出")');
        lineApi.printText("这行内容将直接打印出", printer.TextStyle.getStyle());
        log('✓ 整行文本已添加');

        // 第3步：添加不同风格的文本（对应Demo第113-123行）
        log('步骤3: lineApi.addText() - 添加不同风格');
        lineApi.addText("不同风格的内容:", printer.TextStyle.getStyle());
        lineApi.addText("加粗", printer.TextStyle.getStyle().enableBold(true));
        lineApi.addText("下划线", printer.TextStyle.getStyle().enableUnderline(true));
        lineApi.addText("删除线", printer.TextStyle.getStyle().enableStrikethrough(true));
        lineApi.addText("倾斜", printer.TextStyle.getStyle().enableItalics(true));
        lineApi.addText("\n", printer.TextStyle.getStyle());
        log('✓ 样式文本已添加');

        // 第4步：自动输出（对应Demo第125行）
        log('步骤4: lineApi.autoOut()');
        lineApi.autoOut();
        log('✓ 打印指令已发送');

        GlobalUtils.logger.d("打印文本测试成功");
        log('========== 打印完成 ==========');
        return true;

      } on PlatformException catch (e) {
        log('✗ PlatformException: $e');
        GlobalUtils.logger.d("PlatformException: $e");
        return false;
      } catch (e) {
        log('✗ Exception: $e');
        GlobalUtils.logger.d("Exception: $e");
        return false;
      }
    } catch (e) {
      log('✗ 打印失败: $e');
      GlobalUtils.logger.d("打印失败: $e");
      log('========== 打印失败 ==========');
      return false;
    }
  }

  @override
  Future<bool> printTextReceipt(String content) async {
    try {
      if (_mPrinter == null) {
        throw Exception('打印机未初始化');
      }

      // 使用lineApi打印自定义文本内容
      final lineApi = _mPrinter?.lineApi;
      if (lineApi == null) {
        throw Exception('lineApi未初始化');
      }

      GlobalUtils.logger.d("打印自定义文本: $content");

      // 初始化行
      lineApi.initLine(BaseStyle.getStyle());

      // 打印文本内容（按行分割）
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          lineApi.printText(line, printer.TextStyle.getStyle());
        }
      }

      // 输出
      lineApi.autoOut();

      GlobalUtils.logger.d("打印文本小票成功");
      return true;
    } on PlatformException catch (e) {
      GlobalUtils.logger.d("PlatformException: $e");
      return false;
    } catch (e) {
      GlobalUtils.logger.d("打印文本小票失败: $e");
      return false;
    }
  }

  @override
  void dispose() {
    GlobalUtils.logger.d("释放打印机资源");
    _mPrinter = null;
  }
}
