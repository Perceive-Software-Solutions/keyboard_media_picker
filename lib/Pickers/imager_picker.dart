import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/delegates/album_picker_delegate.dart';
import 'package:piky/delegates/image_picker_delegate.dart';
import 'package:piky/provider/asset_picker_provider.dart';
import 'package:piky/util/functions.dart';
import 'package:piky/util/keep_alive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:provider/provider.dart';

class ImagePicker extends StatefulWidget {

  /// Main sheet controller
  final SheetController sheetController;

  /// Controllers
  final ImagePickerController? controller;
  final PickerController? pickerController;

  /// Sheet sizing extents
  final double initialExtent;
  final double expandedExtent;
  final double mediumExtent;
  final double minExtent;

  /// Header of the Media Picker at min Extent
  /// Contains a String defining the most recent or current album name
  final Widget Function(String, bool) headerBuilder;

  /// Builds the album menu of the image picker
  /// Contains a list of [AssetEntity] mapped to [Uint8List]'s for thumbnails and information
  final Widget Function(Map<AssetPathEntity, Uint8List?>, ScrollController, dynamic Function(AssetPathEntity)) albumMenuBuilder;

  /// Loading indicator when ImagePickerProvidor is still fetching the images
  /// If not used will have the base [CircularProgressIndicator] as placeholder
  final Widget? loadingIndicator;
  final Widget? tileLoadingIndicator;

  /// Overlay of the selected Asset
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  /// Backdrop Colors
  final Color minBackdropColor;
  final Color maxBackdropColor;

  /// Color of the growable Header
  final Color statusBarPaddingColor;

  /// Background color displayed behind the images and albums
  final Color backgroundColor;

  /// If the sheet is locked open
  final bool isLocked;

  /// Overlay displayed when images or videos are locked
  final Widget Function(BuildContext context, int index)? lockOverlayBuilder;
  
  /// Allows the picker to see the sheetstate
  final Function(SheetState state) listener;

