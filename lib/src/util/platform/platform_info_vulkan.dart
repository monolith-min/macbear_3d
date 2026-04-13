// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// --- Vulkan 結構體與常數定義 ---
const int VK_SUCCESS = 0;
const int VK_STRUCTURE_TYPE_APPLICATION_INFO = 0;
const int VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO = 1;

final class VkApplicationInfo extends Struct {
  @Int32()
  external int sType;
  external Pointer<Void> pNext;
  external Pointer<Utf8> pApplicationName;
  @Uint32()
  external int applicationVersion;
  external Pointer<Utf8> pEngineName;
  @Uint32()
  external int engineVersion;
  @Uint32()
  external int apiVersion;
}

final class VkInstanceCreateInfo extends Struct {
  @Int32()
  external int sType;
  external Pointer<Void> pNext;
  @Uint32()
  external int flags;
  external Pointer<VkApplicationInfo> pApplicationInfo;
  @Uint32()
  external int enabledLayerCount;
  external Pointer<Pointer<Utf8>> ppEnabledLayerNames;
  @Uint32()
  external int enabledExtensionCount;
  external Pointer<Pointer<Utf8>> ppEnabledExtensionNames;
}

// --- FFI 函式簽名 ---
typedef NativeCreateInstance = Int32 Function(Pointer<VkInstanceCreateInfo>, Pointer<Void>, Pointer<Pointer<Void>>);
typedef DartCreateInstance = int Function(Pointer<VkInstanceCreateInfo>, Pointer<Void>, Pointer<Pointer<Void>>);

typedef NativeDestroyInstance = Void Function(Pointer<Void>, Pointer<Void>);
typedef DartDestroyInstance = void Function(Pointer<Void>, Pointer<Void>);

typedef NativeEnumeratePhysicalDevices = Int32 Function(Pointer<Void>, Pointer<Uint32>, Pointer<Pointer<Void>>);
typedef DartEnumeratePhysicalDevices = int Function(Pointer<Void>, Pointer<Uint32>, Pointer<Pointer<Void>>);

/// 專門負責探測平台 Vulkan 支援狀態的類別
class PlatformInfoVulkan {
  static bool? _isVulkanSupported;
  static String _gpuName = "Unknown";

  static String get gpuName => _gpuName;

  /// 核心判定方法：決定 macbear_3d 應該使用 Vulkan 還是 OpenGL
  static bool shouldInitVulkan() {
    if (_isVulkanSupported != null) return _isVulkanSupported!;

    if (!Platform.isAndroid) {
      _isVulkanSupported = false;
      return false;
    }

    _isVulkanSupported = _probeVulkanHardware();
    return _isVulkanSupported!;
  }

  static bool _probeVulkanHardware() {
    DynamicLibrary libVulkan;
    try {
      libVulkan = DynamicLibrary.open('libvulkan.so');
    } catch (e) {
      debugPrint("[macbear_3d] libvulkan.so not found.");
      return false;
    }

    final vkCreateInstance = libVulkan.lookupFunction<NativeCreateInstance, DartCreateInstance>('vkCreateInstance');
    final vkDestroyInstance = libVulkan.lookupFunction<NativeDestroyInstance, DartDestroyInstance>('vkDestroyInstance');
    final vkEnumeratePhysicalDevices = libVulkan
        .lookupFunction<NativeEnumeratePhysicalDevices, DartEnumeratePhysicalDevices>('vkEnumeratePhysicalDevices');

    Pointer<Void> instance = nullptr;
    final Pointer<Pointer<Void>> instancePtr = calloc<Pointer<Void>>();
    final Pointer<VkInstanceCreateInfo> createInfo = calloc<VkInstanceCreateInfo>();
    final Pointer<VkApplicationInfo> appInfo = calloc<VkApplicationInfo>();

    try {
      // 1. 建立極簡 ApplicationInfo (Vulkan 1.0 以獲得最大相容性)
      appInfo.ref
        ..sType = VK_STRUCTURE_TYPE_APPLICATION_INFO
        ..pApplicationName = "VulkanProbe".toNativeUtf8()
        ..applicationVersion = 1
        ..pEngineName = "macbear_3d".toNativeUtf8()
        ..engineVersion = 1
        ..apiVersion = (1 << 22); // VK_API_VERSION_1_0

      // 2. 建立 InstanceCreateInfo
      createInfo.ref
        ..sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
        ..pApplicationInfo = appInfo
        ..enabledLayerCount = 0
        ..enabledExtensionCount = 0;

      // 3. 嘗試建立 Instance
      int result = vkCreateInstance(createInfo, nullptr, instancePtr);
      if (result != VK_SUCCESS) return false;

      instance = instancePtr.value;

      // 4. 檢查是否有實體設備 (GPU)
      final Pointer<Uint32> deviceCount = calloc<Uint32>();
      vkEnumeratePhysicalDevices(instance, deviceCount, nullptr);

      if (deviceCount.value == 0) {
        vkDestroyInstance(instance, nullptr);
        return false;
      }

      // --- 這裡可以進一步加入黑名單檢查 ---
      // 雖然 GE8320 支援 Vulkan，但如果是在 Android 9 以下或特定型號，
      // 你可以在此處透過 vkGetPhysicalDeviceProperties 獲取 GPU 名稱並過濾。

      debugPrint("[macbear_3d] Vulkan check passed. Found ${deviceCount.value} device(s).");

      // 清理並回傳成功
      vkDestroyInstance(instance, nullptr);
      return true;
    } catch (e) {
      debugPrint("[macbear_3d] Vulkan probe error: $e");
      return false;
    } finally {
      // 釋放記憶體
      malloc.free(appInfo.ref.pApplicationName);
      malloc.free(appInfo.ref.pEngineName);
      malloc.free(appInfo);
      malloc.free(createInfo);
      malloc.free(instancePtr);
    }
  }
}
