abstract interface class WatchOpenPermission {
  /// The name of a watch connected to this phone, if one is connected.
  Future<String?> connectedWatchName();

  /// Opens the system list of apps, where the wearer can let the app that
  /// manages the watch open other apps from the background.
  Future<void> openAppList();
}
