import 'dart:async';
import 'dart:developer' as developer;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';

class ThermalPrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  // --- التصحيح هنا ---
  // 1. تغيير النوع إلى Stream<int?>
  // 2. إزالة الأقواس () لأن onStateChanged خاصية وليست دالة
  Stream<int?> Function() get connectionState => _bluetooth.onStateChanged;

  /// التحقق مما إذا كان البلوتوث مفعلاً ومتاحاً
  Future<bool> get isAvailable async {
    try {
      return await _bluetooth.isOn ?? false;
    } on PlatformException catch (e) {
      developer.log('Error checking bluetooth availability', error: e, name: 'ThermalPrinterService');
      return false;
    }
  }

  /// التحقق من حالة الاتصال الحالية
  Future<bool> get isConnected async {
    try {
      return await _bluetooth.isConnected ?? false;
    } on PlatformException catch (e) {
      developer.log('Error checking connection status', error: e, name: 'ThermalPrinterService');
      return false;
    }
  }

  /// الحصول على قائمة الأجهزة المقترنة (Bonded Devices)
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } on PlatformException catch (e) {
      developer.log('Error getting bonded devices', error: e, name: 'ThermalPrinterService');
      return [];
    }
  }

  /// الاتصال بجهاز محدد
  Future<bool> connect(BluetoothDevice device) async {
    try {
      if (device.address == null) return false;
      
      // إذا كنا متصلين بالفعل، نحاول إعادة الاتصال لضمان الاستقرار
      if (await isConnected) {
        await disconnect(); 
      }

      developer.log('Connecting to printer: ${device.name} (${device.address})', name: 'ThermalPrinterService');
      await _bluetooth.connect(device);

      // انتظر لتأكيد حالة الاتصال حتى 5 ثواني
      final timeout = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(timeout)) {
        if (await isConnected) {
          developer.log('Printer connected', name: 'ThermalPrinterService');
          return true;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }

      developer.log('Connection attempt timed out', name: 'ThermalPrinterService');
      return false;
    } on PlatformException catch (e) {
      developer.log('Failed to connect to printer', error: e, name: 'ThermalPrinterService');
      return false;
    } catch (e) {
      developer.log('Unexpected error connecting to printer', error: e, name: 'ThermalPrinterService');
      return false;
    }
  }

  /// قطع الاتصال
  Future<bool> disconnect() async {
    try {
      if (await isConnected) {
        await _bluetooth.disconnect();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      developer.log('Failed to disconnect', error: e, name: 'ThermalPrinterService');
      return false;
    }
  }

  /// إرسال أوامر الطباعة (Bytes)
  Future<bool> printBytes(List<int> bytes) async {
    try {
      if (!(await isConnected)) {
        developer.log('Printer not connected', name: 'ThermalPrinterService');
        return false;
      }

      final data = Uint8List.fromList(bytes);
      
      await _bluetooth.writeBytes(data);

      // بعض الأجهزة تحتاج القليل من الوقت لمعالجة البيانات في البافر
      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } on PlatformException catch (e) {
      developer.log('Error printing bytes', error: e, name: 'ThermalPrinterService');
      return false;
    } catch (e) {
      developer.log('Unexpected error during printing', error: e, name: 'ThermalPrinterService');
      return false;
    }
  }

  /// فتح إعدادات البلوتوث في النظام
  Future<void> openBluetoothSettings() async {
    try {
      await _bluetooth.openSettings;
    } catch (e) {
      developer.log('Could not open bluetooth settings', error: e, name: 'ThermalPrinterService');
    }
  }
}