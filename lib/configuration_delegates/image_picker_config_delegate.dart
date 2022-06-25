
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tuple/tuple.dart';

abstract class ImagePickerConfigDelegate {

  /// Background color for the image selector
  /// Status color used for the animated status bar color
  /// Background color used behind the image and album delegate
  final Color backgroundColor;
  final Color statusBarColor;

  ImagePickerConfigDelegate({
    this.backgroundColor = Colors.white, 
    this.statusBarColor = Colors.white
  });
  
  Widget? tileLoadingIndicator(BuildContext context);
  Widget? videoIndicator(BuildContext context, String duration);

  ///Loading Indicator for the Media Viewer
  ///If not used [CircularProgressIndicator] will be its placeholder
  Widget? imageLoadingIndicator(BuildContext context);

  /// Loading Indicator for the albums inside Media Viewer
  /// If not used [CircularProgressIndicator] will be its placeholder
  Widget? albumLoadingIndicator(BuildContext context);

  /// Overlay displayed when images or videos are locked
  Widget? lockOverlayBuilder(BuildContext context, int index);
  
  /// Overlay Widget of the selected asset
  Widget? overlayBuilder(BuildContext context, int index);

  ///MaxExtentHeaderBuilder For the ImagePicker
  ///Displayed when the sliding sheet current extent reaches expanded extent
  Widget headerBuilder(BuildContext context, Widget spacer, String path, bool albumMode, double borderRadius);

  /// Builds the album menu of the image picker
  /// Contains a list of [AssetEntity] mapped to [Uint8List]'s for thumbnails and information
  Widget albumMenuBuilder(BuildContext context, String selectedAlbum, Map<String, Tuple2<AssetPathEntity, Uint8List?>?> assets, ScrollController controller, bool scrollLock, double footerHeight, dynamic Function(AssetPathEntity asset) onSelect);

}