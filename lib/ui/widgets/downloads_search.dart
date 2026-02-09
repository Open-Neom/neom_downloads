import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

class DownloadsSearch extends SearchDelegate {

  final bool isDowns;
  final List data;

  DownloadsSearch({required this.data, this.isDowns = false});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isEmpty)
        IconButton(
          icon: const Icon(CupertinoIcons.search),
          tooltip: AppTranslationConstants.search.tr,
          onPressed: () {},
        )
      else
        IconButton(
          onPressed: () {
            query = '';
          },
          tooltip: AppTranslationConstants.clear.tr,
          icon: const Icon(
            Icons.clear_rounded,
          ),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: AppTranslationConstants.back.tr,
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : [
            ...{
              ...data.where(
                (element) => element['title']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              ),
              ...data.where(
                (element) => element['artist']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              ),
            },
          ];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: NeomImageCard(
          imageUrl: isDowns
              ? suggestionList[index]['image'].toString()
              : suggestionList[index]['image'].toString(),
          localImage: isDowns,
        ),
        title: Text(
          suggestionList[index]['title'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index]['artist'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isDowns
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ///TODO To implement when adding neom_downloads as dependency
                  ///DownloadButton(mediaItem: AppMediaItem.fromJSON(suggestionList[index] as Map),),
                  // TileTrailingMenu(
                  //   appMediaItem: AppMediaItem.fromJSON(suggestionList[index] as Map),
                  //   itemlist: Itemlist(),
                  //   isPlaylist: true,
                  // ),
                ],
              ),
        onTap: () {
          Sint.find<AudioPlayerInvokerService>().init(
            mediaItems: AppMediaItemMapper.listFromList(suggestionList),
            index: index,
            isOffline: isDowns,
            fromDownloads: isDowns,
            recommend: false,
          );
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : [
            ...{
              ...data.where(
                (element) => element['title']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              ),
              ...data.where(
                (element) => element['artist']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              ),
            },
          ];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: NeomImageCard(
          imageUrl: isDowns
              ? suggestionList[index]['image'].toString()
              : suggestionList[index]['image'].toString(),
          localImage: isDowns,
        ),
        title: Text(
          suggestionList[index]['title'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index]['artist'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Sint.find<AudioPlayerInvokerService>().init(
            mediaItems: AppMediaItemMapper.listFromList(suggestionList),
            index: index,
            isOffline: isDowns,
            fromDownloads: isDowns,
            recommend: false,
          );
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Theme.of(context).colorScheme.secondary,
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: Colors.white),
      hintColor: Colors.white70,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
      textTheme: theme.textTheme.copyWith(
        titleLarge:
            const TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
      ),
      inputDecorationTheme:
          const InputDecorationTheme(focusedBorder: InputBorder.none),
    );
  }

}
