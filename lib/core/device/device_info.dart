/// Thiết bị gửi kèm request đăng nhập (`ClientDeviceRequest` bên backend).
///
/// Không mang push token: thiết bị nhận thông báo được đăng ký riêng bằng FID
/// sau khi đăng nhập -- xem `PushMessagingService.registerDevice`.
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String platform;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
    };
  }
}
