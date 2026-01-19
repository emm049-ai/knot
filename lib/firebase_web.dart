// Stub implementations for web (Firebase not available)
class Firebase {
  static Future<void> initializeApp() async {
    // Stub - does nothing on web
  }
}

class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging();
  
  Future<NotificationSettings> requestPermission({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    return NotificationSettings();
  }
  
  Stream<RemoteMessage> get onMessage => const Stream.empty();
}

class NotificationSettings {
  // Stub
}

class RemoteMessage {
  final dynamic notification;
  RemoteMessage({this.notification});
}
