// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hive/hive.dart';
// import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/app_theme.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
// import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
//
// import '../../../domain/use_cases/ext_storage_provider.dart';
// import 'package:neom_media_player/utils/constants/player_translation_constants.dart';
// import '../../../utils/helpers/picker.dart';
// import '../settings/widgets/hive_box_switch_tile.dart';
//
//
// class DownloadSettingsPage extends StatefulWidget {
//   const DownloadSettingsPage({super.key});
//
//   @override
//   State<DownloadSettingsPage> createState() => _DownloadSettingsPageState();
// }
//
// class _DownloadSettingsPageState extends State<DownloadSettingsPage> {
//   final Box settingsBox = Hive.box(AppHiveBox.settings.name);
//   String downloadPath = Hive.box(AppHiveBox.settings.name).get('downloadPath', defaultValue: '/storage/emulated/0/Music') as String;
//   String downloadQuality = Hive.box(AppHiveBox.settings.name).get('downloadQuality', defaultValue: '320 kbps') as String;
//   int downFilename = Hive.box(AppHiveBox.settings.name).get('downFilename', defaultValue: 0) as int;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: AppColor.main50,
//         appBar: AppBarChild(title: PlayerTranslationConstants.downloads.tr,),
//         body: Container(
//           decoration: AppTheme.appBoxDecoration,
//           child: ListView(
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.all(10.0),
//             children: [
//               ListTile(
//                 title: Text(PlayerTranslationConstants.downQuality.tr,),
//                 subtitle: Text(PlayerTranslationConstants.downQualitySub.tr,),
//                 onTap: () {},
//                 trailing: DropdownButton(
//                   value: downloadQuality,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Theme.of(context).textTheme.bodyLarge!.color,
//                   ),
//                   underline: const SizedBox.shrink(),
//                   onChanged: (String? newValue) {
//                     if (newValue != null) {
//                       setState(
//                         () {
//                           downloadQuality = newValue;
//                           Hive.box(AppHiveBox.settings.name).put('downloadQuality', newValue);
//                         },
//                       );
//                     }
//                   },
//                   items: <String>['96 kbps', '160 kbps', '320 kbps']
//                       .map<DropdownMenuItem<String>>((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: Text(value,),
//                     );
//                   }).toList(),
//                 ),
//                 dense: true,
//               ),
//               ListTile(
//                 title: Text(
//                   PlayerTranslationConstants.downLocation.tr,
//                 ),
//                 subtitle: Text(downloadPath),
//                 trailing: TextButton(
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: () async {
//                     downloadPath = await ExtStorageProvider.getExtStorage(
//                           dirName: 'Music',
//                           writeAccess: true,
//                         ) ?? '/storage/emulated/0/Music';
//                     Hive.box(AppHiveBox.settings.name).put('downloadPath', downloadPath);
//                     setState(
//                       () {},
//                     );
//                   },
//                   child: Text(
//                     PlayerTranslationConstants.reset.tr,
//                   ),
//                 ),
//                 onTap: () async {
//                   final String temp = await Picker.selectFolder(
//                     context: context,
//                     message: PlayerTranslationConstants.selectDownLocation.tr,
//                   );
//                   if (temp.trim() != '') {
//                     downloadPath = temp;
//                     Hive.box(AppHiveBox.settings.name).put('downloadPath', temp);
//                     setState(
//                       () {},
//                     );
//                   } else {
//                     AppUtilities.showSnackBar(message: PlayerTranslationConstants.noFolderSelected.tr,);
//                   }
//                 },
//                 dense: true,
//               ),
//               ListTile(
//                 title: Text(PlayerTranslationConstants.downFilename.tr,),
//                 subtitle: Text(PlayerTranslationConstants.downFilenameSub.tr,),
//                 dense: true,
//                 onTap: () {
//                   showModalBottomSheet(
//                     isDismissible: true,
//                     backgroundColor: AppColor.main75,
//                     context: context,
//                     builder: (BuildContext context) {
//                       return ListView(
//                           physics: const BouncingScrollPhysics(),
//                           shrinkWrap: true,
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           children: [
//                             CheckboxListTile(
//                               activeColor: Theme.of(context).colorScheme.secondary,
//                               title: Text(
//                                 '${PlayerTranslationConstants.title.tr} - ${PlayerTranslationConstants.artist.tr}',
//                               ),
//                               value: downFilename == 0,
//                               selected: downFilename == 0,
//                               onChanged: (bool? val) {
//                                 if (val ?? false) {
//                                   downFilename = 0;
//                                   settingsBox.put('downFilename', 0);
//                                   Navigator.pop(context);
//                                 }
//                               },
//                             ),
//                             CheckboxListTile(
//                               activeColor: Theme.of(context).colorScheme.secondary,
//                               title: Text(
//                                 '${PlayerTranslationConstants.artist.tr} - ${PlayerTranslationConstants.title.tr}',
//                               ),
//                               value: downFilename == 1,
//                               selected: downFilename == 1,
//                               onChanged: (val) {
//                                 if (val ?? false) {
//                                   downFilename = 1;
//                                   settingsBox.put('downFilename', 1);
//                                   Navigator.pop(context);
//                                 }
//                               },
//                             ),
//                             CheckboxListTile(
//                               activeColor: Theme.of(context).colorScheme.secondary,
//                               title: Text(PlayerTranslationConstants.title.tr,),
//                               value: downFilename == 2,
//                               selected: downFilename == 2,
//                               onChanged: (val) {
//                                 if (val ?? false) {
//                                   downFilename = 2;
//                                   settingsBox.put('downFilename', 2);
//                                   Navigator.pop(context);
//                                 }
//                               },
//                             ),
//                           ],
//
//                       );
//                     },
//                   );
//                 },
//               ),
//               HiveBoxSwitchTile(
//                 title: PlayerTranslationConstants.createAlbumFold.tr,
//                 subtitle: PlayerTranslationConstants.createAlbumFoldSub.tr,
//                 keyName: 'createDownloadFolder',
//                 isThreeLine: true,
//                 defaultValue: false,
//               ),
//             ],
//           ),
//       ),
//     );
//   }
// }
