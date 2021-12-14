import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piky/Pickers/custom_picker.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:piky/piky.dart';
import 'package:piky/util/functions.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import 'imager_picker.dart';

enum PickerType {
  ImagePicker,
  GiphyPickerView,
  Custom,
  None
}

enum Option {
  Open,
  Close,
}

enum PickerExpansion {
  MINIMUM,
  INITIAL,
  MIDDLE,
  EXPANDED
}


// enum PickerValue {
//   ImagePicker,
//   GiphyPicker,
//   Cusom,
//   None,
// }

class Picker extends StatefulWidget {

  ///Giphy API Key
  final String apiKey;

  ///Child be padded when image or giphy picker is shown
  final Widget child;

  ///Background color behind the image picker
  ///Is seen when neither the Image picker or the Giphy picker is loaded
  final Color backgroundColor;

  ///Picker of controller
  final PickerController controller;

  ///Sliding Sheet Extents
  final double initialExtent;
  final double minExtent;
  final double mediumExtent;
  final double expandedExtent;

  ///MaxExtentHeaderBuilder For the ImagePicker
  ///Displayed when the sliding sheet current extent reaches expanded extent
  final Widget Function(String, bool) imageHeaderBuilder;

  /// Builds the album menu of the image picker
  /// Contains a list of [AssetEntity] mapped to [Uint8List]'s for thumbnails and information
  final Widget Function(Map<AssetPathEntity, Uint8List?>, ScrollController, dynamic Function(AssetPathEntity)) albumMenuBuilder;

  ///The height of either the minExtentHeaderBuilder or the height of the maxExtentHeaderBuilder
  ///Header height should always be passed in specifying the height of maxExtentImageHeaderBuilder
  ///or minExtentImageHeaderBuilder so the offset of the sliding sheet can be set accordingly
  final double headerHeight;

  ///Loading Indicator for the Media Viewer
  ///If not used [CircularProgressIndicator] will be its placeholder
  final Widget? imageLoadingIndicator;

  ///Loading Indicator for the Gif viewer when no Gifs are loaded
  final Widget? Function(BuildContext, bool)? gifLoadingIndicator;

  ///Loading Indicator for the Gif viewer when Gifs are currently beiing rendered
  final Widget? gifLoadingTileIndicator;

  ///Initiate Backdrop Colors
  final Color minBackdropColor;
  final Color maxBackdropColor;

  /// Overlay Widget of the selected asset
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  /// Overlay displayed when images or videos are locked
  final Widget Function(BuildContext context, int index)? lockOverlayBuilder;

  /// Background color for the image selector
  /// Status color used for the animated status bar color
  /// Background color used behind the image and album delegate
  final Color imageBackgroundColor;
  final Color imageStatusBarColor;

  /// GiphyPicker
  final TextStyle cancelButtonStyle;
  final Widget? notch;
  final TextStyle hiddenTextStyle;
  final TextStyle style;
  final Icon icon;
  final TextStyle iconStyle;
  final Color searchColor;
  final Color gifStatusBarColor;
  final Color gifBackgroundColor;


  /// Initial Picker Value
  final PickerType initialValue;

  /// Custom picker
  final Widget Function(BuildContext context, ScrollController scrollController, SheetState state)? customBodyBuilder;
  final Widget Function(BuildContext context, SheetState state)? headerBuilder;
  Color customStatusBarColor;

  Picker({
    required this.apiKey,
    required this.child, 
    required this.initialValue,
    required this.backgroundColor, 
    required this.controller,  
    required this.imageHeaderBuilder,
    required this.albumMenuBuilder,
    this.lockOverlayBuilder,
    this.overlayBuilder,
    this.imageLoadingIndicator,
    this.initialExtent = 0.55, 
    this.minExtent = 0.0,
    this.mediumExtent = 0.55,
    this.expandedExtent= 1.0,
    this.headerHeight = 50,
    this.minBackdropColor = Colors.transparent,
    this.maxBackdropColor = Colors.black,
    this.imageStatusBarColor = Colors.white,
    this.imageBackgroundColor = Colors.white,
    // Giphy Picker
    this.notch,
    this.cancelButtonStyle = const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
    this.hiddenTextStyle = const TextStyle(fontSize: 14, color: Colors.black),
    this.style = const TextStyle(fontSize: 14),
    this.icon = const Icon(Icons.search, size: 24, color: Colors.black),
    this.iconStyle = const TextStyle(color: Colors.grey),
    this.searchColor = Colors.grey,
    this.gifLoadingIndicator,
    this.gifLoadingTileIndicator,
    this.gifStatusBarColor = Colors.white,
    this.gifBackgroundColor = Colors.white,
    // Custom Picker
    this.customBodyBuilder,
    this.headerBuilder,
    this.customStatusBarColor = Colors.white,

  });

