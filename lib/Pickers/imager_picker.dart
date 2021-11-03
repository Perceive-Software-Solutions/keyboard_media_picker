import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keyboard_media_picker/Pickers/picker.dart';
import 'package:keyboard_media_picker/delegates/album_picker_delegate.dart';
import 'package:keyboard_media_picker/delegates/image_picker_delegate.dart';
import 'package:keyboard_media_picker/util/keep_alive.dart';
import 'package:keyboard_media_picker/util/pollar_icons.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ImagePicker extends StatefulWidget {
  final ImagePickerController? controller;
  final double initialExtent;
  final double expandedExtent;
  final TextStyle menuStyle;
  final TextStyle albumNameStyle;
  final Color backgroundColor;

  const ImagePicker({ 
    required Key key,
    required this.controller,
    this.initialExtent = 0.4,
    this.expandedExtent = 1.0,
    this.menuStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    this.albumNameStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    this.backgroundColor = Colors.white
  }) : super(key: key);

  @override
  _ImagePickerState createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> {

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
  final SheetController sheetController = SheetController();

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  ConcreteCubit<bool> sheetCubit = ConcreteCubit<bool>(false);

  /// The primary [Cubit] for the page transition between [AssetPathEntity] and [AssetEntity]
  ConcreteCubit<bool> pageCubit = ConcreteCubit<bool>(false);

  /// Filter option
  FilterOptionGroup filer = FilterOptionGroup();

  @override
  void initState() {
    super.initState();

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

    //Build delegate
    imageDelegate = ImagePickerBuilderDelegate(
      provider,
      widget.controller,
      gridCount: 4
    );

    albumDelegate = AlbumPickerBuilderDelegate(
      provider,
      pageCubit,
      widget.controller,
      gridCount: 2
    );

    initialSelect(widget.controller!.selectedAssets);

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
      child: SafeArea(
        child: BlocProvider(
          create: (context) => pageCubit,
          child: BlocProvider(
            create: (context) => sheetCubit,
            child: SlidingSheet(
                controller: sheetController,
                backdropColor: Colors.white,
                closeOnBackdropTap: true,
                isBackdropInteractable: true,
                snapSpec: SnapSpec(
                  initialSnap: widget.initialExtent,
                  snappings: [widget.initialExtent, widget.expandedExtent],
                  onSnap: (state, _){
                    if(state.isCollapsed){
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
                        height: 47,
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
                builder: (context, _){
                  return BlocBuilder<ConcreteCubit<bool>, bool>(
                    bloc: pageCubit,
                    buildWhen: (o, n) => o != n,
                    builder: (context, state) {
                      return !state ? 
                      Container(key: Key("1"), child: imageDelegate.build(context)) : 
                      Container(key: Key("2"), child: albumDelegate.build(context));
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
        height: 47,
        color: widget.backgroundColor,
        child: GestureDetector(
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(pageCubit.state ? 'All Photos' : path, style: widget.menuStyle),
            Icon(PollarIcons.small_down_arrow, size: 24)
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
        height: 47,
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