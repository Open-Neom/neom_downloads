import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/file_downloader.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/use_cases/download_service.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/constants/download_constants.dart';
import '../../utils/constants/download_translation_constants.dart';
import '../../utils/download_utilities.dart';

class DownloadController with ChangeNotifier implements DownloadService {

  static final Map<String, DownloadController> _instances = {};
  final String id;

  factory DownloadController(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = DownloadController._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  DownloadController._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box(AppHiveBox.settings.name).get(DownloadTranslationConstants.downloadQuality, defaultValue: '320 kbps') as String;
  String downloadFormat = Hive.box(AppHiveBox.settings.name).get(DownloadTranslationConstants.downloadFormat, defaultValue: 'm4a').toString();
  bool createDownloadFolder = Hive.box(AppHiveBox.settings.name).get(DownloadTranslationConstants.createDownloadFolder, defaultValue: false) as bool;

  double? progress = 0.0;
  String lastDownloadId = '';
  bool download = true;

  @override
  Future<void> prepareDownload(
    BuildContext context,
    AppMediaItem mediaItem, {
    bool createFolder = false,
    String? folderName,
  }) async {
    AppConfig.logger.i('Preparing download for ${mediaItem.name}');
    download = true;
    if (Platform.isAndroid || Platform.isIOS) {
      AppConfig.logger.i('Requesting storage permission');
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        AppConfig.logger.i('Request denied');
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }
      status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        AppConfig.logger.i('Request permanently denied');
        await openAppSettings();
      }
    }

    mediaItem.name = mediaItem.name.split('(From')[0].trim();

    String filename = '';
    final int downFilename = Hive.box(AppHiveBox.settings.name).get(DownloadTranslationConstants.downFilename, defaultValue: 0) as int;
    if (downFilename == 0) {
      filename = '${mediaItem.name} - ${mediaItem.artist}';
    } else if (downFilename == 1) {
      filename = '${mediaItem.artist} - ${mediaItem.name}';
    } else {
      filename = mediaItem.name;
    }
    // String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath = Hive.box(AppHiveBox.settings.name).get(DownloadTranslationConstants.downloadPath, defaultValue: '') as String;
    AppConfig.logger.i('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(DownloadConstants.avoidRegex, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      AppConfig.logger.i('Cached Download path is empty, getting new path');
      final String? temp = await DownloadUtilities.getExtStorage(
        dirName: 'Music',
        writeAccess: true,
      );
      dlPath = temp!;
    }
    AppConfig.logger.i('New Download path: $dlPath');

