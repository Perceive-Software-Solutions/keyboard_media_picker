import 'dart:typed_data';

import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/delegates/album_picker_delegate.dart';
import 'package:piky/delegates/image_picker_delegate.dart';
import 'package:piky/provider/asset_picker_provider.dart';
import 'package:piky/util/keep_alive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:provider/provider.dart';

class ImagePicker extends StatefulWidget {
  /// Controllers
  final ImagePickerController? controller;
  final PickerController? pickerController;

  /// Sheet sizing extents
  final double initialExtent;
  final double expandedExtent;
  final double mediumExtent;
  final double minExtent;

  /// Header Height
  /// Must pass the height of the header widget to avoid overflow
  final double headerHeight;

  /// Header of the Media Picker at min Extent
  /// Contains a String defining the most recent or current album name
  final Widget Function(String, bool) headerBuilder;

  /// Builds the album menu of the image picker
  /// Contains a list of [AssetEntity] mapped to [Uint8List]'s for thumbnails and information
  final Widget Function(Map<AssetPathEntity, Uint8List?>, ScrollController, dynamic Function(AssetPathEntity)) albumMenuBuilder;

  /// Loading indicator when ImagePickerProvidor is still fetching the images
  /// If not used will have the base [CircularProgressIndicator] as placeholder
  final Widget? loadingIndicator;

  /// Overlay of the selected Asset
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  /// Backdrop Colors
  final Color minBackdropColor;
  final Color maxBackdropColor;

