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
  final ImagePickerController? controller;
  final PickerController pickerController;
  final double initialExtent;
  final double expandedExtent;
  final TextStyle menuStyle;
  final TextStyle albumNameStyle;
  final Color backgroundColor;
  final Icon menuIcon;

  const ImagePicker({ 
    required Key key,
    required this.controller,
    required this.pickerController,
    this.initialExtent = 0.4,
    this.expandedExtent = 1.0,
    this.menuStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    this.albumNameStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    this.backgroundColor = Colors.white,
    this.menuIcon = const Icon(Icons.download)
  }) : super(key: key);

  @override
  _ImagePickerState createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> {

/*
 
      ____                _   
     / ___|___  _ __  ___| |_ 
    | |   / _ \| '_ \/ __| __|
    | |__| (_) | | | \__ \ |_ 
     \____\___/|_| |_|___/\__|
                              
 
*/

static const double HEADER_HEIGHT = 47.0;

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
    );

    //Build album delegate
    albumDelegate = AlbumPickerBuilderDelegate(
      provider,
      pageCubit,
      albumGridScrollController,
      widget.controller,
      gridCount: 2
    );

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
      if(scrollController.offset <= -80 && !snapping){
        if(sheetController.state!.extent == 1.0){
          snapping = true;
          Future.delayed(Duration.zero, () {
            sheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300));
            sheetCubit.emit(false);
            if(pageCubit.state){
              pageCubit.emit(!pageCubit.state);
            }
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          });
        }
        else if(sheetController.state!.extent == 0.55){
          snapping = true;
          Future.delayed(Duration.zero, () {
            sheetController.snapToExtent(0.0, duration: Duration(milliseconds: 300));
            widget.pickerController.closeImagePicker();
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
    provider.addListener(() { 
      setState(() {
        selectedAssets = provider.selectedAssets;
      });
    });
  }

  /// Initially selects assets if they have been previously selected
  void initialSelect(List<AssetEntity> assets){
    for(AssetEntity asset in widget.controller!.selectedAssets){
        provider.selectAsset(asset);
    }
  }

  @override
  Widget build(BuildContext context) {

    return KeepAliveWidget(
      key: Key('ImagePicker'),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: BlocProvider(
          create: (context) => pageCubit,
          child: BlocProvider(
            create: (context) => sheetCubit,
            child: SlidingSheet(
                controller: sheetController,
                isBackdropInteractable: true,
                duration: Duration(milliseconds: 300),
                snapSpec: SnapSpec(
                  initialSnap: widget.initialExtent,
                  snappings: [0.0, widget.initialExtent, widget.expandedExtent],
                  onSnap: (state, _){
                    if(state.isCollapsed){
                      widget.pickerController.closeImagePicker();
                    }
                    if(state.extent == 0.55){
                      if(sheetCubit.state) sheetCubit.emit(false);
                      if(pageCubit.state) pageCubit.emit(false);
                    }
                    else if(state.isExpanded && !pageCubit.state){
                      if(!sheetCubit.state) sheetCubit.emit(true);
                    }
                  },
                ),
                headerBuilder: (context, _){
                  return BlocBuilder<ConcreteCubit<bool>, bool>(
                    bloc: sheetCubit,
                    buildWhen: (o, n) => o != n,
                    builder: (context, sheetCubitState) {
                      return Container(
                        height: HEADER_HEIGHT,
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
                                    // return FadeTransition(opacity: animation, child: child,);
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
                    }
                  );
                },
                customBuilder: (context, controller, sheetState){
                  double SAFE_AREA_PADDING = sheetState.isExpanded ? MediaQuery.of(context).padding.top : 0.0;
                  double height = sheetState.extent < widget.initialExtent ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height*sheetState.extent;
                  return BlocBuilder<ConcreteCubit<bool>, bool>(
                    bloc: pageCubit,
                    buildWhen: (o, n) => o != n,
                    builder: (context, state) {
                      return SingleChildScrollView(
                        controller: controller,
                        child: !state ? Container(
                          key: Key("1"), 
                          height: height-HEADER_HEIGHT-SAFE_AREA_PADDING,
                          child: imageDelegate.build(context)
                        ) : Container(
                          key: Key("2"), 
                          height: MediaQuery.of(context).size.height-HEADER_HEIGHT-SAFE_AREA_PADDING,
                          child: albumDelegate.build(context)
                        ),
                      );
                    }
                  );
                },
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, 
    bool sheetCubitState, 
    String path){
    
    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    if(sheetCubitState){
      //Max Extent
      return Container(
        key: Key("Picker-Max-View"),
        height: HEADER_HEIGHT,
        color: widget.backgroundColor,
        child: GestureDetector(
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(pageCubit.state ? 'All Photos' : path, style: widget.menuStyle),
            widget.menuIcon
          ],
        ),
        onTap: () {
          provider.getAssetPathList();
          pageCubit.emit(!pageCubit.state);
        }),
      );
    }
    else{
      //Min Extent
      return Container(
        height: HEADER_HEIGHT,
        width: width,
        color: widget.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(path, style: widget.albumNameStyle),
              Spacer(),
              GestureDetector(
                child: Text('All Photos', style: widget.menuStyle),
                onTap: () {
                  pageCubit.emit(!pageCubit.state);
                  sheetController.expand();
                },
              )
            ],
          ),
        ),
      );
    }
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