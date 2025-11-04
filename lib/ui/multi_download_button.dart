import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import '../data/implementations/download_controller.dart';
import '../utils/constants/download_translation_constants.dart';

class MultiDownloadButton extends StatefulWidget {
  final List data;
  final String playlistName;
  const MultiDownloadButton({
    super.key,
    required this.data,
    required this.playlistName,
  });

  @override
  MultiDownloadButtonState createState() => MultiDownloadButtonState();
}

class MultiDownloadButtonState extends State<MultiDownloadButton> {
  late DownloadController down;
  int done = 0;

  @override
  void initState() {
    super.initState();
    down = DownloadController(widget.data.first['id'].toString());
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: (down.lastDownloadId == widget.data.last['id'])
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: DownloadTranslationConstants.downDone.tr,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      tooltip: DownloadTranslationConstants.down.tr,
                      onPressed: () async {
                        for (final items in widget.data) {
                          AppMediaItem appMediaItem = AppMediaItem.fromJSON(items);
                          down.prepareDownload(
                            context,
                            appMediaItem,
                            createFolder: true,
                            folderName: widget.playlistName,
                          );
                          await _waitUntilDone(appMediaItem.id);
                          setState(() {
                            done++;
                          });
                        }
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: done / widget.data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