  @override
  _PickerState createState() => _PickerState();
}

class _PickerState extends State<Picker> {

  ///Option: ImagePicker or GiffyPicker
  ConcreteCubit<PickerType?> type = ConcreteCubit(null);

  ///Image picker controller
  ImagePickerController? imagePickerController;

  ///Giffy picker controller
  GiphyPickerController? giphyPickerController;

  ///Main Sliding sheet controller for the image picker
  late SheetController imageSheetController;

  ///Main Sliding sheet controller for the giphy picker
  late SheetController gifSheetController;

  ///Main Sliding sheet controller for the custom picker
  late SheetController customSheetController;

  Future<void> Function()? currentlyOpen;

  double bottomPadding = 0.0;

  bool get isOpen => bottomPadding > 0;

  late ConcreteCubit<double> sheetState;

  /// If the padding is locked in place
  bool paddingLock = false;

  bool local = false;

  @override
  void initState(){
    super.initState();

    /// Extent of all 3 sliding sheets
    sheetState = ConcreteCubit<double>(widget.initialExtent);

     /// Intialize the [ImagePickerController]
    imagePickerController = ImagePickerController(
      selectedAssets: [], 
      duration: DurationConstraint(max: Duration(minutes: 1)), 
      imageCount: 5, 
      onlyPhotos: false
    );
    giphyPickerController = GiphyPickerController();

    ///Calles onChange and returns the image list
    imagePickerController!.addListener(_imageReceiver);
    giphyPickerController!.addListener(_giphyReceiver);

    //Initiate controllers
    imageSheetController = SheetController();
    gifSheetController = SheetController();
    customSheetController = SheetController();

    if(widget.initialValue != PickerType.None){
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) { 
        openPicker(overrideLock: false);
      });
    }
  }

  @override
  void dispose() {
    imagePickerController!.dispose();
    giphyPickerController!.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller._bind(this);
    }
  }

  ///Snaps the currently open picker to the defined extent
  void snapPickerTo(PickerExpansion extent){
    
    //Retreive picker sheet controller
    late SheetController currentSheetController;
    switch (type.state) {
      case PickerType.Custom:
        currentSheetController = customSheetController;
        break;
      case PickerType.GiphyPickerView:
        currentSheetController = gifSheetController;
        break;
      case PickerType.ImagePicker:
        currentSheetController = imageSheetController;
        break;
      default:
        throw 'Picker Closed';
    }

    switch (extent) {
      case PickerExpansion.MINIMUM:
        currentSheetController.snapToExtent(widget.minExtent, duration: Duration(milliseconds: 300));
        break;
      case PickerExpansion.INITIAL:
        currentSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300));
        break;
      case PickerExpansion.MIDDLE:
        currentSheetController.snapToExtent(widget.mediumExtent, duration: Duration(milliseconds: 300));
        break;
      case PickerExpansion.EXPANDED:
        currentSheetController.snapToExtent(widget.expandedExtent, duration: Duration(milliseconds: 300));
        break;
      default:
        throw 'Invalid Extent';
    }

  }

  void multiSheetStateListener(SheetState state){
    sheetState.emit(state.extent);
  }

  void openPicker({
    PickerType? index,
    List<AssetEntity>? selectedAssets, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos,
    bool? overrideLock
  }) async {
    type.emit(index ?? widget.initialValue);
    bottomPadding = (MediaQuery.of(context).size.height*(widget.minExtent));
    if(overrideLock != null){
      paddingLock = overrideLock;
    }
    else{
      paddingLock = true;
    }
    await Future.delayed(Duration(milliseconds: 50));
    if(type.state == PickerType.ImagePicker){
      openImagePicker(selectedAssets ?? const [], const DurationConstraint(max: Duration(minutes: 1)), imageCount ?? 5, onlyPhotos ?? false, overrideLock).then((value) {
        paddingLock = false;
      });
    }
    else if(type.state == PickerType.GiphyPickerView){
      openGiphyPicker(overrideLock);
    }
    else if(type.state == PickerType.Custom){
      openCustomPicker(overrideLock);
    }
  }

  Future<void> instantOpen({
    PickerType? index,
    List<AssetEntity>? selectedAssets, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos,
    bool? overrideLock,
  }) async {
    type.emit(index);
    bottomPadding = (MediaQuery.of(context).size.height*(widget.minExtent));
    if(overrideLock != null){
      paddingLock = overrideLock;
    }
    else{
      paddingLock = true;
    }
    if(type.state == PickerType.ImagePicker){
      currentlyOpen = closeImagePicker;
      imageSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300))?.then((value) {
        paddingLock = false;
      }) ?? Future.delayed(Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
      });
    }
    else if(type.state == PickerType.GiphyPickerView){
      currentlyOpen = closeGiphyPicker;
      gifSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300))?.then((value) {
      paddingLock = false;
      }) ?? Future.delayed(Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
      });
    }
    if(type.state == PickerType.Custom){
      currentlyOpen = closeCustomPicker;
      customSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300))?.then((value) {
      paddingLock = false;
      }) ?? Future.delayed(Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
      });
    }
  }

  void closePicker() async {
    
    if(currentlyOpen != null){
      await currentlyOpen!();
    }

    await Future.delayed(Duration(milliseconds: 50));

    bottomPadding = 0;

    setState((){});
  }

  ///Opens the image picker: Called from picker controller
  Future<void> openImagePicker(
    List<AssetEntity> selectedAssets, 
    DurationConstraint duration, 
    int imageCount, 
    bool onlyPhotos,
    [bool? overrideLock]) async {
    
    /// Intialize the [ImagePickerController]
    // imagePickerController = ImagePickerController(
    //   selectedAssets: selectedAssets, 
    //   duration: duration, 
    //   imageCount: imageCount, 
    //   onlyPhotos: onlyPhotos
    // );

    bottomPadding = (MediaQuery.of(context).size.height*(widget.minExtent));

    if(overrideLock != null){
      paddingLock = overrideLock;
    }
    else{
      paddingLock = true;
    }

    if(currentlyOpen != null && type.state != PickerType.ImagePicker){
      await currentlyOpen!();
    }
    
    currentlyOpen = closeImagePicker;

    imageSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300))?.then((value) {
      paddingLock = false;
      type.emit(PickerType.ImagePicker);
    }) ?? Future.delayed(Duration(milliseconds: 300)).then((value) {
      paddingLock = false;
      type.emit(PickerType.ImagePicker);
    });
  }

  ///Close the image picker: Called from image controller
  Future<void> closeImagePicker() async {

    type.emit(null);

    widget.controller._update();

    await imageSheetController.collapse();

  }

  ///Close the giphy picker: Called from picker controller
  Future<void> closeGiphyPicker() async {
    type.emit(null);
    widget.controller._update();
    await gifSheetController.collapse();
  }

  Future<void> closeCustomPicker() async {
    type.emit(null);
    widget.controller._update();
    await customSheetController.collapse();
  }

  ///Opens the giphy picker: Called from picker controller
  Future<void> openGiphyPicker([bool? overrideLock]) async {

    bottomPadding = (MediaQuery.of(context).size.height*(widget.minExtent));
    
    if(overrideLock != null){
      paddingLock = overrideLock;
    }
    else{
      paddingLock = true;
    }

    if(currentlyOpen != null && type.state != PickerType.GiphyPickerView){
      await currentlyOpen!();
    }

    currentlyOpen = closeGiphyPicker;

    gifSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300))?.then((value) {
      paddingLock = false;
      type.emit(PickerType.GiphyPickerView);
    }) ?? Future.delayed(Duration(milliseconds: 300)).then((value) {
      paddingLock = false;
      type.emit(PickerType.GiphyPickerView);
    });
  }

  Future<void> openCustomPicker([bool? overrideLock]) async {

    bottomPadding = (MediaQuery.of(context).size.height*(widget.minExtent));

    if(overrideLock != null){
      paddingLock = overrideLock;
    }
    else{
      paddingLock = true;
    }

    if(currentlyOpen != null && type.state != PickerType.Custom){
      await currentlyOpen!();
    }

    currentlyOpen = closeCustomPicker;

    await customSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300))?.then((value) {
      paddingLock = false;
      type.emit(PickerType.Custom);
    }) ?? Future.delayed(Duration(milliseconds: 300)).then((value) {
      paddingLock = false;
      type.emit(PickerType.Custom);
    });
  }

  ///Handles the giphy receiving
  void _giphyReceiver() {
    if(imagePickerController != null){
      imagePickerController!.clearAll();
      widget.controller.onImageReceived([]);
    }
    widget.controller.onGiphyReceived(giphyPickerController!.gif);
  }

  ///Handles the image receiving
  void _imageReceiver() { 
    if(giphyPickerController != null){
      giphyPickerController!.clearGif();
      widget.controller.onGiphyReceived('');
    }
    widget.controller.onImageReceived(imagePickerController!.list);
  }

  /// Clear Asset Entity
  void clearAssetEntity(AssetEntity asset){
    if(imagePickerController != null){
      imagePickerController?.clearAssetEntity(asset);
    }
  }

  /// Clear all assets
  void clearAllAsset(){
    if(imagePickerController != null && giphyPickerController != null){
      giphyPickerController?.clearGif();
      imagePickerController?.clearAll();
      widget.controller.onImageReceived([]);
      widget.controller.onGiphyReceived('');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: widget.backgroundColor,
      body: BlocBuilder<ConcreteCubit<PickerType?>, PickerType?>(
        bloc: type,
        buildWhen: (o, n) => o!=n,
        builder: (context, pickerType) {
          return Stack(
            children: [
              BlocBuilder<ConcreteCubit<double>, double>(
                bloc: sheetState,
                builder: (context, extent) {
                  return AnimatedPadding(
                    duration: Duration(milliseconds: 0),
                    curve: Curves.linear,
                    padding: EdgeInsets.only(bottom: extent > widget.initialExtent || paddingLock ? bottomPadding : (bottomPadding/widget.minExtent)*extent),
                    child: widget.child,
                  );
                }
              ),
              ImagePicker(
                key: Key('ImagePicker'), 
                isLocked: pickerType == PickerType.ImagePicker,
                sheetController: imageSheetController,
                controller: imagePickerController, 
                pickerController: widget.controller, 
                initialExtent: widget.initialExtent, 
                minExtent: 0,
                mediumExtent: widget.mediumExtent,
                expandedExtent: widget.expandedExtent,
                headerBuilder: widget.imageHeaderBuilder,
                albumMenuBuilder: widget.albumMenuBuilder,
                loadingIndicator: widget.imageLoadingIndicator,
                minBackdropColor: widget.minBackdropColor,
                maxBackdropColor: widget.maxBackdropColor,
                overlayBuilder: widget.overlayBuilder,
                statusBarPaddingColor: widget.imageStatusBarColor,
                backgroundColor: widget.imageBackgroundColor,
                lockOverlayBuilder: widget.lockOverlayBuilder,
                listener: multiSheetStateListener,
              ),
              GiphyPicker(
                key: Key('GiphyPicker'), 
                isLocked: pickerType == PickerType.GiphyPickerView,
                apiKey: widget.apiKey, 
                sheetController: gifSheetController,
                controller: giphyPickerController, 
                pickerController: widget.controller,
                initialExtent: widget.initialExtent, 
                minExtent: 0,
                mediumExtent: widget.mediumExtent,
                expandedExtent: widget.expandedExtent,
                notch: widget.notch,
                cancelButtonStyle: widget.cancelButtonStyle,
                hiddentTextStyle: widget.hiddenTextStyle,
                style: widget.style,
                icon: widget.icon,
                iconStyle: widget.iconStyle,
                backgroundColor: widget.gifBackgroundColor,
                searchColor: widget.searchColor,
                minBackdropColor: widget.minBackdropColor,
                maxBackdropColor: widget.maxBackdropColor,
                loadingIndicator: widget.gifLoadingIndicator,
                loadingTileIndicator: widget.gifLoadingTileIndicator,
                statusBarPaddingColor: widget.gifStatusBarColor,
                overlayBuilder: widget.overlayBuilder,
                headerColor: widget.gifStatusBarColor,
                listener: multiSheetStateListener,
              ),
              CustomPicker(
                isLocked: pickerType == PickerType.Custom,
                sheetController: customSheetController, 
                pickerController: widget.controller, 
                customBodyBuilder: widget.customBodyBuilder!, 
                headerBuilder: widget.headerBuilder!,
                initialExtent: widget.initialExtent, 
                minExtent: 0,
                mediumExtent: widget.mediumExtent,
                expandedExtent: widget.expandedExtent,
                statusBarPaddingColor: widget.customStatusBarColor,
                minBackdropColor: widget.minBackdropColor,
                maxBackdropColor: widget.maxBackdropColor,
                listener: multiSheetStateListener,
              ) 
            ],
          );
        }
      ),
    );
  }
}

