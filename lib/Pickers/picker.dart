import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:piky/Pickers/custom_picker.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:piky/piky.dart';
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

  /// GiphyPicker
  Widget? notch;
  TextStyle cancelButtonStyle;
  TextStyle hiddenTextStyle;
  TextStyle style;
  Icon icon;
  TextStyle iconStyle;
  Color searchColor;
  Color gifStatusBarColor;

  /// Initial Picker Value
  PickerType initialValue;

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
    this.overlayBuilder,
    this.imageLoadingIndicator,
    this.initialExtent = 0.55, 
    this.minExtent = 0.0,
    this.mediumExtent = 0.55,
    this.expandedExtent= 1.0,
    this.headerHeight = 50,
    this.minBackdropColor = Colors.transparent,
    this.maxBackdropColor = Colors.black,
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
  PickerType? type;

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

  @override
  void initState(){
    super.initState();

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
        openPicker();
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

  void openPicker({
    PickerType? index,
    List<AssetEntity>? selectedAssets, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos
  }) async {
    type = (index ?? widget.initialValue);
    bottomPadding = (MediaQuery.of(context).size.height*(widget.initialExtent)) - 5;
    setState((){});
    await Future.delayed(Duration(milliseconds: 50));
    if(type == PickerType.ImagePicker){
      openImagePicker(selectedAssets ?? const [], const DurationConstraint(max: Duration(minutes: 1)), imageCount ?? 5, onlyPhotos ?? false);
    }
    else if(type == PickerType.GiphyPickerView){
      openGiphyPicker(); 
    }
    else if(type == PickerType.Custom){
      openCustomPicker();
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
  void openImagePicker(
    List<AssetEntity> selectedAssets, 
    DurationConstraint duration, 
    int imageCount, 
    bool onlyPhotos) async {
    
    /// Intialize the [ImagePickerController]
    // imagePickerController = ImagePickerController(
    //   selectedAssets: selectedAssets, 
    //   duration: duration, 
    //   imageCount: imageCount, 
    //   onlyPhotos: onlyPhotos
    // );

    if(currentlyOpen != null && type != PickerType.ImagePicker){
      await currentlyOpen!();
    }

    // Set the picker type
    type = PickerType.ImagePicker;

    currentlyOpen = closeImagePicker;

    await imageSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300));

    setState((){});

    widget.controller._update();
  }

  ///Close the image picker: Called from image controller
  Future<void> closeImagePicker() async {

    type = null;

    setState((){});

    // imagePickerController!.removeListener(_imageReceiver);

    // imagePickerController?.dispose();

    // imagePickerController = null;

    widget.controller._update();

    await imageSheetController.collapse();

  }

  ///Close the giphy picker: Called from picker controller
  Future<void> closeGiphyPicker() async {

    type = null;

    setState((){});

    // giphyPickerController!.removeListener(_giphyReceiver);

    // giphyPickerController?.dispose();

    // giphyPickerController = null;

    widget.controller._update();

    await gifSheetController.collapse();

  }

  Future<void> closeCustomPicker() async {
      
    type = null;

    setState((){});

    widget.controller._update();

    await customSheetController.collapse();
  }

  ///Opens the giphy picker: Called from picker controller
  void openGiphyPicker() async {

    if(currentlyOpen != null && type != PickerType.GiphyPickerView){
      await currentlyOpen!();
    }

    type = PickerType.GiphyPickerView;

    currentlyOpen = closeGiphyPicker;

    await gifSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300));

    setState((){});

    widget.controller._update();

  }

  void openCustomPicker() async {

    if(currentlyOpen != null && type != PickerType.Custom){
      await currentlyOpen!();
    }

    type = PickerType.Custom;

    currentlyOpen = closeCustomPicker;

    await customSheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300));

    setState((){});

    widget.controller._update();
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
    }
  }

  @override
  Widget build(BuildContext context) {

    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: widget.backgroundColor,
      body: Stack(
        children: [
          AnimatedPadding(
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: widget.child,
          ),

          // type == PickerType.ImagePicker ? 
          ImagePicker(
            key: Key('ImagePicker'), 
            isLocked: type == PickerType.ImagePicker,
            sheetController: imageSheetController,
            controller: imagePickerController, 
            pickerController: widget.controller, 
            // initialExtent: 0,
            initialExtent: widget.initialExtent, 
            minExtent: 0,
            mediumExtent: widget.mediumExtent,
            expandedExtent: widget.expandedExtent,
            headerBuilder: widget.imageHeaderBuilder,
            albumMenuBuilder: widget.albumMenuBuilder,
            headerHeight: widget.headerHeight,
            loadingIndicator: widget.imageLoadingIndicator,
            minBackdropColor: widget.minBackdropColor,
            maxBackdropColor: widget.maxBackdropColor,
            overlayBuilder: widget.overlayBuilder,
          ),
          // ) : type == PickerType.GiphyPickerView ? 
          GiphyPicker(
            key: Key('GiphyPicker'), 
            isLocked: type == PickerType.GiphyPickerView,
            apiKey: widget.apiKey, 
            sheetController: gifSheetController,
            controller: giphyPickerController, 
            pickerController: widget.controller,
            // initialExtent: 0,
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
            backgroundColor: widget.backgroundColor,
            searchColor: widget.searchColor,
            minBackdropColor: widget.minBackdropColor,
            maxBackdropColor: widget.maxBackdropColor,
            loadingIndicator: widget.gifLoadingIndicator,
            loadingTileIndicator: widget.gifLoadingTileIndicator,
            statusBarPaddingColor: widget.gifStatusBarColor,
          ) ,
          // : type == PickerType.Custom ? 
          CustomPicker(
            isLocked: type == PickerType.Custom,
            sheetController: customSheetController, 
            pickerController: widget.controller, 
            customBodyBuilder: widget.customBodyBuilder!, 
            headerBuilder: widget.headerBuilder!,
            // initialExtent: 0,
            initialExtent: widget.initialExtent, 
            minExtent: 0,
            mediumExtent: widget.mediumExtent,
            expandedExtent: widget.expandedExtent,
            statusBarPaddingColor: widget.customStatusBarColor,
            minBackdropColor: widget.minBackdropColor,
            maxBackdropColor: widget.maxBackdropColor,
          ) 
          // : Container()
        ],
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

    bool onlyPhotos = false

  }) => _state!.openImagePicker(selectedAssets, duration, imageCount, onlyPhotos);

  void closePicker() => _state!.closePicker();
  
  void openPicker({
    PickerType? index,
    List<AssetEntity>? selectedAssets, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos
  }) => _state!.openPicker(
    index: index,
    selectedAssets: selectedAssets,
    duration: duration,
    imageCount: imageCount,
    onlyPhotos: onlyPhotos,
  );

  void closeImagePicker() => _state!.closeImagePicker();

  void closeGiphyPicker() => _state!.closeGiphyPicker();

  void openGiphyPicker() => _state!.openGiphyPicker();

  void openCustomPicker() => _state!.openCustomPicker();

  void closeCustomPicker() => _state!.closeCustomPicker();

  PickerType? get type => _state != null ? _state!.type : null;

  ///Returns the gify controller
  GiphyPickerController? get gifController => _state!.giphyPickerController;

  ///Returns the image picker controller
  ImagePickerController? get imageController => _state!.imagePickerController;

  /// Clears an indivudal asset
  void clearAssetEntity(AssetEntity asset) => _state != null ? _state!.clearAssetEntity(asset) : null;

  /// Clear every asset
  void clearAll() => _state != null ? _state!.clearAllAsset() : null;

  ///Notifies all listners
  void _update() => notifyListeners();

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

}

