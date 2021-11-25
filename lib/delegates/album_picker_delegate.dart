import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/provider/asset_picker_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sliding_sheet/sliding_sheet.dart';



class AlbumPickerBuilderDelegate {
  AlbumPickerBuilderDelegate(
    this.provider,
    this.pageCubit,
    this.gridScrollController,
    this.albumMenuBuilder,
    this.imagePickerController, {
      this.gridCount = 3,

  });

  final Widget Function(Map<AssetPathEntity, Uint8List?>, ScrollController controller, dynamic Function(AssetPathEntity)) albumMenuBuilder;

  /// The [ScrollController] for the preview grid.
  final ScrollController gridScrollController;

  /// [ChangeNotifier] for asset picker
  final DefaultAssetPickerProvider provider;

  /// Primary cubit for initiating page transitions
  final ConcreteCubit<bool> pageCubit;

  /// The column count inside of the [_sliverGrid]
  final int gridCount;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [ImagePickerBuilderDelegate] accordingly
  final ImagePickerController? imagePickerController;

  /// Keep a dispose method to sync with [State].
  ///
  /// Be aware that the method will do nothing when [keepScrollOffset] is true.
  void dispose() {
    gridScrollController.dispose();
  }

  /// Whether the current platform is Apple OS.
  bool get isAppleOS => Platform.isIOS || Platform.isMacOS;

  //Takes an input [Key], and returns the index of the child element with that associated key, or null if not found.
  int findChildIndexBuilder(String id, List<AssetEntity> assets, {int placeholderCount = 0}) {
    int index = assets.indexWhere((AssetEntity e) => e.id == id);
    index += placeholderCount;
    return index;
  }

  /// Loading indicator
  Widget loadingIndicator(BuildContext context){
    return Center(
      child: SizedBox.fromSize(
        size: Size.square(48.0),
        child: CircularProgressIndicator(
            strokeWidth: 4.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            value: 1.0,
          ),
      ),
    );
  }

  /// Item widgets when the thumb data load failed.
  Widget failedItemBuilder(BuildContext context) {
    return Center(
      child: Container()
    );
  }

  /// Builds the overlapping thumbnail
  Widget thumbnailItemBuilder(
    BuildContext context, Uint8List? thumbNail){
      Widget assetItemBuilder(){
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            width: 36,
            child: thumbNail != null ? Image.memory(
              thumbNail,
              filterQuality: FilterQuality.high,
              fit: BoxFit.fitWidth,
            ) : Container()
          ),
        );
      }

    if(thumbNail != null)
      return assetItemBuilder();
    else
      return SizedBox.shrink();
    
  }

  Widget assetListBuilder(BuildContext context){
    return Selector<DefaultAssetPickerProvider, Map<AssetPathEntity, Uint8List?>>(
      selector: (_, DefaultAssetPickerProvider p) => p.pathEntityList,
      builder: (_, Map<AssetPathEntity, Uint8List?> pathEntityList, __) {
        return albumMenuBuilder(pathEntityList, gridScrollController, (AssetPathEntity entity){
          provider.currentPathEntity = entity;
          provider.getAssetsFromEntity(0, entity);
          if(pageCubit.state) pageCubit.emit(false);
        });
      }
    );
  }
  
  /// Yes, the build method
  Widget build(BuildContext context){
    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (BuildContext context, _) {
        return Container(
          color: Colors.grey,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 16),
            child: assetListBuilder(context),
          ),
        );
      }, 
    );
  }
}