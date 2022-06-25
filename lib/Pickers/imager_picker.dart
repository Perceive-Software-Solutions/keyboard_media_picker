import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/configuration_delegates/image_picker_config_delegate.dart';
import 'package:piky/delegates/album_picker_delegate.dart';
import 'package:piky/delegates/image_picker_delegate.dart';
import 'package:piky/provider/asset_picker_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class ImagePicker extends StatefulWidget {

  /// Main sheet controller
  final PerceiveSlidableController sheetController;

  /// Controllers
  final ImagePickerController? controller;

  /// Sheet sizing extents
  final double initialExtent;
  final double expandedExtent;
  final double mediumExtent;
  final double minExtent;

  /// Delegate
  final ImagePickerConfigDelegate delegate;
  
  /// Allows the picker to see the sheetstate
  final Function(double extent) listener;

  /// If the image picker is in a locked state
  final ConcreteCubit<PickerType?>? openType;

  const ImagePicker({ 
    required Key key,
    required this.delegate,
    required this.controller,
    required this.sheetController,
    required this.listener,
    this.openType,
    this.minExtent = 0.0,
    this.initialExtent = 0.4,
    this.mediumExtent = 0.4,
    this.expandedExtent = 1.0, 
  }) : super(key: key);

  @override
  _ImagePickerState createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> with SingleTickerProviderStateMixin {

/*
 
     ____  _        _       
    / ___|| |_ __ _| |_ ___ 
    \___ \| __/ _` | __/ _ \
     ___) | || (_| | ||  __/
    |____/ \__\__,_|\__\___|
                            
 
*/

  /// Primary provider for loading assets
  late DefaultAssetPickerProvider provider;

  /// Primary delegate for displaying thumbnails
  late AlbumPickerBuilderDelegate albumDelegate;

  /// The current selected assets
  List<AssetEntity> selectedAssets = <AssetEntity>[];

  /// The primary [Cubit] for the page transition between [AssetPathEntity] and [AssetEntity]
  ConcreteCubit<bool> pageCubit = ConcreteCubit<bool>(false);

  @override
  void initState() {
    super.initState();

    /// Order images inside albums
    OrderOption order = OrderOption(asc: false, type: OrderOptionType.createDate);

    /// Filter option
    FilterOptionGroup filer = FilterOptionGroup(orders: [order]);

    //Initiate provider
    provider = DefaultAssetPickerProvider(
      maxAssets: widget.controller!.imageCount, 
      pageSize: 120,
      pathThumbSize: 80,
      requestType: 
      widget.controller!.onlyPhotos ? 
      RequestType.image : 
      RequestType.common,
      filterOptions: filer
    );

    // Add already selected images
    initialSelect(widget.controller!.selectedAssets);
    
    // Constantly edit the state with selected assets
    addSelectedAssetstoState();

  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller!._bind(this);
    }
  }

  @override
  void dispose(){
    super.dispose();
    provider.removeListener(() { });
    provider.dispose();
  }

  void _updateMaxAssets(int assetCount){
    print("ASSET COUNT UPDATING");
    print(assetCount);
    if(assetCount >= 0){
      provider.maximumAssets = assetCount;
    }
  }

  void unSelectAsset(AssetEntity asset){
    provider.unSelectAsset(asset);
    widget.controller?.update();
  }

  /// Adds the current selected assets to [ImagePicker] dynamically
  void addSelectedAssetstoState(){
    if(mounted){
      provider.addListener(() { 
        setState(() {
          selectedAssets = provider.selectedAssets;
        });
      });
    }
  }

  /// Initially selects assets if they have been previously selected
  void initialSelect(List<AssetEntity> assets){
    for(AssetEntity asset in widget.controller!.selectedAssets){
        provider.selectAsset(asset);
    }
  }

  /// Add assets through the image picker controller
  void addAssets(List<AssetEntity> assets){
    initialSelect(assets);
  }

  void sheetListener(double extent){
    if(extent <= widget.initialExtent/3 && widget.openType?.state == PickerType.ImagePicker){
      if(extent == 0){
        Future.delayed(Duration(milliseconds: 100)).then((value){
          widget.sheetController.snapTo(widget.initialExtent);
        });
      }
      else{
        widget.sheetController.snapTo(widget.initialExtent);
      }
    }
    widget.listener(extent);
  }

  Widget _buildHeader(BuildContext context, Widget spacer, double borderRadius){

    return BlocBuilder<ConcreteCubit<bool>, bool>(
      bloc: pageCubit,
      buildWhen: (o, n) => o != n,
      builder: (context, pageCubitState) {
        return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
          value: provider,
          builder: (context, snapshot) {
            return Selector<DefaultAssetPickerProvider, AssetPathEntity?>(
              selector: (_, DefaultAssetPickerProvider p) => p.currentPathEntity,
              builder: (BuildContext context, AssetPathEntity? _path, Widget? child) {
                return GestureDetector(
                  onTap: () {
                    if(!pageCubit.state){
                      widget.sheetController.push(AlbumPickerBuilderDelegate(
                        provider,
                        pageCubit,
                        widget.delegate,
                        widget.controller,
                        gridCount: 2
                      ), _buildRoute(widget.delegate.backgroundColor));
                    }
                    else{
                      widget.sheetController.pop();
                    }

                    provider.getAssetPathList();
                    pageCubit.emit(!pageCubit.state);
                    if(pageCubit.state && widget.sheetController.extent < widget.mediumExtent){
                      widget.sheetController.snapTo(widget.mediumExtent);
                    }
                  },
                  child: widget.delegate.headerBuilder(context, spacer, _path?.name ?? "Recents", pageCubitState, borderRadius) 
                );
              }
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {

    
    return PerceiveSlidable(
      controller: widget.sheetController,
      staticSheet: true,
      closeOnBackdropTap: false,
      isBackgroundIntractable: false,
      doesPop: false,
      additionalSnappings: [widget.initialExtent],
      initialExtent: 0,
      backgroundColor: widget.delegate.backgroundColor,
      minExtent: widget.minExtent,
      mediumExtent: widget.mediumExtent,
      expandedExtent: widget.expandedExtent,
      extentListener: sheetListener,
      persistentHeader: _buildHeader,
      delegate: ImagePickerBuilderDelegate(
        provider,
        widget.delegate,
        widget.controller,
        gridCount: 4,
      ),
    );

  }
}

class ImagePickerController extends ChangeNotifier {
  _ImagePickerState? _state;

  /// The previously selected [AssetEntity]
  final List<AssetEntity> selectedAssets;
  /// Set the max [DurationConstraint] of videos that can be selected
  final DurationConstraint duration;
  /// Set the max amount of images that can be selected
  /// 
  /// The max amount of videos can not be included becuase it is internal
  final int imageCount;
  /// Filter for what should be included for the [DefaultAssetPickerProvider]
  final bool onlyPhotos;

  ImagePickerController({
    required this.selectedAssets, 
    required this.duration, 
    required this.imageCount, 
    required this.onlyPhotos
  });

  /// Bind to state
  void _bind(_ImagePickerState bind) => _state = bind;

  /// Notify listeners
  void update() => _state != null ? notifyListeners() : null;

  /// Get the [list] of previously selected assets
  List<AssetEntity>? get list => _state != null ? _state!.provider.selectedAssets : null;

  /// Get the current state of the [ImagePicker]
  PikyOption? get type => _state != null ? type : null;

  /// Clean individual asset entity
  void clearAssetEntity(AssetEntity asset) => _state != null ? _state!.unSelectAsset(asset) : null;

  /// Clear all selected assets
  void clearAll() => _state != null ? _state!.provider.clearAll() : null;

  /// Add assets to the imageProvider
  void addAssets(List<AssetEntity> assets) => _state != null ? _state!.addAssets(assets) : null;

  /// Max Asset Counts
  void updateAssetCount(int assetCount) => _state != null ? _state!._updateMaxAssets(assetCount) : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
  }
}

class ConcreteCubit<T> extends Cubit<T> {
  ConcreteCubit(T initialState) : super(initialState);
}

_buildRoute(Color backgroundColor){
  return (Widget nextPage) {
    return PageRouteBuilder(
      maintainState: true,
      barrierColor: backgroundColor,
      pageBuilder: (context, animation, secondaryAnimation) {
        Widget result = nextPage;
        assert(() {
          if (result == null) {
            throw FlutterError(
              'Route builders must never return null.',
            );
          }
          return true;
        }());
        return Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          child: result,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  };
}