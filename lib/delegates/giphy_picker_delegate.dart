import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/provider/giphy_picker_provider.dart';
import 'package:provider/provider.dart';

class GiphyPickerPickerBuilderDelegate {
  GiphyPickerPickerBuilderDelegate(
    this.provider,
    this.gridScrollController,
    this.giphyPickerController,
    this.sheetCubit,
    this.loadingIndicator,
    this.loadingTileIndicator, {
      this.initialExtent = 0.4,
      this.overlayStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    }
  );

  /// Overlay TextStyle
  final TextStyle overlayStyle;

  /// Loading Indicator before any Gifs are loaded
  final Widget? Function(BuildContext, bool)? loadingIndicator;

  /// Individual Gif loading indicator
  final Widget? loadingTileIndicator;

  /// [ChangeNotifier] for giphy picker
  final GiphyPickerProvider provider;

  /// The [ScrollController] for the preview grid.
  final ScrollController gridScrollController;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [GiphyPickerPickerBuilderDelegate] accordingly
  final GiphyPickerController? giphyPickerController;

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  final ConcreteCubit<bool> sheetCubit;

  /// Intial Extent
  final double initialExtent;

  /// Primary [TextEditingController] to get the current value of the [TextField]
  TextEditingController searchFieldController = TextEditingController();

  ScrollController loading = ScrollController();

  /// Loading indicator
  Widget loadingIndicatorExample(BuildContext context){
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

  /// Overlays [imageItemBuilder] amd [videoItemBuilder] to display the slected state
  List<Widget> selectedOverlay(BuildContext context){

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
            child: Text('1', style: overlayStyle)
          ),
        )
      )
    ];
  }

  Widget loadingTileIndicatorExample(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(12)
      ),
    );
  }

  //Build all containers that hold the gifs
  Widget assetItemBuilder(String url, Map<String, double> currentAssets, int index){

    // Render individual asset
    Widget _displayImage(){
      return  Selector<GiphyPickerProvider, String?>(
      selector: (_, GiphyPickerProvider p) => p.selectedAsset,
      builder: (BuildContext context, String? selectedAsset, Widget? child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(url,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                  if(loadingProgress == null) return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: child
                  );
                  return loadingTileIndicator ?? loadingTileIndicatorExample();
                }),
              ),
              if (selectedAsset == currentAssets.keys.elementAt(index)) ...selectedOverlay(context)
            ],
          );
        }
      );
    }

    return FlatButton(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 300,
          minHeight: 125, 
        ),
        child: AnimationConfiguration.staggeredGrid(
          columnCount: (index / 2).floor(),
          position: index,
          duration: const Duration(milliseconds: 375),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _displayImage()
            ),
          ),
        ),
      ),
      onPressed: (){
        if(provider.selectedAsset == currentAssets.keys.elementAt(index))
          provider.unSelectAsset();
        else provider.selectAsset(currentAssets.keys.elementAt(index));

        giphyPickerController!.update();
      },
    );
  }

  /// The primary grid view builder for assets
  Widget assetsGridBuilder(BuildContext context, bool sheetCubitState){

    //Height of the screen
    var height = MediaQuery.of(context).size.height;

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    return Selector<GiphyPickerProvider, int>(
      selector: (_, GiphyPickerProvider provider) => provider.displayAssets.length,
      builder: (_, int length, __) {
      return Selector<GiphyPickerProvider, Map<String, double>>(
        selector: (_, GiphyPickerProvider provider) => provider.displayAssets,
        builder: (_, Map<String, double> assets, __) {
          List<double> urlRatio = assets.values.toList();
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: !sheetCubitState ? height*initialExtent - 60 : height - 65 - MediaQuery.of(context).padding.top,
                child: StaggeredGridView.countBuilder(
                  controller: gridScrollController,
                  shrinkWrap: true,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  padding: EdgeInsets.only(left: 5, right: 5, bottom: 5),
                  itemCount: provider.totalAssetsCount,
                  scrollDirection: !sheetCubitState ? Axis.horizontal : Axis.vertical,
                  crossAxisCount: 2,
                  itemBuilder: (context, i){
                    return assetItemBuilder(assets.keys.elementAt(i), assets, i);
                  },
                  staggeredTileBuilder: (int index) => StaggeredTile.extent(1, !sheetCubitState ? 
                  (height*0.165)*urlRatio[index] - 15 : (width*0.5)/urlRatio[index] - 15),
                ),
              ),
            ],
          );
        }
      );
    }
  );
  }

  /// Yes, the build method
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      builder: (BuildContext context, _) {
        return Selector<GiphyPickerProvider, bool>(
          selector: (_, GiphyPickerProvider provider) => provider.hasAssetsToDisplay,
          builder: (_, bool hasAssetsToDisplay, __) {
            return BlocBuilder<ConcreteCubit<bool>, bool>(
              bloc: sheetCubit,
              builder: (BuildContext context, bool sheetCubitState) {
                return hasAssetsToDisplay ? assetsGridBuilder(context, sheetCubitState) : loadingIndicator!(context, sheetCubitState) ?? loadingIndicatorExample(context);
              }
            );
          }
        );
      }
    );
  }
}