package com.holox.ailand_pos

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException

/**
 * 外接USB打印机插件
 * 用于检测和管理通过USB连接的外接打印机设备
 * 完全独立于内置Sunmi打印机功能
 */
class ExternalPrinterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var usbManager: UsbManager? = null

    companion object {
        private const val TAG = "ExternalPrinter"
        private const val CHANNEL_NAME = "com.holox.ailand_pos/external_printer"
        private const val ACTION_USB_PERMISSION = "com.holox.ailand_pos.USB_PERMISSION"
        
        // USB打印机类代码
        // Class 7 = Printer
        private const val USB_CLASS_PRINTER = 7
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_USB_PERMISSION -> {
                    synchronized(this) {
                        val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                        }

                        if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                            device?.let {
                                Log.d(TAG, "USB permission granted for device: ${it.deviceName}")
                            }
                        } else {
                            Log.d(TAG, "USB permission denied for device: ${device?.deviceName}")
                        }
                    }
                }
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    Log.d(TAG, "USB device attached")
                    channel.invokeMethod("onUsbDeviceAttached", null)
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    Log.d(TAG, "USB device detached")
                    channel.invokeMethod("onUsbDeviceDetached", null)
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        usbManager = context?.getSystemService(Context.USB_SERVICE) as? UsbManager

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        // 注册USB设备广播接收器
        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context?.registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context?.registerReceiver(usbReceiver, filter)
        }

        Log.d(TAG, "ExternalPrinterPlugin attached")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context?.unregisterReceiver(usbReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        context = null
        usbManager = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanUsbPrinters" -> scanUsbPrinters(result)
            "requestPermission" -> requestPermission(call, result)
            "testPrint" -> testPrint(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * 扫描USB打印机设备
     */
    private fun scanUsbPrinters(result: Result) {
        try {
            val deviceList = usbManager?.deviceList ?: emptyMap()
            Log.d(TAG, "Scanning USB devices, found: ${deviceList.size}")

            val printers = deviceList.values
                .filter { isPrinterDevice(it) }
                .map { device ->
                    hashMapOf(
                        "deviceId" to device.deviceId.toString(),
                        "deviceName" to device.deviceName,
                        "manufacturer" to (device.manufacturerName ?: "Unknown"),
                        "productName" to (device.productName ?: "Unknown"),
                        "vendorId" to device.vendorId,
                        "productId" to device.productId,
                        "isConnected" to true,
                        "serialNumber" to device.serialNumber
                    )
                }

            Log.d(TAG, "Found ${printers.size} printer devices")
            result.success(printers)
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning USB devices: ${e.message}", e)
            result.error("SCAN_ERROR", "Failed to scan USB devices: ${e.message}", null)
        }
    }

    /**
     * 判断是否为打印机设备
     */
    private fun isPrinterDevice(device: UsbDevice): Boolean {
        // 方法1: 检查USB设备类
        if (device.deviceClass == USB_CLASS_PRINTER) {
            Log.d(TAG, "Device ${device.deviceName} is a printer (by device class)")
            return true
        }

        // 方法2: 检查接口类
        for (i in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(i)
            if (usbInterface.interfaceClass == USB_CLASS_PRINTER) {
                Log.d(TAG, "Device ${device.deviceName} is a printer (by interface class)")
                return true
            }
        }

        // 方法3: 检查常见打印机厂商ID
        // 可以根据实际使用的打印机品牌添加更多厂商ID
        val knownPrinterVendors = listOf(
            0x04b8, // Epson
            0x04e8, // Samsung
            0x03f0, // HP
            0x04a9, // Canon
            0x067b, // Prolific (常用于热敏打印机)
            0x0416, // 芯烨 (Xprinter)
            0x0519, // 佳博 (Gprinter)
        )

        if (device.vendorId in knownPrinterVendors) {
            Log.d(TAG, "Device ${device.deviceName} is likely a printer (by vendor ID)")
            return true
        }

        return false
    }

    /**
     * 请求USB设备权限
     */
    private fun requestPermission(call: MethodCall, result: Result) {
        try {
            val deviceId = call.argument<String>("deviceId")
            if (deviceId == null) {
                result.error("INVALID_ARGUMENT", "Device ID is required", null)
                return
            }

            val device = findDeviceById(deviceId)
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "Device not found: $deviceId", null)
                return
            }

            if (usbManager?.hasPermission(device) == true) {
                Log.d(TAG, "Already has permission for device: ${device.deviceName}")
                result.success(true)
                return
            }

            val permissionIntent = PendingIntent.getBroadcast(
                context,
                0,
                Intent(ACTION_USB_PERMISSION),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE
                } else {
                    0
                }
            )

            usbManager?.requestPermission(device, permissionIntent)
            Log.d(TAG, "Requesting permission for device: ${device.deviceName}")
            
            // 注意：权限结果通过广播接收器处理
            // 这里先返回true，实际权限状态在广播中处理
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting permission: ${e.message}", e)
            result.error("PERMISSION_ERROR", "Failed to request permission: ${e.message}", null)
        }
    }

    /**
     * 测试打印
     */
    private fun testPrint(call: MethodCall, result: Result) {
        try {
            val deviceId = call.argument<String>("deviceId")
            val testText = call.argument<String>("testText") ?: "Test Print"

            if (deviceId == null) {
                result.error("INVALID_ARGUMENT", "Device ID is required", null)
                return
            }

            val device = findDeviceById(deviceId)
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "Device not found: $deviceId", null)
                return
            }

            if (usbManager?.hasPermission(device) != true) {
                result.error("NO_PERMISSION", "No permission for device", null)
                return
            }

            // 尝试打印
            val printSuccess = printToDevice(device, testText)

            if (printSuccess) {
                result.success(
                    hashMapOf(
                        "success" to true,
                        "message" to "打印测试成功"
                    )
                )
            } else {
                result.success(
                    hashMapOf(
                        "success" to false,
                        "message" to "打印失败，请检查打印机状态"
                    )
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during test print: ${e.message}", e)
            result.error("PRINT_ERROR", "Print failed: ${e.message}", null)
        }
    }

    /**
     * 根据设备ID查找USB设备
     */
    private fun findDeviceById(deviceId: String): UsbDevice? {
        return usbManager?.deviceList?.values?.find {
            it.deviceId.toString() == deviceId
        }
    }

    /**
     * 向USB设备发送打印数据
     * 使用ESC/POS命令集（热敏打印机通用标准）
     */
    private fun printToDevice(device: UsbDevice, text: String): Boolean {
        var connection: android.hardware.usb.UsbDeviceConnection? = null
        try {
            connection = usbManager?.openDevice(device)
            if (connection == null) {
                Log.e(TAG, "Failed to open device connection")
                return false
            }

            // 查找打印机端点
            val usbInterface = device.getInterface(0)
            connection.claimInterface(usbInterface, true)

            var endpoint: android.hardware.usb.UsbEndpoint? = null
            for (i in 0 until usbInterface.endpointCount) {
                val ep = usbInterface.getEndpoint(i)
                if (ep.direction == android.hardware.usb.UsbConstants.USB_DIR_OUT) {
                    endpoint = ep
                    break
                }
            }

            if (endpoint == null) {
                Log.e(TAG, "No OUT endpoint found")
                return false
            }

            // 构建ESC/POS打印命令
            val commands = buildEscPosPrintCommand(text)

            // 发送数据到打印机
            val bytesWritten = connection.bulkTransfer(
                endpoint,
                commands,
                commands.size,
                5000 // 5秒超时
            )

            Log.d(TAG, "Bytes written: $bytesWritten / ${commands.size}")
            return bytesWritten > 0
        } catch (e: IOException) {
            Log.e(TAG, "IO Error during print: ${e.message}", e)
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error during print: ${e.message}", e)
            return false
        } finally {
            connection?.close()
        }
    }

    /**
     * 构建ESC/POS打印命令
     * ESC/POS是热敏打印机的通用命令标准
     */
    private fun buildEscPosPrintCommand(text: String): ByteArray {
        val commands = mutableListOf<Byte>()

        // ESC @ - 初始化打印机
        commands.addAll(listOf(0x1B, 0x40))

        // ESC a 1 - 居中对齐
        commands.addAll(listOf(0x1B, 0x61, 0x01))

        // 添加文本内容
        commands.addAll(text.toByteArray(Charsets.UTF_8).toList())

        // LF - 换行
        commands.add(0x0A)
        commands.add(0x0A)

        // GS V 66 0 - 切纸（部分切纸）
        commands.addAll(listOf(0x1D, 0x56, 0x42, 0x00))

        return commands.toByteArray()
    }
}