class PickerController extends ChangeNotifier{

  _PickerState? _state;

  ///If a image is selected inside of the ImagePicker
  Function(List<AssetEntity>? images) onImageReceived;
  ///If a Giphy is selected inside of the GiphyPicker
  Function(String? gif) onGiphyReceived;

  PickerController({required this.onGiphyReceived, required this.onImageReceived});

  void _bind(_PickerState bind) => _state = bind;

  bool get isOpen => _state!.isOpen;

  void openImagePicker({

    DurationConstraint duration = const DurationConstraint(max: Duration(minutes: 1)),

    List<AssetEntity> selectedAssets = const [],

    int imageCount = 5,

    bool onlyPhotos = false,

    bool? overrideLock

  }) => _state!.openImagePicker(selectedAssets, duration, imageCount, onlyPhotos, overrideLock);

  void closePicker() => _state!.closePicker();
  
  void openPicker({
    PickerType? index,
    List<AssetEntity>? selectedAssets, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos,
    bool? overrideLock
  }) => _state!.openPicker(
    index: index,
    selectedAssets: selectedAssets,
    duration: duration,
    imageCount: imageCount,
    onlyPhotos: onlyPhotos,
    overrideLock: overrideLock
  );

  void closeImagePicker() => _state!.closeImagePicker();