  const ImagePicker({ 
    required Key key,
    required this.controller,
    required this.headerBuilder,
    required this.albumMenuBuilder,
    this.pickerController,
    this.loadingIndicator,
    this.overlayBuilder,
    this.minExtent = 0.0,
    this.initialExtent = 0.4,
    this.mediumExtent = 0.4,
    this.expandedExtent = 1.0,
    this.headerHeight = 50,
    this.minBackdropColor = Colors.transparent,
    this.maxBackdropColor = Colors.black
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

  /// Primary delegate for displaying assets
  late ImagePickerBuilderDelegate imageDelegate;

  /// Primary delegate for displaying thumbnails
  late AlbumPickerBuilderDelegate albumDelegate;

  /// Controls the animation of the backdrop color reletive the the [SlidingSheet]
  late AnimationController animationController;

  /// Animates the color from min extent to medium extent
  late Animation<Color?> colorTween;

  /// Initial extent
  late ConcreteCubit<double> sheetExtent = ConcreteCubit<double>(widget.initialExtent);

  /// The state of the [ImagePicker]
  Option type = Option.Open;

  /// The current selected assets
  List<AssetEntity> selectedAssets = <AssetEntity>[];

  /// The primary controller for the [SlidingSheet]
  SheetController sheetController = SheetController();

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  ConcreteCubit<bool> sheetCubit = ConcreteCubit<bool>(false);

  /// The primary [Cubit] for the page transition between [AssetPathEntity] and [AssetEntity]
  ConcreteCubit<bool> pageCubit = ConcreteCubit<bool>(false);

  /// The [ScrollController] for the image preview grid
  ScrollController imageGridScrollController = ScrollController();

  /// The [ScrollController] for the album preview grid.
  ScrollController albumGridScrollController = ScrollController();

  /// If the sliding sheet is currently snapping
  bool snapping = false;

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
      RequestType.all,
      filterOptions: filer
    );

    //Build image delegate
    imageDelegate = ImagePickerBuilderDelegate(
      provider,
      imageGridScrollController,
      widget.controller,
      gridCount: 4,
      loadingIndicator: widget.loadingIndicator,
      overlayBuilder: widget.overlayBuilder
    );

    //Build album delegate
    albumDelegate = AlbumPickerBuilderDelegate(
      provider,
      pageCubit,
      albumGridScrollController,

      widget.albumMenuBuilder,
      widget.controller,
      gridCount: 2
    );

    //Initiate animation
    animationController = AnimationController(
      vsync: this,
      value: widget.initialExtent/widget.mediumExtent,
      duration: Duration(milliseconds: 0)
    );
    colorTween = ColorTween(begin: widget.minBackdropColor, end: widget.maxBackdropColor).animate(animationController);

    // Add already selected images
    initialSelect(widget.controller!.selectedAssets);
    
    // Constantly edit the state with selected assets
    addSelectedAssetstoState();

    // Initiate listeners on scroll controllers
    initiateListener(imageGridScrollController);
    initiateListener(albumGridScrollController);
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller!._bind(this);
    }
  }

  void initiateListener(ScrollController scrollController){
    scrollController.addListener(() {
      if(scrollController.offset <= -50 && sheetController.state!.extent != widget.minExtent && !snapping){
        if(sheetController.state!.extent == 1.0){
          snapping = true;
          Future.delayed(Duration.zero, () {
            sheetController.snapToExtent(widget.mediumExtent, duration: Duration(milliseconds: 300));
            sheetCubit.emit(false);
            if(pageCubit.state){
              pageCubit.emit(!pageCubit.state);
            }
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          });
        }
        else if(sheetController.state!.extent == widget.mediumExtent){
          snapping = true;
          Future.delayed(Duration.zero, () {
            sheetController.snapToExtent(widget.minExtent, duration: Duration(milliseconds: 300));
          });
          Future.delayed(Duration(milliseconds: 300)).then((value) => {
            snapping = false
          });
        }
      }
    });
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

  void sheetListener(SheetState state){
    if(state.extent <= widget.mediumExtent && (state.extent - widget.minExtent) >= 0){
      animationController.animateTo((state.extent - widget.minExtent) / widget.mediumExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    Widget _buildHeader(BuildContext context, bool sheetCubitState, String path){
      //Max Extent
      return GestureDetector(
        onTap: () {
          provider.getAssetPathList();
          pageCubit.emit(!pageCubit.state);
          sheetCubit.emit(true);
          sheetController.expand();
        },
        child: widget.headerBuilder(path, sheetCubitState) 
      );
    }

    return KeepAliveWidget(
      key: Key('ImagePicker'),
      child: BlocProvider(
        create: (context) => pageCubit,
        child: BlocProvider(
          create: (context) => sheetCubit,
          child: BlocBuilder<ConcreteCubit<bool>, bool>(
            bloc: sheetCubit,
            buildWhen: (o, n) => o != n,
            builder: (context, sheetCubitState) {
              return ColorfulSafeArea(
                top: sheetCubitState,
                color: widget.maxBackdropColor,
                child: AnimatedBuilder(
                  animation: colorTween,
                  builder: (context, child) {
                    return BlocBuilder<ConcreteCubit<double>, double>(
                      bloc: sheetExtent,
                      builder: (context, extent) {
                        return SlidingSheet(
                            controller: sheetController,
                            isBackdropInteractable: extent > widget.minExtent ? false : true,
                            duration: Duration(milliseconds: 300),
                            cornerRadius: 32,
                            cornerRadiusOnFullscreen: 0,
                            backdropColor: colorTween.value,
                            listener: sheetListener,
                            snapSpec: SnapSpec(
                              initialSnap: widget.initialExtent,
                              snappings: [widget.minExtent, widget.mediumExtent, widget.expandedExtent],
                              onSnap: (state, _){
                                if(state.isCollapsed && widget.minExtent == 0){
                                  widget.pickerController!.closeImagePicker();
                                }
                                if(state.extent == widget.mediumExtent){
                                  if(sheetCubit.state) sheetCubit.emit(false);
                                  if(pageCubit.state) pageCubit.emit(false);
                                }
                                else if(state.isExpanded && !pageCubit.state){
                                  if(!sheetCubit.state) sheetCubit.emit(true);
                                }
                              },
                            ),
                            headerBuilder: (context, state){
                              return Container(
                                height: widget.headerHeight,
                                color: Colors.white,
                                child: ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
                                  value: provider,
                                  builder: (context, snapshot) {
                                    return Selector<DefaultAssetPickerProvider, AssetPathEntity?>(
                                      selector: (_, DefaultAssetPickerProvider p) => p.currentPathEntity,
                                      builder: (BuildContext context, AssetPathEntity? _path, Widget? child) {
                                        return AnimatedSwitcher(
                                          duration: Duration(milliseconds: 400),
                                          transitionBuilder: (child, animation){
                                            return FadeTransition(
                                              opacity: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOut,
                                              ),
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, -1.5),
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeInOutQuart,
                                                )),
                                                child: child
                                              ),
                                            );
                                          },
                                          child: _buildHeader(context, sheetCubitState, _path?.name ?? "Recents")
                                        );
                                      }
                                    );
                                  }
                                )
                              );
                            },
                            customBuilder: (context, controller, sheetState){
                              double SAFE_AREA_PADDING = sheetCubitState ? MediaQuery.of(context).padding.top : 0.0;
                              double height = sheetCubitState ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height*widget.mediumExtent;
                              return BlocBuilder<ConcreteCubit<bool>, bool>(
                                bloc: pageCubit,
                                buildWhen: (o, n) => o != n,
                                builder: (context, state) {
                                  return SingleChildScrollView(
                                    controller: controller,
                                    child: !state ? Container(
                                      key: Key("1"), 
                                      height: height-widget.headerHeight-SAFE_AREA_PADDING,
                                      child: imageDelegate.build(context)
                                    ) : Container(
                                      key: Key("2"), 
                                      height: MediaQuery.of(context).size.height-widget.headerHeight-SAFE_AREA_PADDING,
                                      child: albumDelegate.build(context)
                                    ),
                                  );
                                }
                              );
                            },
                          );
                      }
                    );
                  }
                ),
              );
            }
          ),
        ),
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
  Option? get type => _state != null ? type : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
  }
}

class ConcreteCubit<T> extends Cubit<T> {
  ConcreteCubit(T initialState) : super(initialState);
}