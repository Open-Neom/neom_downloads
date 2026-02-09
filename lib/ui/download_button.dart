import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:sint/sint.dart';

import '../data/implementations/download_controller.dart';
import '../utils/constants/download_translation_constants.dart';

class DownloadButton extends StatefulWidget {

  final AppMediaItem mediaItem;
  final double size;

  const DownloadButton({
    super.key,
    required this.mediaItem,
    this.size = 25,
  });

  @override
  DownloadButtonState createState() => DownloadButtonState();
}

class DownloadButtonState extends State<DownloadButton> {
  late DownloadController down;
  final Box downloadsBox = Hive.box('downloads');
  final ValueNotifier<bool> showStopButton = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    down = DownloadController(widget.mediaItem.id);
    down.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: Center(
        child: (downloadsBox.containsKey(widget.mediaItem.id))
            ? IconButton(
                icon: const Icon(Icons.download_done_rounded),
                tooltip: 'Download Done',
                color: Theme.of(context).colorScheme.secondary,
                iconSize: widget.size,
                onPressed: () {
                  down.prepareDownload(context, widget.mediaItem);
                },
              )
            : down.progress == 0
            ? IconButton(icon: const Icon(Icons.save_alt,),
          iconSize: widget.size,
          color: Theme.of(context).iconTheme.color,
          tooltip: AppTranslationConstants.download.tr,
          onPressed: () {down.prepareDownload(context, widget.mediaItem);},
        ) : GestureDetector(
          child: Stack(
            children: [
              Center(
                child: CircularProgressIndicator(
                  value: down.progress == 1 ? null : down.progress,
                ),
              ),
              Center(
                child: ValueListenableBuilder(
                  valueListenable: showStopButton,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                      iconSize: 25.0,
                      color: Theme.of(context).iconTheme.color,
                      tooltip: DownloadTranslationConstants.stopDown.tr,
                      onPressed: () {
                        down.download = false;
                        },
                    ),
                  ),
                  builder: (BuildContext context, bool showValue, Widget? child,) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: !showValue,
                            child: Center(
                              child: Text(down.progress == null
                                    ? '0%' : '${(100 * down.progress!).round()}%',
                              ),
                            ),
                          ),
                          Visibility(
                            visible: showValue,
                            child: child!,
                          ),
                        ],
                      ),
                    );
                    },
                ),
              ),
            ],
          ),
          onTap: () {
            showStopButton.value = true;
            Future.delayed(const Duration(seconds: 2), () async {
              showStopButton.value = false;
            });
          },
        ),
      ),
    );
  }
}
