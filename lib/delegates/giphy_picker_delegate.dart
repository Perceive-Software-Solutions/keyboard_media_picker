import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fort/fort.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:piky/state/state.dart';
class GiphyPickerPickerBuilderDelegate extends ScrollablePerceiveSlidableDelegate {
  GiphyPickerPickerBuilderDelegate(
    this.provider,
    this.giphyPickerController,
    this.header,
    this.loadingIndicator,
    this.connectivityIndicator,
    this.loadingTileIndicator, {
      this.overlayBuilder,
      this.mediumExtent = 0.4,
    }
  ) : super(pageCount: 1, staticScrollModifier: 0.01);

  /// Builds the header
  final Widget Function(BuildContext context, Widget spacer, double borderRadius) header;

  /// Overlay Widget of the selected asset
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  /// Loading Indicator before any Gifs are loaded
  final Widget? loadingIndicator;

  /// When the giphy picker is not connected to the internet
  final Widget? Function(BuildContext, double)? connectivityIndicator;

  /// Individual Gif loading indicator
  final Widget? loadingTileIndicator;

  /// [ChangeNotifier] for giphy picker
  final Tower<GiphyState> provider;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [GiphyPickerPickerBuilderDelegate] accordingly
  final GiphyPickerController? giphyPickerController;

  /// Intial Extent
  final double mediumExtent;

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
  Widget selectedOverlay(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
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
              child: Text('1', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
            )
          )
        )
      ],
    );
  }

  Widget loadingTileIndicatorExample(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
      ),
    );
  }

  Widget connectivityIndicatorExample(){
    return Container(
      child: Center(
        child: Text("Not Connected to the internel"),
      ),
    );
  }

  //Build all containers that hold the gifs
  Widget assetItemBuilder(String url, Map<String, double> currentAssets, int index){

    // Render individual asset
    Widget _displayImage(BuildContext context, String? selectedAsset){
      return Stack(
        children: [
          Positioned.fill(
            child: loadingTileIndicator ?? loadingTileIndicatorExample()
          ),
          Positioned.fill(
            child: Image.network(url,
              fit: BoxFit.cover,
            ),
          ),
          if (selectedAsset == currentAssets.keys.elementAt(index)) overlayBuilder != null ? overlayBuilder!(context, 1) : selectedOverlay(context)
        ],
      );
    }

    return StoreConnector<GiphyState, String?>(
      converter: (store) => store.state.selectedAsset,
      builder: (context, selectedAsset) {
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
                  child: _displayImage(context, selectedAsset)
                ),
              ),
            ),
          ),
          onPressed: (){
            if(selectedAsset == currentAssets.keys.elementAt(index))
              provider.dispatch(unSelectGif());
            else provider.dispatch(selectAsset(currentAssets.keys.elementAt(index)));
            giphyPickerController!.update();
          },
        );
      }
    );
  }

  /// The primary grid view builder for assets
  Widget assetsGridBuilder(BuildContext context, double extent, ScrollController scrollController, bool scrollLock, double footerHeight, Map<String, double> displayAssets){

    //Height of the screen
    var height = MediaQuery.of(context).size.height;

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    List<double> urlRatio = displayAssets.values.toList();

    return StaggeredGridView.countBuilder(
      controller: scrollController,
      physics: scrollLock ? NeverScrollableScrollPhysics() : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      padding: EdgeInsets.only(bottom: footerHeight + MediaQueryData.fromWindow(window).viewInsets.bottom),
      itemCount: displayAssets.length,
      scrollDirection: Axis.vertical,
      crossAxisCount: 2,
      itemBuilder: (context, i){
        return assetItemBuilder(displayAssets.keys.elementAt(i), displayAssets, i);
      },
      staggeredTileBuilder: (int index) => StaggeredTile.extent(1, (width*0.5)/urlRatio[index] - 15),
    );
  }

  @override
  Widget headerBuilder(BuildContext context, pageObj, Widget spacer, double borderRadius) {
    return header(context, spacer, borderRadius);
  }

  @override
  Widget scrollingBodyBuilder(BuildContext context, SheetState? sheetState, ScrollController scrollController, int pageIndex, bool scrollLock, double footerHeight) {
    return StoreConnector<GiphyState, GiphyState>(
      converter: (store) => store.state,
      builder: (context, state){

        final extent = sheetState?.extent ?? 0;

        if(state.displayAssets.length == 0 && !state.connectivity){
          return connectivityIndicator == null ? connectivityIndicatorExample() : connectivityIndicator!(context, extent)!;
        }
        else if(state.displayAssets.length > 0){
          return assetsGridBuilder(context, extent, scrollController, scrollLock, footerHeight, state.displayAssets);
        }
        else{
          return loadingIndicator ?? loadingIndicatorExample(context);
        }
      }
    );
  }
}