  void closeGiphyPicker() => _state!.closeGiphyPicker();

  void openGiphyPicker(bool? overrideLock) => _state!.openGiphyPicker(overrideLock);

  void openCustomPicker(bool? overrideLock) => _state!.openCustomPicker(overrideLock);

  void closeCustomPicker() => _state!.closeCustomPicker();

  void instantOpen({
    PickerType? index,
    List<AssetEntity>? selectedAssets, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos,
    bool? overrideLock
  }) => _state!.instantOpen(
    index: index, 
    selectedAssets: selectedAssets, 
    duration: duration, 
    imageCount: imageCount, 
    onlyPhotos: onlyPhotos,
    overrideLock: overrideLock
  );

  PickerType? get type => _state != null ? _state!.type.state : null;

  ///Returns the gify controller
  GiphyPickerController? get gifController => _state!.giphyPickerController;

  ///Returns the image picker controller
  ImagePickerController? get imageController => _state!.imagePickerController;

  /// Clears an indivudal asset
  void clearAssetEntity(AssetEntity asset) => _state != null ? _state!.clearAssetEntity(asset) : null;

  /// Clear every asset
  void clearAll() => _state != null ? _state!.clearAllAsset() : null;

  /// Snaps the current sheet controller to an extent
  /// Picker must be open to an index
  void snap(PickerExpansion extent) => _state != null ? _state!.snapPickerTo(extent) : null;

  ///Notifies all listners
  void _update() => notifyListeners();

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

}

