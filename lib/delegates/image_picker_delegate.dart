import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/provider/asset_entity_image_provider.dart';
import 'package:piky/provider/asset_picker_provider.dart';
import 'package:piky/widget/builder/asset_entity_grid_item_builder.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';



class ImagePickerBuilderDelegate {
  ImagePickerBuilderDelegate(
    this.provider,
    this.imagePickerController, {
      this.gridCount = 4,
      this.overlayStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      this.backgroundColor = Colors.white
  });

  final TextStyle overlayStyle;

  final Color backgroundColor;

  /// [ChangeNotifier] for asset picker
  final DefaultAssetPickerProvider provider;

  /// The column count inside of the [_sliverGrid]
  final int gridCount;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [ImagePickerBuilderDelegate] accordingly
  final ImagePickerController? imagePickerController;

  /// The [ScrollController] for the preview grid.
  final ScrollController gridScrollController = ScrollController();

  /// The [ScrollController] for the [SingleChildScrollView]
  final ScrollController mainScrollController = ScrollController();

  /// Keep a dispose method to sync with [State].
  ///
  /// Be aware that the method will do nothing when [keepScrollOffset] is true.
  void dispose() {
    gridScrollController.dispose();
    mainScrollController.dispose();
  }

  //Takes an input [Key], and returns the index of the child element with that associated key, or null if not found.
  int findChildIndexBuilder(String id, List<AssetEntity> assets, {int placeholderCount = 0}) {
    int index = assets.indexWhere((AssetEntity e) => e.id == id);
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

  /// Overlays [imageItemBuilder] amd [videoItemBuilder] to display the slected state
  List<Widget> selectedOverlay(BuildContext context, AssetEntity asset){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;
    
    return [
      Positioned.fill(
        child: Opacity(
          opacity: 0.4,
          child: Container(
            height: width / 3,
            width: width / 3,
            color: Colors.black,
          ),
        ),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:BorderRadius.circular(30)),
          child: Center(
            child: Text(
              (provider.selectedAssets.indexOf(asset) + 1).toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        )),
      ))
    ];
  }

  /// Items and placeholders current displayed in the grid
  int assetGridItemCount(List<AssetEntity> assets, {int placeholderCount = 0}){
    return assets.length + placeholderCount;
  }

  /// The item builder for image type of asset
  Widget imageItemBuilder(BuildContext context, AssetEntity asset){

    int defaultGridThumbSize = 200;

    final AssetEntityImageProvider imageProvider = AssetEntityImageProvider(
      asset,
      isOriginal: false,
      thumbSize: <int>[defaultGridThumbSize, defaultGridThumbSize],
    );

    return Selector<DefaultAssetPickerProvider, int>(
      selector: (_, DefaultAssetPickerProvider p) => p.selectedAssets.length,
      builder: (BuildContext context, int selectedCount, Widget? child) {
        return Stack(
          children: [
            Positioned.fill(
              child: AssetEntityGridItemBuilder(
                image: imageProvider,
                failedItemBuilder: failedItemBuilder,
              ),
            ),
          if (provider.selectedAssets.contains(asset)) ...selectedOverlay(context, asset)
        ],
        );
      }
    );
  }

  /// The item builder for video type of asset
  Widget videoItemBuilder(BuildContext context, AssetEntity asset){

    int defaultGridThumbSize = 200;

    final AssetEntityImageProvider imageProvider = AssetEntityImageProvider(
      asset,
      isOriginal: false,
      thumbSize: <int>[defaultGridThumbSize, defaultGridThumbSize],
    );

    return Selector<DefaultAssetPickerProvider, int>(
      selector: (_, DefaultAssetPickerProvider p) => p.selectedAssets.length,
      builder: (BuildContext context, int selectedCount, Widget? child) {
        return Stack(
          children: [
            Positioned.fill(
              child: AssetEntityGridItemBuilder(
                image: imageProvider,
                failedItemBuilder: failedItemBuilder,
              ),
            ),
            Opacity(
              opacity: 0.4,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: Container(
                    height: 16,
                    width: 32,
                    decoration:
                        BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                    ),
                    child: Center(
                        child: Text(
                          asset.videoDuration.toString().split('.')[0].substring(3),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12
                        ),
                      )
                    ),
                  ),
                ),
              ),
            ),
          if (provider.selectedAssets.contains(asset)) ...selectedOverlay(context, asset)
        ],
        );
      }
    );
  }

  /// Returns an Image or video widget depending on the duration of the [AssetEntity]
  /// 
  /// Load more assets when the index reached at third line counting backwards
  Widget assetItemBuilder(BuildContext context, DefaultAssetPickerProvider provider, int index, List<AssetEntity> currentAssets){
    
    // length of the currently loaded assets
    int _length = currentAssets.length;

    // If the asset is a video 
    bool isVideo = currentAssets[index].videoDuration.inMilliseconds > 0;

    Widget child = isVideo ? 
      videoItemBuilder(context, currentAssets[index]) : 
      imageItemBuilder(context, currentAssets[index]);

    // load more assets when a offset of 6 is reached and has more to load
    if (index == _length - gridCount * 3 && provider.hasMoreToLoad) {
      provider.loadMoreAssets();
    }

    return AnimationConfiguration.staggeredGrid(
      columnCount: (index / gridCount).floor(),
      position: index,
      duration: const Duration(milliseconds: 375),
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: GestureDetector(
            child: child,
            onTap:(){
              if(provider.selectedAssets.isNotEmpty){
                if(provider.selectedAssets[0].videoDuration.inMilliseconds > 0){
                  provider.unSelectAsset(provider.selectedAssets[0]);
                }
              }
              if(provider.selectedAssets.contains(currentAssets[index]))
                provider.unSelectAsset(currentAssets[index]);
              else if(currentAssets[index].videoDuration.inMilliseconds > 0){
                provider.selectedAssets.clear();
                provider.selectAsset(currentAssets[index]);
              }
              else provider.selectAsset(currentAssets[index]);

              imagePickerController!.update();
            }
          )
        ),
      )
    );
  }

  /// The main grid view builder for assets
  Widget assetsGridBuilder(BuildContext context){

    return Selector<DefaultAssetPickerProvider, AssetPathEntity?>(
      selector: (_, DefaultAssetPickerProvider p) => p.currentPathEntity,
      builder: (_, AssetPathEntity? path, __) {

        // First, we need the count of the assets.
        int totalCount = path?.assetCount ?? 0;

        // Then we use the [totalCount] to calculate how many placeholders we need.
        int placeholderCount = 0;
        if (totalCount % gridCount != 0) {
          // When there are left items that not filled into one row, filled the row
          // with placeholders.
          placeholderCount = gridCount - totalCount % gridCount;
        } else {
          // Otherwise, we don't need placeholders.
          placeholderCount = 0;
        }

        Widget _sliverGrid(BuildContext c, List<AssetEntity> assets){
          return SliverGrid(
            delegate: SliverChildBuilderDelegate((_, int index) => Builder(
              builder: (BuildContext c){
                if (index >= assets.length) {
                  return const SizedBox.shrink();
                }
                return assetItemBuilder(context, provider, index, assets);
                },
              ),
              childCount: assetGridItemCount(
                assets,
                placeholderCount: placeholderCount
              ),
              findChildIndexCallback: (Key key) {
                if (key is ValueKey<String>) {
                  return findChildIndexBuilder(
                    key.value,
                    assets,
                    placeholderCount: placeholderCount,
                  );
                }
                return null;
              },
            ), 
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1
            )
          );
        }

        return Selector<DefaultAssetPickerProvider, List<AssetEntity>>(
          selector: (_, DefaultAssetPickerProvider provider) => provider.currentAssets,
          builder: (_, List<AssetEntity> assets, __) {
            return AnimationLimiter(
              child: BlocBuilder<ConcreteCubit<bool>, bool>(
                builder: (context, state) {
                  return CustomScrollView(
                    scrollDirection: Axis.vertical,
                    physics: AlwaysScrollableScrollPhysics(),
                    controller: gridScrollController,
                    slivers: [
                      _sliverGrid(_, assets)
                    ],
                  );
                }
              ),
            );
          }
        );
      }
    );
  } 
  
  /// Yes, the build method
  Widget build(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    //height of the screen
    var height = MediaQuery.of(context).size.height;
    
    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (BuildContext context, _){
        return Selector<DefaultAssetPickerProvider, bool>(
        selector: (_, DefaultAssetPickerProvider provider) => provider.hasAssetsToDisplay,
        builder: (_, bool hasAssetsToDisplay, __) {
          return SingleChildScrollView(
            controller: mainScrollController,
            child: Container(
              color: backgroundColor,
              height: height,
              width: width,
              child: hasAssetsToDisplay ? assetsGridBuilder(context) : loadingIndicator(context),
              ),
            );
          }
        );
      }, 
    );
  }
}