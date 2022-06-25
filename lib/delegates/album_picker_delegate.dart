import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/configuration_delegates/image_picker_config_delegate.dart';
import 'package:piky/provider/asset_picker_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';



class AlbumPickerBuilderDelegate extends ScrollablePerceiveSlidableDelegate {
  AlbumPickerBuilderDelegate(
    this.provider,
    this.pageCubit,
    this.delegate,
    this.imagePickerController, {
    this.gridCount = 3,
  }) : super(pageCount: 1, staticScrollModifier: 0.01);


  final ImagePickerConfigDelegate delegate;

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

  Widget assetListBuilder(BuildContext context, DefaultAssetPickerProvider provider, ScrollController scrollController, bool scrollLock, double footerHeight){
    return delegate.albumMenuBuilder(context, provider.currentPathEntity?.name ?? '', provider.pathEntityList, scrollController, scrollLock, footerHeight, (AssetPathEntity entity){
      provider.currentPathEntity = entity;
      if(pageCubit.state){
        pageCubit.emit(false);
        sheetController.pop();
      }
      provider.getAssetsFromEntity(0, entity);
    });
  }

  @override
  Widget headerBuilder(BuildContext context, pageObj, Widget spacer, double borderRadius) {
    throw UnimplementedError();
  }

  @override
  Widget scrollingBodyBuilder(BuildContext context, SheetState? state, ScrollController scrollController, int pageIndex, bool scrollLock, double footerHeight) {
    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (BuildContext context, _) {
        return Selector<DefaultAssetPickerProvider, int>(
          selector: (_, DefaultAssetPickerProvider provider) => provider.pathEntityList.length,
          builder: (_, int length, __) {
            return length != 0 ? assetListBuilder(context, provider, scrollController, scrollLock, footerHeight) : Container();
          }
        );
      }, 
    );
  }
}