  const ImagePicker({ 
    required Key key,
    required this.controller,
    required this.headerBuilder,
    required this.albumMenuBuilder,
    required this.sheetController,
    required this.listener,
    this.pickerController,
    this.loadingIndicator,
    this.tileLoadingIndicator,
    this.overlayBuilder,
    this.minExtent = 0.0,
    this.initialExtent = 0.4,
    this.mediumExtent = 0.4,
    this.expandedExtent = 1.0,
    this.statusBarPaddingColor = Colors.white,
    this.minBackdropColor = Colors.transparent,
    this.maxBackdropColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.isLocked = false,
    this.lockOverlayBuilder,
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

  // /// The primary controller for the [SlidingSheet]
  // widget.sheetController widget.sheetController = widget.sheetController();

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  ConcreteCubit<bool> sheetCubit = ConcreteCubit<bool>(false);

  /// The primary [Cubit] for the page transition between [AssetPathEntity] and [AssetEntity]
  ConcreteCubit<bool> pageCubit = ConcreteCubit<bool>(false);

  bool albumPage = false;

  /// The [ScrollController] for the image preview grid
  ScrollController imageGridScrollController = ScrollController();

  /// The [ScrollController] for the album preview grid.
  ScrollController albumGridScrollController = ScrollController();

  /// If the sliding sheet is currently snapping
  bool snapping = false;

  /// HeaderBuilder height
  double HEADER_HEIGHT = 60;

  GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  Widget? imageChild;

  Widget? albumChild;

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

    albumDelegate = AlbumPickerBuilderDelegate(
      // provider,
      pageCubit,
      albumGridScrollController,
      widget.albumMenuBuilder,
      widget.controller,
      gridCount: 2
    );

    //Build image delegate
    imageDelegate = ImagePickerBuilderDelegate(
      provider,
      imageGridScrollController,
      widget.controller,
      gridCount: 4,

      loadingIndicator: widget.loadingIndicator,
      overlayBuilder: widget.overlayBuilder,
      lockOverlayBuilder: widget.lockOverlayBuilder
    );

    //Initiate animation
    animationController = AnimationController(
      vsync: this,
      value: widget.minExtent/widget.mediumExtent,
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

  @override
  void dispose(){
    super.dispose();
    provider.removeListener(() { });
    provider.dispose();
  }

  void unSelectAsset(AssetEntity asset){
    provider.unSelectAsset(asset);
    widget.controller?.update();
  }


  void initiateListener(ScrollController scrollController){
    scrollController.addListener(() {
      if(scrollController.offset <= -50 && widget.sheetController.state!.extent != widget.minExtent && !snapping){ 
        if(widget.sheetController.state!.extent == 1.0){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.sheetController.snapToExtent(widget.mediumExtent, duration: Duration(milliseconds: 300));
            sheetCubit.emit(false);
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          });
        }
        else if(widget.sheetController.state!.extent == widget.mediumExtent){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.sheetController.snapToExtent(widget.minExtent, duration: Duration(milliseconds: 300));
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

  /// Add assets through the image picker controller
  void addAssets(List<AssetEntity> assets){
    initialSelect(assets);
  }

  void sheetListener(SheetState state){
    if(state.extent <= widget.mediumExtent && (state.extent - widget.initialExtent) >= 0){
      animationController.animateTo((state.extent - widget.initialExtent) / widget.mediumExtent);
    }
    sheetExtent.emit(state.extent);
    if(state.extent <= widget.initialExtent/3 && widget.isLocked){
      widget.sheetController.snapToExtent(widget.initialExtent);
    }
    widget.listener(state);
  }

  Widget _buildHeader(BuildContext context, bool sheetCubitState, String path){
    //Max Extent
    return GestureDetector(
      onTap: () {
        provider.getAssetPathList();
        pageCubit.emit(!pageCubit.state);
        if(pageCubit.state && widget.sheetController.state!.extent < widget.mediumExtent){
          widget.sheetController.snapToExtent(widget.mediumExtent);
        }
      },
      child: widget.headerBuilder(path, sheetCubitState) 
    );
  }

  @override
  Widget build(BuildContext context) {

    var statusBarHeight = MediaQueryData.fromWindow(window).padding.top;

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
              return AnimatedBuilder(
                animation: colorTween,
                builder: (context, child) {
                  return BlocBuilder<ConcreteCubit<double>, double>(
                    bloc: sheetExtent,
                    builder: (context, extent) {
                      double topExtentValue = Functions.animateOver(extent, percent: 0.9);
                      return SlidingSheet(
                          controller: widget.sheetController,
                          isBackdropInteractable: false,
                          duration: Duration(milliseconds: 300),
                          cornerRadius: 32,
                          cornerRadiusOnFullscreen: 0,
                          backdropColor: extent > widget.initialExtent ? colorTween.value : null,
                          listener: sheetListener,
                          snapSpec: SnapSpec(
                            initialSnap: widget.minExtent,
                            snappings: [widget.minExtent, widget.initialExtent, widget.mediumExtent, widget.expandedExtent],
                          ),
                          headerBuilder: (context, state){
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(height: lerpDouble(0, statusBarHeight, topExtentValue)!, color: widget.statusBarPaddingColor,),
                                Container(
                                  height: HEADER_HEIGHT,
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
                                ),
                              ],
                            );
                          },
                          customBuilder: (context, controller, sheetState){
                            double pageHeight = MediaQuery.of(context).size.height;
                            return BlocBuilder<ConcreteCubit<double>, double>(
                              bloc: sheetExtent,
                              builder: (context, extent) {
                                double height = extent > 0.55 ? (extent == 1.0 ? extent*pageHeight - MediaQuery.of(context).padding.top - 60 : extent > 0.8 ? 
                                extent*pageHeight - MediaQuery.of(context).padding.top : extent*pageHeight - 60) : 
                                pageHeight*0.55 - 60;
                                return BlocBuilder<ConcreteCubit<bool>, bool>(
                                  bloc: pageCubit,
                                  buildWhen: (o, n) => o != n,
                                  builder: (context, state) {
                                    if(albumPage != state && state){
                                      key.currentState!.push(_createRoute((_){    
                                      // if(albumChild == null){
                                      //   albumChild = albumDelegate.build(context, provider);
                                      // }
                                        return Container(
                                          key: Key("2"),
                                          color: widget.backgroundColor,
                                          child: albumDelegate.build(context, provider)
                                        );
                                      }));
                                    }
                                    else if(albumPage != state && !state){
                                      key.currentState!.pop();
                                    }
                                    albumPage = state;
                                    return SingleChildScrollView(
                                      controller: controller,
                                      child: Container(
                                        height: height,
                                        width: MediaQuery.of(context).size.width,
                                        child: Navigator(
                                          key: key,
                                          onGenerateRoute: (route) => _createRoute((_){
                                              if(imageChild == null){
                                                imageChild = imageDelegate.build(context);
                                              }
                                              return Container(
                                                color: widget.backgroundColor,
                                                key: Key("1"), 
                                                height: height,
                                                child: imageChild
                                              );
                                            }
                                          )
                                        ),
                                      )
                                    );
                                  }
                                );
                              }
                            );
                          },
                        );
                    }
                  );
                }
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

  /// Clean individual asset entity
  void clearAssetEntity(AssetEntity asset) => _state != null ? _state!.unSelectAsset(asset) : null;

  /// Clear all selected assets
  void clearAll() => _state != null ? _state!.provider.clearAll() : null;

  /// Add assets to the imageProvider
  void addAssets(List<AssetEntity> assets) => _state != null ? _state!.addAssets(assets) : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
  }
}

class ConcreteCubit<T> extends Cubit<T> {
  ConcreteCubit(T initialState) : super(initialState);
}

Route _createRoute(Widget Function(BuildContext) nextPage) {
  Widget buildContent(BuildContext context) => nextPage(context);
  return PageRouteBuilder(
    maintainState: true,
    pageBuilder: (context, animation, secondaryAnimation) {
      Widget result = buildContent(context);
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
}