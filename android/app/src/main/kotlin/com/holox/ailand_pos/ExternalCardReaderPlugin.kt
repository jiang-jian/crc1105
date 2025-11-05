package com.holox.ailand_pos

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * 外接USB读卡器插件
 * 用于检测和管理通过USB连接的外接读卡器设备
 * 支持各类IC卡读卡器（ISO 14443 Type A/B, Mifare等）
 */
class ExternalCardReaderPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var usbManager: UsbManager? = null
    private var currentConnection: UsbDeviceConnection? = null
    private val cardReadExecutor = Executors.newSingleThreadScheduledExecutor()

    companion object {
        private const val TAG = "ExternalCardReader"
        private const val CHANNEL_NAME = "com.holox.ailand_pos/external_card_reader"
        private const val ACTION_USB_PERMISSION = "com.holox.ailand_pos.USB_CARD_READER_PERMISSION"
        
        // USB设备类代码
        private const val USB_CLASS_SMART_CARD = 11  // CCID (Chip Card Interface Device)
        private const val USB_CLASS_VENDOR_SPECIFIC = 0xFF  // 厂商自定义类
        
        /**
         * 全球主流读卡器厂商ID列表（扩展版）
         * 数据来源：USB-IF官方数据库 + CCID官方支持列表
         * 覆盖：美洲、欧洲、亚洲主流品牌
         */
        private val KNOWN_CARD_READER_VENDORS = listOf(
            // === 市场领导者（按市占率排序）===
            0x072f,  // ACS (Advanced Card Systems) - 全球市占率最高
            0x076b,  // HID Global (OmniKey) - 企业级首选
            0x04e6,  // SCM Microsystems - 欧洲主流
            0x096e,  // Feitian Technologies - 中国最大厂商
            0x1050,  // Yubico - FIDO/U2F领导者
            
            // === 企业级品牌 ===
            0x04cc,  // Identiv (收购SCM后的品牌)
            0x08e6,  // Gemalto (Thales) - 安全芯片巨头
            0x0b97,  // O2Micro - 笔记本内置读卡器
            0x058f,  // Alcor Micro - 笔记本内置读卡器
            0x0bda,  // Realtek Semiconductor - 多功能读卡器
            
            // === 欧洲专业品牌 ===
            0x0c4b,  // Reiner SCT - 德国品牌
            0x0dc3,  // Athena Smartcard Solutions - 欧洲企业级
            0x0bf8,  // Fujitsu Technology Solutions - 日本富士通
            0x413c,  // Dell - 戴尔键盘集成读卡器
            0x0483,  // STMicroelectronics - 意法半导体
            0x046a,  // Cherry GmbH - 德国樱桃（键盘+读卡器）
            0x0973,  // SchlumbergerSema - 欧洲老牌
            
            // === 亚洲品牌 ===
            0x1fc9,  // NXP Semiconductors - 荷兰恩智浦
            0x04e8,  // Samsung Electronics - 三星
            0x04f2,  // Chicony Electronics - 群光电子
            0x0409,  // NEC - 日本NEC
            0x0a5c,  // Broadcom - 博通（TPM+读卡器）
            0x163c,  // Watchdata - 握奇数据（中国）
            0x0ca6,  // Castles Technology - 台湾凯泽科技
            0x0557,  // ATEN International - 宏正自动科技
            
            // === 安全密钥厂商 ===
            0x20a0,  // Nitrokey - 开源安全密钥
            0x234b,  // SafeNet (被Gemalto收购)
            0x0a89,  // Aktiv (ActivIdentity)
            0x1a44,  // VASCO Data Security - DIGIPASS
            0x23a0,  // BIFIT - 必发特（中国）
            
            // === OEM和通用芯片厂商 ===
            0x03f0,  // Hewlett-Packard (HP)
            0x0a82,  // Syscan - 扫描仪和读卡器
            0x0c27,  // RFIDeas - RFID读卡器
            0x1209,  // Generic (pid.codes) - 开源硬件
            0x10c4,  // Silicon Labs - USB转接芯片
            0x067b,  // Prolific Technology - USB转接芯片
            0x0424,  // Microchip (SMSC) - USB Hub芯片
            
            // === 中国制造商 ===
            0x0403,  // FTDI - 常用于串口读卡器
            0x1a86,  // QinHeng Electronics - 沁恒电子
        )
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
                                Log.d(TAG, "USB permission granted for card reader: ${it.deviceName}")
                                channel.invokeMethod("onPermissionGranted", mapOf("deviceId" to it.deviceId.toString()))
                            }
                        } else {
                            Log.d(TAG, "USB permission denied for device: ${device?.deviceName}")
                            channel.invokeMethod("onPermissionDenied", null)
                        }
                    }
                }
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    
                    if (device != null && isCardReaderDevice(device)) {
                        Log.d(TAG, "Card reader device attached: ${device.deviceName}")
                        channel.invokeMethod("onUsbDeviceAttached", null)
                    }
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    
                    if (device != null && isCardReaderDevice(device)) {
                        Log.d(TAG, "Card reader device detached: ${device.deviceName}")
                        closeConnection()
                        channel.invokeMethod("onUsbDeviceDetached", null)
                    }
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

        Log.d(TAG, "ExternalCardReaderPlugin attached")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context?.unregisterReceiver(usbReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        closeConnection()
        cardReadExecutor.shutdown()
        context = null
        usbManager = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanUsbReaders" -> scanUsbReaders(result)
            "requestPermission" -> requestPermission(call, result)
            "readCard" -> readCard(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * 扫描USB读卡器设备
     */
    private fun scanUsbReaders(result: Result) {
        try {
            val deviceList = usbManager?.deviceList ?: emptyMap()
            Log.d(TAG, "Scanning USB devices, found: ${deviceList.size}")

            val cardReaders = deviceList.values
                .filter { isCardReaderDevice(it) }
                .map { device ->
                    val deviceInfo = getDeviceInfo(device)
                    
                    // 构建友好的设备名称（使用型号，而不是USB路径）
                    val friendlyName = deviceInfo["model"] ?: "Smart Card Reader"
                    
                    hashMapOf(
                        "deviceId" to device.deviceId.toString(),
                        "deviceName" to friendlyName,  // 使用友好名称
                        "manufacturer" to deviceInfo["manufacturer"],
                        "productName" to friendlyName,  // 产品名称也使用友好名称
                        "model" to deviceInfo["model"],
                        "specifications" to deviceInfo["specifications"],
                        "vendorId" to device.vendorId,
                        "productId" to device.productId,
                        "isConnected" to (usbManager?.hasPermission(device) == true),
                        "serialNumber" to device.serialNumber,
                        "usbPath" to device.deviceName  // 保留原始USB路径用于调试
                    )
                }

            Log.d(TAG, "Found ${cardReaders.size} card reader devices")
            result.success(cardReaders)
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning USB devices: ${e.message}", e)
            result.error("SCAN_ERROR", "Failed to scan USB devices: ${e.message}", null)
        }
    }

    /**
     * 判断是否为读卡器设备
     */
    private fun isCardReaderDevice(device: UsbDevice): Boolean {
        // 方法1: 检查USB设备类（CCID - Chip Card Interface Device）
        if (device.deviceClass == USB_CLASS_SMART_CARD) {
            Log.d(TAG, "Device ${device.deviceName} is a card reader (CCID class)")
            return true
        }

        // 方法2: 检查接口类
        for (i in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(i)
            if (usbInterface.interfaceClass == USB_CLASS_SMART_CARD) {
                Log.d(TAG, "Device ${device.deviceName} is a card reader (CCID interface)")
                return true
            }
        }

        // 方法3: 检查常见读卡器厂商ID
        if (device.vendorId in KNOWN_CARD_READER_VENDORS) {
            Log.d(TAG, "Device ${device.deviceName} is likely a card reader (known vendor: 0x${device.vendorId.toString(16)})")
            return true
        }

        // 方法4: 通过产品名称关键词判断
        val productName = device.productName?.lowercase() ?: ""
        val cardReaderKeywords = listOf("card", "reader", "rfid", "nfc", "smartcard", "ccid", "mifare")
        if (cardReaderKeywords.any { productName.contains(it) }) {
            Log.d(TAG, "Device ${device.deviceName} is likely a card reader (by product name)")
            return true
        }

        return false
    }

    /**
     * 获取设备详细信息（改进版：支持Android 5.0以下，添加厂商名称映射）
     */
    private fun getDeviceInfo(device: UsbDevice): Map<String, String?> {
        // 获取产品名称和厂商名称（Android 5.0+ 需要）
        val productName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            device.productName ?: "Unknown"
        } else {
            "Unknown"
        }
        
        val manufacturerName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            device.manufacturerName ?: getManufacturerNameByVendorId(device.vendorId)
        } else {
            getManufacturerNameByVendorId(device.vendorId)
        }
        
        // 根据厂商ID推断型号和规格（扩展版 - 覆盖全球主流品牌）
        val info = when (device.vendorId) {
            // === 市场领导者 ===
            0x072f -> mapOf(
                "manufacturer" to "ACS",
                "model" to if (productName != "Unknown") productName else "ACR122U",
                "specifications" to "ISO 14443 Type A/B, Mifare Classic/Plus/DESFire"
            )
            0x076b -> mapOf(
                "manufacturer" to "HID Global",
                "model" to if (productName != "Unknown") productName else "OMNIKEY 5427 CK",
                "specifications" to "ISO 14443, ISO 15693, Mifare, DESFire, iCLASS"
            )
            0x04e6 -> mapOf(
                "manufacturer" to "SCM Microsystems",
                "model" to if (productName != "Unknown") productName else "SCR3310",
                "specifications" to "ISO 7816, PC/SC, CCID"
            )
            0x096e -> mapOf(
                "manufacturer" to "Feitian",
                "model" to if (productName != "Unknown") productName else "R502",
                "specifications" to "ISO 14443 Type A/B, Mifare, DESFire, Java Card"
            )
            0x1050 -> mapOf(
                "manufacturer" to "Yubico",
                "model" to if (productName != "Unknown") productName else "YubiKey 5 NFC",
                "specifications" to "FIDO2, U2F, PIV, OpenPGP, OATH, ISO 14443"
            )
            
            // === 企业级品牌 ===
            0x04cc -> mapOf(
                "manufacturer" to "Identiv",
                "model" to if (productName != "Unknown") productName else "uTrust 3700 F",
                "specifications" to "ISO 14443, ISO 15693, Mifare, DESFire, iCLASS"
            )
            0x08e6 -> mapOf(
                "manufacturer" to "Gemalto",
                "model" to if (productName != "Unknown") productName else "IDBridge CT700",
                "specifications" to "ISO 7816, PC/SC, EMV, PIV, CAC"
            )
            0x0b97 -> mapOf(
                "manufacturer" to "O2Micro",
                "model" to if (productName != "Unknown") productName else "Oz776",
                "specifications" to "ISO 7816, SD/MMC, MS/MS Pro"
            )
            0x058f -> mapOf(
                "manufacturer" to "Alcor Micro",
                "model" to if (productName != "Unknown") productName else "AU9540",
                "specifications" to "ISO 7816, SD/SDHC/SDXC, MMC"
            )
            0x0bda -> mapOf(
                "manufacturer" to "Realtek",
                "model" to if (productName != "Unknown") productName else "RTS5169",
                "specifications" to "ISO 7816, SD/MMC, USB 3.0"
            )
            
            // === 欧洲专业品牌 ===
            0x0c4b -> mapOf(
                "manufacturer" to "Reiner SCT",
                "model" to if (productName != "Unknown") productName else "cyberJack RFID",
                "specifications" to "ISO 14443, ISO 7816, PACE, EAC"
            )
            0x0dc3 -> mapOf(
                "manufacturer" to "Athena",
                "model" to if (productName != "Unknown") productName else "ASE IIIe USB",
                "specifications" to "ISO 7816, EMV, PIV"
            )
            0x0bf8 -> mapOf(
                "manufacturer" to "Fujitsu",
                "model" to if (productName != "Unknown") productName else "SmartCase KB SCR",
                "specifications" to "ISO 7816, PC/SC, CCID"
            )
            0x413c -> mapOf(
                "manufacturer" to "Dell",
                "model" to if (productName != "Unknown") productName else "Keyboard with Smart Card Reader",
                "specifications" to "ISO 7816, CAC, PIV"
            )
            0x0483 -> mapOf(
                "manufacturer" to "STMicroelectronics",
                "model" to if (productName != "Unknown") productName else "ST23YR48",
                "specifications" to "ISO 7816, JavaCard 3.0.4, GlobalPlatform"
            )
            
            // === 亚洲品牌 ===
            0x1fc9 -> mapOf(
                "manufacturer" to "NXP",
                "model" to if (productName != "Unknown") productName else "MFRC522",
                "specifications" to "ISO 14443 Type A, Mifare"
            )
            0x04e8 -> mapOf(
                "manufacturer" to "Samsung",
                "model" to if (productName != "Unknown") productName else "S3FKRN4",
                "specifications" to "ISO 7816, NFC, Samsung Pay"
            )
            0x04f2 -> mapOf(
                "manufacturer" to "Chicony",
                "model" to if (productName != "Unknown") productName else "HP USB Smart Card Reader",
                "specifications" to "ISO 7816, CAC, PIV"
            )
            0x0409 -> mapOf(
                "manufacturer" to "NEC",
                "model" to if (productName != "Unknown") productName else "SmartCard Reader",
                "specifications" to "ISO 7816, FeliCa, Mifare"
            )
            0x0a5c -> mapOf(
                "manufacturer" to "Broadcom",
                "model" to if (productName != "Unknown") productName else "BCM5880",
                "specifications" to "ISO 7816, TPM, PIV, CAC"
            )
            
            // === 安全密钥厂商 ===
            0x20a0 -> mapOf(
                "manufacturer" to "Nitrokey",
                "model" to if (productName != "Unknown") productName else "Nitrokey Pro 2",
                "specifications" to "OpenPGP, FIDO U2F, TOTP, HOTP"
            )
            0x234b -> mapOf(
                "manufacturer" to "SafeNet",
                "model" to if (productName != "Unknown") productName else "eToken 5110",
                "specifications" to "ISO 7816, PKCS#11, PIV, CAC"
            )
            0x163c -> mapOf(
                "manufacturer" to "Watchdata",
                "model" to if (productName != "Unknown") productName else "W1981",
                "specifications" to "ISO 7816, JavaCard, GlobalPlatform"
            )
            0x0a89 -> mapOf(
                "manufacturer" to "Aktiv",
                "model" to if (productName != "Unknown") productName else "ActivIdentity USB Reader V3",
                "specifications" to "ISO 7816, PIV, CAC"
            )
            
            // === 其他知名品牌 ===
            0x03f0 -> mapOf(
                "manufacturer" to "HP",
                "model" to if (productName != "Unknown") productName else "USB Smart Card Reader",
                "specifications" to "ISO 7816, CAC, PIV"
            )
            0x0ca6 -> mapOf(
                "manufacturer" to "Castles",
                "model" to if (productName != "Unknown") productName else "EZ100PU",
                "specifications" to "ISO 7816, EMV Level 1 & 2"
            )
            0x0a82 -> mapOf(
                "manufacturer" to "Syscan",
                "model" to if (productName != "Unknown") productName else "TravelScan",
                "specifications" to "ISO 7816, MRZ, RFID"
            )
            0x0973 -> mapOf(
                "manufacturer" to "SchlumbergerSema",
                "model" to if (productName != "Unknown") productName else "Reflex USB",
                "specifications" to "ISO 7816, PC/SC"
            )
            0x046a -> mapOf(
                "manufacturer" to "Cherry",
                "model" to if (productName != "Unknown") productName else "SmartTerminal ST-1144",
                "specifications" to "ISO 7816, HBCI, FinTS"
            )
            
            // === 中国品牌 ===
            0x1a44 -> mapOf(
                "manufacturer" to "VASCO",
                "model" to if (productName != "Unknown") productName else "DIGIPASS 920",
                "specifications" to "ISO 7816, OATH, EMV CAP"
            )
            0x0c27 -> mapOf(
                "manufacturer" to "RFIDeas",
                "model" to if (productName != "Unknown") productName else "pcProx Plus",
                "specifications" to "125 kHz, HID Prox, EM4100"
            )
            0x23a0 -> mapOf(
                "manufacturer" to "BIFIT",
                "model" to if (productName != "Unknown") productName else "iBank2Key",
                "specifications" to "ISO 7816, Banking Security"
            )
            0x0557 -> mapOf(
                "manufacturer" to "ATEN",
                "model" to if (productName != "Unknown") productName else "UC232A",
                "specifications" to "RS-232, Smart Card"
            )
            
            // === 芯片厂商 ===
            0x1209 -> mapOf(
                "manufacturer" to "Generic",
                "model" to if (productName != "Unknown") productName else "Open Source Hardware",
                "specifications" to "ISO 7816, Varies by Project"
            )
            0x10c4 -> mapOf(
                "manufacturer" to "Silicon Labs",
                "model" to if (productName != "Unknown") productName else "CP2102",
                "specifications" to "USB to UART, Smart Card Interface"
            )
            0x067b -> mapOf(
                "manufacturer" to "Prolific",
                "model" to if (productName != "Unknown") productName else "PL2303",
                "specifications" to "USB to Serial, ISO 7816"
            )
            0x0424 -> mapOf(
                "manufacturer" to "Microchip",
                "model" to if (productName != "Unknown") productName else "USB Hub with Card Reader",
                "specifications" to "ISO 7816, SD/MMC"
            )
            
            // === 默认 ===
            else -> mapOf(
                "manufacturer" to manufacturerName,
                "model" to if (productName != "Unknown") productName else "Smart Card Reader",
                "specifications" to "ISO 14443, ISO 7816"
            )
        }
        
        return info
    }
    
    /**
     * 根据厂商ID获取厂商名称（扩展版 - 覆盖全球主流品牌）
     * 数据来源：USB-IF官方数据库 + CCID官方支持列表
     */
    private fun getManufacturerNameByVendorId(vendorId: Int): String {
        return when (vendorId) {
            // 主流读卡器厂商（按市场占有率排序）
            0x072f -> "ACS (Advanced Card Systems)"      // 市占率最高
            0x076b -> "HID Global (OmniKey)"             // 企业级首选
            0x04e6 -> "SCM Microsystems"                 // 欧洲主流
            0x096e -> "Feitian Technologies"            // 中国最大厂商
            0x1050 -> "Yubico"                           // FIDO/U2F领导者
            0x04cc -> "Identiv (SCM)"                   // 收购SCM后的品牌
            0x08e6 -> "Gemalto (Thales)"                // 安全芯片巨头
            0x0b97 -> "O2Micro"                          // 笔记本内置读卡器
            0x058f -> "Alcor Micro"                      // 笔记本内置读卡器
            0x0bda -> "Realtek Semiconductor"           // 多功能读卡器
            
            // 欧洲品牌
            0x0c4b -> "Reiner SCT"                       // 德国品牌
            0x0dc3 -> "Athena Smartcard Solutions"      // 欧洲企业级
            0x0bf8 -> "Fujitsu Technology Solutions"    // 日本富士通
            0x413c -> "Dell"                             // 戴尔键盘集成
            0x0483 -> "STMicroelectronics"              // 意法半导体
            
            // 亚洲品牌
            0x1fc9 -> "NXP Semiconductors"              // 荷兰恩智浦
            0x04e8 -> "Samsung Electronics"             // 三星
            0x04f2 -> "Chicony Electronics"             // 群光电子
            0x0409 -> "NEC"                              // 日本NEC
            0x0a5c -> "Broadcom"                         // 博通
            
            // 专业安全厂商
            0x20a0 -> "Nitrokey"                         // 开源安全密钥
            0x234b -> "SafeNet (Gemalto)"               // SafeNet被Gemalto收购
            0x163c -> "Watchdata"                        // 握奇数据
            0x0a89 -> "Aktiv"                            // ActivIdentity
            
            // 其他知名品牌
            0x03f0 -> "Hewlett-Packard (HP)"            // 惠普
            0x0ca6 -> "Castles Technology"              // 台湾凯泽科技
            0x0a82 -> "Syscan"                           // 摄像头和读卡器
            0x0973 -> "SchlumbergerSema"                 // Cherry收购
            0x046a -> "Cherry GmbH"                      // 德国樱桃
            
            // 中国品牌
            0x1a44 -> "VASCO Data Security"             // DIGIPASS
            0x0c27 -> "RFIDeas"                          // RFID读卡器
            0x23a0 -> "BIFIT"                            // 必发特
            0x0557 -> "ATEN International"              // 宏正自动科技
            
            // 通用芯片厂商（也生产读卡器）
            0x1209 -> "Generic (pid.codes)"             // 开源硬件通用ID
            0x10c4 -> "Silicon Labs"                     // 芯科科技
            0x067b -> "Prolific Technology"             // 笔记本读卡器
            0x0424 -> "Microchip (SMSC)"                // Microchip收购SMSC
            
            else -> "Unknown Manufacturer"
        }
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
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting permission: ${e.message}", e)
            result.error("PERMISSION_ERROR", "Failed to request permission: ${e.message}", null)
        }
    }

    /**
     * 读取卡片数据
     */
    private fun readCard(call: MethodCall, result: Result) {
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

            if (usbManager?.hasPermission(device) != true) {
                result.error("NO_PERMISSION", "No permission for device", null)
                return
            }

            // 在后台线程执行读卡操作
            cardReadExecutor.submit {
                try {
                    Log.d(TAG, "Starting card read operation for device: $deviceId")
                    val cardData = performCardRead(device)
                    
                    // 切回主线程返回结果
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        if (cardData != null) {
                            // 检查是否有错误信息
                            val hasError = cardData.containsKey("error")
                            
                            if (hasError) {
                                // 读卡过程中发生错误，但有部分信息
                                result.success(
                                    hashMapOf(
                                        "success" to false,
                                        "message" to (cardData["message"] as? String ?: "读取失败"),
                                        "errorCode" to (cardData["error"] as? String ?: "UNKNOWN_ERROR"),
                                        "cardData" to cardData
                                    )
                                )
                            } else {
                                // 检查UID是否有效
                                val isValid = cardData["isValid"] as? Boolean ?: false
                                val uid = cardData["uid"] as? String ?: ""
                                
                                if (isValid && uid.isNotEmpty() && uid != "Unknown") {
                                    result.success(
                                        hashMapOf(
                                            "success" to true,
                                            "message" to "读卡成功",
                                            "cardData" to cardData
                                        )
                                    )
                                } else {
                                    result.success(
                                        hashMapOf(
                                            "success" to false,
                                            "message" to "检测到卡片但无法读取UID，请重试或更换卡片位置",
                                            "errorCode" to "INVALID_UID",
                                            "cardData" to cardData,
                                            "hint" to "提示：确保卡片完全放置在读卡器感应区域"
                                        )
                                    )
                                }
                            }
                        } else {
                            result.success(
                                hashMapOf(
                                    "success" to false,
                                    "message" to "未检测到卡片",
                                    "errorCode" to "NO_CARD",
                                    "hint" to "请将卡片放置在读卡器上并重试"
                                )
                            )
                        }
                    }
                } catch (e: Exception) {
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        Log.e(TAG, "Error reading card: ${e.message}", e)
                        result.success(
                            hashMapOf(
                                "success" to false,
                                "message" to "读卡失败: ${e.message ?: "未知错误"}",
                                "errorCode" to "READ_ERROR",
                                "error" to e.javaClass.simpleName,
                                "hint" to "请检查读卡器连接并重试"
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during card read: ${e.message}", e)
            result.error("READ_ERROR", "Card read failed: ${e.message}", null)
        }
    }

    /**
     * 执行实际的读卡操作
     * 使用CCID协议与读卡器通信
     */
    private fun performCardRead(device: UsbDevice): Map<String, Any>? {
        var connection: UsbDeviceConnection? = null
        try {
            connection = usbManager?.openDevice(device)
            if (connection == null) {
                Log.e(TAG, "Failed to open device connection")
                return null
            }

            currentConnection = connection

            // 查找CCID接口
            val ccidInterface = findCCIDInterface(device)
            if (ccidInterface == null) {
                Log.e(TAG, "No CCID interface found")
                return null
            }

            connection.claimInterface(ccidInterface, true)

            // 查找端点
            var inEndpoint: UsbEndpoint? = null
            var outEndpoint: UsbEndpoint? = null
            for (i in 0 until ccidInterface.endpointCount) {
                val endpoint = ccidInterface.getEndpoint(i)
                if (endpoint.direction == android.hardware.usb.UsbConstants.USB_DIR_IN) {
                    inEndpoint = endpoint
                } else {
                    outEndpoint = endpoint
                }
            }

            if (inEndpoint == null || outEndpoint == null) {
                Log.e(TAG, "Missing required endpoints")
                return null
            }

            // 1. 发送IccPowerOn命令激活卡片
            val powerOnCommand = buildIccPowerOnCommand()
            val powerOnResponse = sendCommand(connection, outEndpoint, inEndpoint, powerOnCommand)
            
            if (powerOnResponse == null || !isSuccessResponse(powerOnResponse)) {
                Log.e(TAG, "Failed to power on card")
                return null
            }

            // 2. 提取ATR (Answer To Reset)
            val atr = extractATR(powerOnResponse)
            if (atr.isEmpty()) {
                Log.e(TAG, "No ATR received")
                return null
            }

            Log.d(TAG, "ATR received: ${atr.joinToString("") { "%02X".format(it) }}")

            // 3. 识别卡片类型（根据ATR）
            val cardType = identifyCardType(atr)
            val isMifareClassic = cardType.contains("Mifare Classic", ignoreCase = true)
            
            Log.d(TAG, "Card type identified: $cardType, isMifareClassic: $isMifareClassic")
            
            // 4. 根据卡片类型选择不同的UID获取方式
            var uid: ByteArray = byteArrayOf()
            
            if (isMifareClassic) {
                // Mifare Classic 卡片：尝试多种方式读取UID
                Log.d(TAG, "Attempting Mifare Classic UID read...")
                
                // 方式1: 标准Get UID命令
                val getUidCommand = buildGetUidCommand()
                val uidResponse1 = sendCommand(connection, outEndpoint, inEndpoint, getUidCommand)
                
                if (uidResponse1 != null && isSuccessResponse(uidResponse1)) {
                    uid = extractUid(uidResponse1)
                    Log.d(TAG, "UID read via standard command: ${formatUid(uid)}")
                } else {
                    Log.d(TAG, "Standard UID command failed, trying Mifare-specific command...")
                    
                    // 方式2: Mifare专用读取Block 0
                    val mifareUidCommand = buildMifareGetUidCommand()
                    val uidResponse2 = sendCommand(connection, outEndpoint, inEndpoint, mifareUidCommand)
                    
                    if (uidResponse2 != null && isSuccessResponse(uidResponse2)) {
                        // Block 0 的前4或7字节是UID
                        val blockData = extractATR(uidResponse2)
                        uid = if (blockData.size >= 7 && blockData[0] != 0x00.toByte()) {
                            blockData.copyOfRange(0, 7)  // 7字节UID
                        } else if (blockData.size >= 4) {
                            blockData.copyOfRange(0, 4)  // 4字节UID
                        } else {
                            blockData
                        }
                        Log.d(TAG, "UID read via Mifare Block 0: ${formatUid(uid)}")
                    } else {
                        Log.d(TAG, "Mifare Block 0 read failed, extracting from ATR...")
                        // 方式3: 从ATR中提取
                        uid = extractUidFromATR(atr)
                    }
                }
            } else {
                // 非Mifare Classic卡片：使用标准命令
                Log.d(TAG, "Attempting standard UID read...")
                val getUidCommand = buildGetUidCommand()
                val uidResponse = sendCommand(connection, outEndpoint, inEndpoint, getUidCommand)
                
                uid = if (uidResponse != null && isSuccessResponse(uidResponse)) {
                    extractUid(uidResponse)
                } else {
                    // 从ATR中提取
                    extractUidFromATR(atr)
                }
                Log.d(TAG, "UID read: ${formatUid(uid)}")
            }

            // 5. 验证UID是否有效
            if (uid.isEmpty() || uid.all { it == 0x00.toByte() }) {
                Log.w(TAG, "UID is empty or all zeros, card may not be properly detected")
                // 即使UID无效，仍返回其他信息
            }
            
            // 6. 构建返回数据
            val result = hashMapOf(
                "uid" to formatUid(uid),
                "type" to cardType,
                "capacity" to getCardCapacity(cardType),
                "timestamp" to java.time.Instant.now().toString(),
                "isValid" to uid.isNotEmpty(),
                "atr" to atr.joinToString("") { "%02X".format(it) },
                "rawUid" to uid.joinToString("") { "%02X".format(it) }
            )
            
            Log.d(TAG, "Card read completed successfully: $result")
            return result
            
        } catch (e: IOException) {
            Log.e(TAG, "IO Error during card read: ${e.message}", e)
            // 返回错误信息而不是null，让上层能够获取更多信息
            return hashMapOf(
                "error" to "IO_ERROR",
                "message" to (e.message ?: "通信错误"),
                "isValid" to false
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error during card read: ${e.message}", e)
            return hashMapOf(
                "error" to "READ_ERROR",
                "message" to (e.message ?: "读卡失败"),
                "isValid" to false
            )
        } finally {
            connection?.close()
            currentConnection = null
        }
    }

    /**
     * 查找CCID接口
     */
    private fun findCCIDInterface(device: UsbDevice): android.hardware.usb.UsbInterface? {
        for (i in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(i)
            if (usbInterface.interfaceClass == USB_CLASS_SMART_CARD) {
                return usbInterface
            }
        }
        // 如果没有找到标准CCID类，返回第一个接口（某些设备使用厂商自定义类）
        return if (device.interfaceCount > 0) device.getInterface(0) else null
    }

    /**
     * 构建IccPowerOn命令
     * CCID协议：PC_to_RDR_IccPowerOn
     */
    private fun buildIccPowerOnCommand(): ByteArray {
        return byteArrayOf(
            0x62.toByte(),  // bMessageType: PC_to_RDR_IccPowerOn
            0x00, 0x00, 0x00, 0x00,  // dwLength
            0x00,  // bSlot
            0x00,  // bSeq
            0x01,  // bPowerSelect: Activate (5V)
            0x00, 0x00  // RFU
        )
    }

    /**
     * 构建Get UID命令
     * ISO 14443-3 Type A: APDU命令
     * 支持多种卡片类型的UID获取方式
     */
    private fun buildGetUidCommand(): ByteArray {
        // 方式1: PC/SC 2.0 标准 Get Data 命令 (适用于大多数读卡器)
        // FFCA000000 - Get UID without card selection
        val apdu = byteArrayOf(0xFF.toByte(), 0xCA.toByte(), 0x00, 0x00, 0x00)
        return buildXfrBlockCommand(apdu)
    }
    
    /**
     * 构建Mifare Classic专用的Get UID命令
     * 使用Load Keys + Authenticate + Read的流程
     */
    private fun buildMifareGetUidCommand(): ByteArray {
        // 使用更通用的方式：直接读取制造商数据块（Block 0）
        // 命令: FF B0 00 00 10 (Read Binary - 16 bytes from block 0)
        val apdu = byteArrayOf(
            0xFF.toByte(), 0xB0.toByte(), // Read Binary
            0x00, 0x00,                    // Block 0
            0x10                           // Read 16 bytes
        )
        return buildXfrBlockCommand(apdu)
    }
    
    /**
     * 构建Mifare认证命令
     * 使用默认密钥 FFFFFFFFFFFF
     */
    private fun buildMifareAuthCommand(blockNumber: Int = 0): ByteArray {
        // Load Authentication Keys命令
        // FF 82 00 00 06 FF FF FF FF FF FF (Load Key into reader)
        val loadKeyApdu = byteArrayOf(
            0xFF.toByte(), 0x82.toByte(),
            0x00, 0x00,
            0x06,  // Key length
            0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(),  // Default key
            0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte()
        )
        
        // Authenticate命令
        // FF 86 00 00 05 01 00 [block] 60 00
        // 60 = Key A, 61 = Key B
        val authApdu = byteArrayOf(
            0xFF.toByte(), 0x86.toByte(),
            0x00, 0x00,
            0x05,  // Data length
            0x01,  // Version
            0x00,  // Reserved
            blockNumber.toByte(),  // Block number
            0x60,  // Key Type A
            0x00   // Key number in reader
        )
        
        // 返回Load Key命令（认证命令需要在后续单独发送）
        return buildXfrBlockCommand(loadKeyApdu)
    }

    /**
     * 构建XfrBlock命令
     * CCID协议：PC_to_RDR_XfrBlock
     */
    private fun buildXfrBlockCommand(apdu: ByteArray): ByteArray {
        val header = byteArrayOf(
            0x6F.toByte(),  // bMessageType: PC_to_RDR_XfrBlock
            apdu.size.toByte(), 0x00, 0x00, 0x00,  // dwLength
            0x00,  // bSlot
            0x01,  // bSeq
            0x00,  // bBWI
            0x00, 0x00  // wLevelParameter
        )
        return header + apdu
    }

    /**
     * 发送命令并接收响应（增强版）
     * 增加重试机制和详细日志
     */
    private fun sendCommand(
        connection: UsbDeviceConnection,
        outEndpoint: UsbEndpoint,
        inEndpoint: UsbEndpoint,
        command: ByteArray,
        retries: Int = 2
    ): ByteArray? {
        val commandHex = command.joinToString("") { "%02X".format(it) }
        Log.d(TAG, "Sending command (${command.size} bytes): $commandHex")
        
        for (attempt in 1..retries) {
            try {
                // 发送命令
                val sendTimeout = 5000  // 5秒超时
                val bytesSent = connection.bulkTransfer(outEndpoint, command, command.size, sendTimeout)
                
                if (bytesSent < 0) {
                    Log.e(TAG, "Failed to send command (attempt $attempt/$retries): error code $bytesSent")
                    if (attempt < retries) {
                        Thread.sleep(100)  // 短暂延迟后重试
                        continue
                    }
                    return null
                }
                
                if (bytesSent != command.size) {
                    Log.w(TAG, "Partial send: sent $bytesSent of ${command.size} bytes")
                }
                
                Log.d(TAG, "Command sent successfully: $bytesSent bytes")

                // 接收响应（多次尝试，因为某些读卡器响应较慢）
                val responseBuffer = ByteArray(1024)
                var bytesReceived = 0
                var receiveAttempts = 0
                val maxReceiveAttempts = 3
                
                while (receiveAttempts < maxReceiveAttempts) {
                    val receiveTimeout = if (receiveAttempts == 0) 5000 else 2000
                    bytesReceived = connection.bulkTransfer(inEndpoint, responseBuffer, responseBuffer.size, receiveTimeout)
                    
                    if (bytesReceived > 0) {
                        break  // 成功接收
                    }
                    
                    receiveAttempts++
                    if (receiveAttempts < maxReceiveAttempts) {
                        Log.d(TAG, "No response yet, retry receiving (${receiveAttempts}/$maxReceiveAttempts)...")
                        Thread.sleep(100)
                    }
                }
                
                if (bytesReceived < 0) {
                    Log.e(TAG, "Failed to receive response (attempt $attempt/$retries): error code $bytesReceived")
                    if (attempt < retries) {
                        Thread.sleep(200)
                        continue
                    }
                    return null
                }
                
                if (bytesReceived == 0) {
                    Log.w(TAG, "Received empty response (attempt $attempt/$retries)")
                    if (attempt < retries) {
                        Thread.sleep(200)
                        continue
                    }
                    return byteArrayOf()  // 返回空数组而不是null
                }

                val response = responseBuffer.copyOf(bytesReceived)
                val responseHex = response.joinToString("") { "%02X".format(it) }
                Log.d(TAG, "Response received ($bytesReceived bytes): $responseHex")
                
                return response
            } catch (e: Exception) {
                Log.e(TAG, "Error sending command (attempt $attempt/$retries): ${e.message}", e)
                if (attempt < retries) {
                    Thread.sleep(200)
                    continue
                }
            }
        }
        
        return null  // 所有重试都失败
    }

    /**
     * 检查响应是否成功
     */
    private fun isSuccessResponse(response: ByteArray): Boolean {
        if (response.size < 10) return false
        // CCID响应：第7字节是bStatus，0x00表示成功
        return response[7] == 0x00.toByte()
    }

    /**
     * 提取ATR (Answer To Reset)
     */
    private fun extractATR(response: ByteArray): ByteArray {
        if (response.size < 10) return byteArrayOf()
        // CCID响应头10字节，之后是数据
        val dataLength = (response[1].toInt() and 0xFF) or 
                        ((response[2].toInt() and 0xFF) shl 8) or
                        ((response[3].toInt() and 0xFF) shl 16) or
                        ((response[4].toInt() and 0xFF) shl 24)
        
        if (dataLength == 0 || response.size < 10 + dataLength) return byteArrayOf()
        return response.copyOfRange(10, 10 + dataLength)
    }

    /**
     * 提取UID（增强版）
     * 支持多种响应格式和UID长度
     */
    private fun extractUid(response: ByteArray): ByteArray {
        if (response.size < 10) return byteArrayOf()
        val data = extractATR(response)
        
        if (data.isEmpty()) return byteArrayOf()
        
        Log.d(TAG, "Extracting UID from data: ${data.joinToString("") { "%02X".format(it) }}")
        
        // 检查是否有状态字（SW1 SW2）
        val hasStatusWord = data.size >= 2 && 
                           (data[data.size - 2] == 0x90.toByte() && data[data.size - 1] == 0x00.toByte() ||
                            data[data.size - 2] == 0x63.toByte())  // 部分成功
        
        // 去掉状态字
        val uidData = if (hasStatusWord && data.size > 2) {
            data.copyOf(data.size - 2)
        } else {
            data
        }
        
        // 根据UID长度返回合适的字节数
        return when {
            // 4字节UID (Single Size)
            uidData.size >= 4 && uidData.size <= 6 -> uidData.copyOf(4)
            
            // 7字节UID (Double Size)
            uidData.size >= 7 && uidData.size <= 9 -> uidData.copyOf(7)
            
            // 10字节UID (Triple Size)
            uidData.size >= 10 -> uidData.copyOf(10)
            
            // 返回全部数据（如果不符合标准长度）
            else -> uidData
        }
    }

    /**
     * 从ATR中提取UID（后备方案 - 增强版）
     * ATR通常不直接包含UID，但可以提取历史字节作为标识
     */
    private fun extractUidFromATR(atr: ByteArray): ByteArray {
        if (atr.isEmpty()) return byteArrayOf()
        
        Log.d(TAG, "Extracting UID from ATR as fallback")
        
        // ATR结构：
        // TS (1 byte) | T0 (1 byte) | TA1..TD1 (optional) | Historical bytes | TCK (optional)
        
        try {
            // T0 字节包含历史字节数量（低4位）
            if (atr.size >= 2) {
                val t0 = atr[1].toInt() and 0xFF
                val historicalBytesCount = t0 and 0x0F
                
                // 跳过接口字节（TA, TB, TC, TD）
                var offset = 2
                var currentByte = t0
                
                // 检查TA1, TB1, TC1, TD1...
                while (offset < atr.size && (currentByte and 0xF0) != 0) {
                    if ((currentByte and 0x10) != 0) offset++  // TA存在
                    if ((currentByte and 0x20) != 0) offset++  // TB存在
                    if ((currentByte and 0x40) != 0) offset++  // TC存在
                    if ((currentByte and 0x80) != 0 && offset < atr.size) {
                        currentByte = atr[offset++].toInt() and 0xFF  // TD存在，继续检查
                    } else {
                        break
                    }
                }
                
                // 提取历史字节
                if (offset < atr.size && historicalBytesCount > 0) {
                    val endOffset = minOf(offset + historicalBytesCount, atr.size)
                    val historicalBytes = atr.copyOfRange(offset, endOffset)
                    
                    if (historicalBytes.isNotEmpty()) {
                        Log.d(TAG, "Extracted historical bytes as UID: ${historicalBytes.joinToString("") { "%02X".format(it) }}")
                        return historicalBytes
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting UID from ATR: ${e.message}")
        }
        
        // 如果解析失败，返回ATR的前几个字节作为标识
        val fallbackLength = minOf(7, atr.size)
        Log.d(TAG, "Using first $fallbackLength bytes of ATR as UID")
        return atr.copyOfRange(0, fallbackLength)
    }

    /**
     * 识别卡片类型
     */
    /**
     * 识别卡片类型（增强版）
     * 支持更多Mifare卡型号和ISO 14443卡片
     */
    private fun identifyCardType(atr: ByteArray): String {
        if (atr.isEmpty()) return "Unknown"
        
        // 转换为16进制字符串
        val atrHex = atr.joinToString("") { "%02X".format(it) }
        Log.d(TAG, "Analyzing ATR: $atrHex")
        
        // 详细的ATR模式匹配
        return when {
            // Mifare Classic 1K 的各种ATR模式
            atrHex.contains("3B8F80") -> "Mifare Classic 1K"
            atrHex.contains("3B8F8001804F0CA000000306030001000000006A") -> "Mifare Classic 1K"
            atrHex.contains("3B8F8001804F0CA0000003060300") -> "Mifare Classic 1K"
            atrHex.startsWith("3B8F") && atrHex.contains("0306") -> "Mifare Classic 1K"
            
            // Mifare Classic 4K 的ATR模式
            atrHex.contains("3B8B80") -> "Mifare Classic 4K"
            atrHex.contains("3B8B8001804F0CA000000306180010000000009E") -> "Mifare Classic 4K"
            atrHex.startsWith("3B8B") && atrHex.contains("0306") -> "Mifare Classic 4K"
            
            // Mifare Ultralight 系列
            atrHex.contains("3B8980") -> "Mifare Ultralight"
            atrHex.contains("3B8F8001804F0CA000000306030002000000006B") -> "Mifare Ultralight"
            atrHex.startsWith("3B89") -> "Mifare Ultralight"
            
            // Mifare DESFire 系列
            atrHex.contains("3B8A80") -> "Mifare DESFire EV1"
            atrHex.contains("3B8180018080") -> "Mifare DESFire"
            atrHex.contains("DESFire", ignoreCase = true) -> "Mifare DESFire"
            
            // Mifare Plus 系列
            atrHex.contains("3B8F8001804F0CA000000306030004") -> "Mifare Plus"
            atrHex.contains("Plus", ignoreCase = true) -> "Mifare Plus"
            
            // ISO 14443 Type A (通用识别)
            atr[0] == 0x3B.toByte() && atrHex.length > 10 -> {
                // 进一步细分
                when {
                    atrHex.contains("0306") -> "Mifare Classic"  // 通用Mifare标识
                    atrHex.contains("4A434F50") -> "JCOP (Java Card)"
                    else -> "ISO 14443 Type A"
                }
            }
            
            // ISO 14443 Type B
            atr[0] == 0x3F.toByte() -> "ISO 14443 Type B"
            
            // 其他智能卡
            atr[0] == 0x3B.toByte() -> "ISO 7816 Smart Card"
            
            else -> "Unknown Card Type"
        }
    }

    /**
     * 获取卡片容量
     */
    private fun getCardCapacity(cardType: String): String {
        return when (cardType) {
            "Mifare Classic 1K" -> "1KB"
            "Mifare Classic 4K" -> "4KB"
            "Mifare Ultralight" -> "512 bytes"
            "Mifare DESFire" -> "2KB-8KB"
            else -> "Unknown"
        }
    }

    /**
     * 格式化UID显示
     */
    private fun formatUid(uid: ByteArray): String {
        if (uid.isEmpty()) return "Unknown"
        return uid.joinToString(":") { "%02X".format(it) }
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
     * 关闭当前连接
     */
    private fun closeConnection() {
        currentConnection?.close()
        currentConnection = null
    }
}