        if (createFolder && createDownloadFolder && folderName != null) {
      final String fName = folderName.replaceAll(DownloadConstants.avoidRegex, '');
      dlPath = '$dlPath/$fName';
      if (!await Directory(dlPath).exists()) {
        AppConfig.logger.i('Creating folder $fName');
        await Directory(dlPath).create();
      }
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      AppConfig.logger.i('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = mediaItem.id;
          case 1:
            downloadMediaItem(context, dlPath, filename, mediaItem);
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
          default:
            lastDownloadId = mediaItem.id;
            break;
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                CommonTranslationConstants.alreadyExists.tr,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('"${mediaItem.name}" ${DownloadTranslationConstants.downAgain.tr}',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                        BuildContext context,
                        bool rememberValue,
                        Widget? child,
                      ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(DownloadTranslationConstants.rememberChoice.tr,),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = mediaItem.id;
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              AppTranslationConstants.no.tr,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box(AppHiveBox.downloads.name).delete(mediaItem.id);
                              downloadMediaItem(context, dlPath, filename, mediaItem);
                              rememberOption = 1;
                            },
                            child: Text(DownloadTranslationConstants.yesReplace.tr),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename = filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadMediaItem(context, dlPath, filename, mediaItem);
                            },
                            child: Text(AppTranslationConstants.yes.tr,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary == Colors.white
                                    ? Colors.black : null,
                              ),
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadMediaItem(context, dlPath, filename, mediaItem);
    }
  }

  @override
  Future<void> downloadMediaItem(BuildContext context, String? dlPath,
    String fileName, AppMediaItem mediaItem,) async {
    AppConfig.logger.i('Processing download');
    progress = null;
    notifyListeners();
    String? mediaPath = '';
    String imgPath = '';
    String? appPath;
    final List<int> bytes = [];
    final artName = fileName.replaceAll('.m4a', '.jpg');
    if (!Platform.isWindows) {
      AppConfig.logger.i('Getting App Path for storing image');
      appPath = Hive.box(AppHiveBox.settings.name).get('tempDirPath')?.toString();
      appPath ??= (await getTemporaryDirectory()).path;
    } else {
      final Directory? temp = await getDownloadsDirectory();
      appPath = temp!.path;
    }

    try {
      AppConfig.logger.i('Creating audio file $dlPath/$fileName');
      await File('$dlPath/$fileName').create(recursive: true)
          .then((value) => mediaPath = value.path);
      AppConfig.logger.i('Creating image file $appPath/$artName');
      await File('$appPath/$artName').create(recursive: true)
          .then((value) => imgPath = value.path);
    } catch (e) {
      AppConfig.logger.i('Error creating files, requesting additional permission');
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          AppConfig.logger.i('ManageExternalStorage permission is denied, requesting permission',);
          await [Permission.manageExternalStorage,].request();
        }
        status = await Permission.manageExternalStorage.status;
        if (status.isPermanentlyDenied) {
          AppConfig.logger.i('ManageExternalStorage Request is permanently denied, opening settings',);
          await openAppSettings();
        }
      }

      AppConfig.logger.i('Retrying to create audio file');
      await File('$dlPath/$fileName').create(recursive: true)
          .then((value) => mediaPath = value.path);

      AppConfig.logger.i('Retrying to create image file');
      await File('$appPath/$artName').create(recursive: true)
          .then((value) => imgPath = value.path);
    }
    final String kUrl = mediaItem.url;

    AppConfig.logger.i('Connecting to Client');
    final client = Client();
    final response = await client.send(Request('GET', Uri.parse(kUrl)));
    final int total = response.contentLength ?? 0;
    int received = 0;
    AppConfig.logger.i('Client connected, Starting download');
    response.stream.asBroadcastStream();
    AppConfig.logger.i('broadcasting download state');
    response.stream.listen((value) {
      bytes.addAll(value);
      try {
        received += value.length;
        progress = received / total;
        notifyListeners();
        if (!download) {
          client.close();
        }
      } catch (e) {
        AppConfig.logger.e('Error in download: $e');
      }
    }).onDone(() async {
      if (download) {
        AppConfig.logger.i('Download complete, modifying file');
        final file = File(mediaPath!);
        await file.writeAsBytes(bytes);
        imgPath = await FileDownloader.downloadImage(mediaItem.imgUrl);
        if(mediaItem.lyrics.isNotEmpty) AppConfig.logger.i('Getting audio tags');
        if (Platform.isAndroid) {
          try {
            AppConfig.logger.i('Started tag editing');
            // await Future.delayed(const Duration(seconds: 1), () async {
            //   if (await file2.exists()) {
            //     await file2.delete();
            //   }
            // });
          } catch (e) {
            AppConfig.logger.e('Error editing tags: $e');
          }
        } else {
          ///This would be needed when adding offline mode downloading audio.
          // Set metadata to file
          // await MetadataGod.writeMetadata(
          //   file: mediaPath!,
          //   metadata: Metadata(
          //     title: mediaItem.name,
          //     artist: mediaItem.artist,
          //     albumArtist: mediaItem.artist,
          //     album: mediaItem.album,
          //     genre: mediaItem.language,
          //     year: mediaItem.publishedYear,
          //     durationMs: mediaItem.duration * 1000,
          //     fileSize: BigInt.from(file.lengthSync()),
          //     picture: Picture(
          //       data: File(imgPath).readAsBytesSync(),
          //       mimeType: 'image/jpeg',
          //     ),
          //   ),
          // );
        }

        AppConfig.logger.i('Closing connection & notifying listeners');
        client.close();
        lastDownloadId = mediaItem.id;
        progress = 0.0;
        notifyListeners();

        AppConfig.logger.i('Putting data to downloads database');
        final AppMediaItem downloadedMediaItem = mediaItem;

        downloadedMediaItem.path = mediaPath;
        downloadedMediaItem.imgUrl = imgPath;
        downloadedMediaItem.mediaSource = AppMediaSource.offline;

        Hive.box(AppHiveBox.downloads.name).put(downloadedMediaItem.id, downloadedMediaItem.toJSON());

        AppConfig.logger.i('Everything done, showing snackbar');
        AppUtilities.showSnackBar(
          message: '"${mediaItem.name}" ${DownloadTranslationConstants.downed.tr}',
        );
      } else {
        download = true;
        progress = 0.0;
        File(mediaPath!).delete();
        File(imgPath).delete();
      }
    });
  }
}
