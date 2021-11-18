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
    this.giphyPickerController,
    this.sheetCubit,
    this.valueCubit, {
      this.initialExtent = 0.4,
      this.overlayStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      this.backgroundColor = Colors.white
    }
  );

  final TextStyle overlayStyle;

  final Color backgroundColor;

  /// [ChangeNotifier] for giphy picker
  final GiphyPickerProvider provider;

  /// Controls the changes in state relative to the [SlidingSheet]
  /// 
  /// If the state is changed the imagePicker can change certain
  /// params inside of the [GiphyPickerPickerBuilderDelegate] accordingly
  final GiphyPickerController? giphyPickerController;

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  final ConcreteCubit<bool> sheetCubit;

  /// The primary [Cubit] to listen to the value of the [TextField]
  final ConcreteCubit<String> valueCubit;

  final double initialExtent;

  /// Primary [ScrollController] for the grid view
  ScrollController gridController = ScrollController();

  /// Primary [TextEditingController] to get the current value of the [TextField]
  TextEditingController searchFieldController = TextEditingController();

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

  //Build all containers that hold the gifs
  Widget assetItemBuilder(String url, String value, Map<String, double> currentAssets, int index){

    // length of the currently loaded assets
    int _length = currentAssets.length;

     // load more assets when a offset of 6 is reached and has more to load
    if (index == _length - 6) {
      if(value == '')
        provider.loadMoreAssetsFromTrending(currentAssets.length + 1);
      else 
        provider.loadMoreAssetsFromSearching(currentAssets.length + 1, value);
    }

    // Render individual asset
    Widget _displayImage(){
      return  Selector<GiphyPickerProvider, String?>(
      selector: (_, GiphyPickerProvider p) => p.selectedAsset,
      builder: (BuildContext context, String? selectedAsset, Widget? child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(url),
                      fit: BoxFit.cover
                    ),
                  ),
                ),
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

    return BlocBuilder<ConcreteCubit<String>, String>(
      bloc: valueCubit,
      builder: (BuildContext context, String value) {
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
                      height: !sheetCubitState ? height*0.4 - 60 : height,
                      child: StaggeredGridView.countBuilder(
                        shrinkWrap: true,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                        padding: EdgeInsets.only(left: 5, right: 5, bottom: 5),
                        itemCount: provider.totalAssetsCount,
                        scrollDirection: !sheetCubitState ? Axis.horizontal : Axis.vertical,
                        crossAxisCount: 2,
                        itemBuilder: (context, i){
                          return assetItemBuilder(assets.keys.elementAt(i), value, assets, i);
                        },
                        staggeredTileBuilder: (int index) => StaggeredTile.extent(1, !sheetCubitState ? (height*0.165)*urlRatio[index] - 15 : (width*0.5)/urlRatio[index] - 15),
                      ),
                    ),
                  ],
                );
              }
            );
          }
        );
      }
    );
  }

  /// Yes, the build method
  Widget build(BuildContext context) {

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    //height of the screen
    var height = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider.value(
      value: provider,
      builder: (BuildContext context, _) {
        return Selector<GiphyPickerProvider, bool>(
          selector: (_, GiphyPickerProvider provider) => provider.hasAssetsToDisplay,
          builder: (_, bool hasAssetsToDisplay, __) {
            return BlocBuilder<ConcreteCubit<bool>, bool>(
              bloc: sheetCubit,
              builder: (BuildContext context, bool sheetCubitState) {
                return SingleChildScrollView(
                  controller: gridController,
                  child: Container(
                    height: height,
                    width: width,
                    color: backgroundColor,
                    child: hasAssetsToDisplay ? assetsGridBuilder(context, sheetCubitState) : loadingIndicator(context)
                  ),
                );
              }
            );
          }
        );
      }
    );
  }
}