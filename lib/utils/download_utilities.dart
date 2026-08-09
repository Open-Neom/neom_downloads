import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadUtilities {

  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  // getting external storage path
  static Future<String?> getExtStorage({
    required String dirName,
    required bool writeAccess,
  }) async {
    // path_provider speaks dart:io types while this module imports core_io;
    // crossing between them through plain path strings keeps every platform
    // compiling and analyzing cleanly.
    String? androidPath;

    try {
      if (kIsWeb) return null;
      // checking platform
      if (Platform.isAndroid) {
        if (await requestPermission(Permission.storage)) {
          final extDir = await getExternalStorageDirectory();

          // getting main path
          final String newPath = (extDir!).path
              .replaceFirst('Android/data/com.your.app/files', dirName);
          androidPath = newPath;

          final directory = Directory(newPath);

          // checking if directory exist or not
          if (!await directory.exists()) {
            // if directory not exists then asking for permission to create folder
            await requestPermission(Permission.manageExternalStorage);
            //creating folder

            await directory.create(recursive: true);
          }
          if (await directory.exists()) {
            try {
              if (writeAccess) {
                await requestPermission(Permission.manageExternalStorage);
              }
              // if directory exists then returning the complete path
              return newPath;
            } catch (e) {
              rethrow;
            }
          }
        } else {
          return throw 'something went wrong';
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      } else {
        final dir = await getDownloadsDirectory();
        return dir!.path;
      }
    } catch (e) {
      rethrow;
    }
    return androidPath;
  }
}
