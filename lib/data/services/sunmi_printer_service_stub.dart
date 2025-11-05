/// Web平台的打印机服务stub实现
/// 由于商米SDK不支持Web，这里提供模拟实现

import 'sunmi_printer_service.dart';

/// 平台特定接口
abstract class SunmiPrinterServicePlatform {
  factory SunmiPrinterServicePlatform.create() => _WebStub();
  
  Future<bool> checkAvailability();
  Future<PrinterDetailInfo?> getPrinterDetails(Function(String) log);
  Future<PrinterStatusInfo> getPrinterStatus(PrinterDetailInfo? detailInfo, Function(String) log);
  Future<bool> testPrintText(Function(String) log);
  Future<bool> printTextReceipt(String content);
  void dispose();
}

/// Web平台的stub实现
class _WebStub implements SunmiPrinterServicePlatform {
  @override
  Future<bool> checkAvailability() async {
    return true;
  }

  @override
  Future<PrinterDetailInfo?> getPrinterDetails(Function(String) log) async {
    log('Web平台：返回模拟详情');
    return PrinterDetailInfo(
      printerId: 'WEB-MOCK-12345',
      printerName: 'Sunmi Web Mock Printer',
      printerStatus: 'READY',
      printerType: '热敏打印机',
      printerPaper: '80mm',
    );
  }

  @override
  Future<PrinterStatusInfo> getPrinterStatus(PrinterDetailInfo? detailInfo, Function(String) log) async {
    log('Web平台：返回模拟状态');
    return PrinterStatusInfo(
      status: PrinterStatus.ready,
      message: '打印机已准备好（Web 模拟）',
      rawStatus: 'READY',
      detailInfo: detailInfo,
    );
  }

  @override
  Future<bool> testPrintText(Function(String) log) async {
    log('Web平台：模拟打印');
    await Future.delayed(const Duration(seconds: 1));
    log('✓ 模拟打印完成');
    return true;
  }

  @override
  Future<bool> printTextReceipt(String content) async {
    print('Web 模拟打印文本小票: $content');
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  void dispose() {
    // Web平台无需清理
  }
}

