import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/custom_picker.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:piky/piky.dart';

import 'imager_picker.dart';

enum PickerType {
  ImagePicker,
  GiphyPickerView,
  Custom,
  None
}

enum PikyOption {
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

  /// Color of the background overlay when the piky is expanded
  final Color maxBackdropColor;

  /// Initial Picker Value
  final PickerType initialValue;

  /// Delegates to build each piky
  final ImagePickerConfigDelegate? imagePickerDelegate;
  final GiphyPickerConfigDelegate? giphyPickerDelegate;
  final CustomPickerConfigDelegate? customPickerDelegate;

  Picker({
    required this.child, 
    required this.initialValue,
    required this.backgroundColor, 
    required this.controller,  
    this.initialExtent = 0.55, 
    this.minExtent = 0.0,
    this.mediumExtent = 0.55,
    this.expandedExtent= 1.0,
    this.maxBackdropColor = Colors.black,
    this.imagePickerDelegate,
    this.giphyPickerDelegate,
    this.customPickerDelegate,
  }) : assert(
    imagePickerDelegate != null ||
    giphyPickerDelegate != null ||
    customPickerDelegate != null
  ),
  assert(initialValue != PickerType.ImagePicker || imagePickerDelegate != null),
  assert(initialValue != PickerType.GiphyPickerView || giphyPickerDelegate != null),
  assert(initialValue != PickerType.Custom || customPickerDelegate != null);

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
  late final PerceiveSlidableController imageSheetController = PerceiveSlidableController();

  ///Main Sliding sheet controller for the giphy picker
  late final PerceiveSlidableController gifSheetController = PerceiveSlidableController();

  ///Main Sliding sheet controller for the custom picker
  late final PerceiveSlidableController customSheetController = PerceiveSlidableController();

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
      imageCount: 4, 
      onlyPhotos: false
    );
    giphyPickerController = GiphyPickerController();

    ///Calles onChange and returns the image list
    imagePickerController!.addListener(_imageReceiver);
    giphyPickerController!.addListener(_giphyReceiver);

    if(widget.initialValue != PickerType.None){
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
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
    late PerceiveSlidableController currentSheetController;
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
        currentSheetController.snapTo(widget.minExtent, duration: Duration(milliseconds: 300));
        break;
      case PickerExpansion.INITIAL:
        currentSheetController.snapTo(widget.initialExtent, duration: Duration(milliseconds: 300));
        break;
      case PickerExpansion.MIDDLE:
        currentSheetController.snapTo(widget.mediumExtent, duration: Duration(milliseconds: 300));
        break;
      case PickerExpansion.EXPANDED:
        currentSheetController.snapTo(widget.expandedExtent, duration: Duration(milliseconds: 300));
        break;
      default:
        throw 'Invalid Extent';
    }

  }

  dynamic multiSheetStateListener(double extent){
    sheetState.emit(extent);
  }

  void openPicker({
    PickerType? index,
    List<AssetEntity>? selectedAssets,
    String? gif,
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
      if(widget.imagePickerDelegate != null){
        openImagePicker(selectedAssets ?? const [], const DurationConstraint(max: Duration(minutes: 1)), imageCount ?? 5, onlyPhotos ?? false, overrideLock).then((value) {
          paddingLock = false;
        });
      }
      else{
        //Close piky
        closePicker();
      }
    }
    else if(type.state == PickerType.GiphyPickerView){
      if(widget.giphyPickerDelegate != null){
        openGiphyPicker(gif ?? '', overrideLock);
      }
      else{
        //Close piky
        closePicker();
      }
    }
    else if(type.state == PickerType.Custom){
      if(widget.customPickerDelegate != null){
        openCustomPicker(overrideLock);
      }
      else{
        //Close piky
        closePicker();
      }
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

    if(selectedAssets.isNotEmpty && mounted){
      imagePickerController!.addAssets(selectedAssets);
    }

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

    if(widget.imagePickerDelegate == null){
      // No image picker
      paddingLock = false;
      setState(() {});
      return;
    }
    
    currentlyOpen = closeImagePicker;

    try{
      await imageSheetController.snapTo(widget.initialExtent, duration: Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
        type.emit(PickerType.ImagePicker);
      });
    }catch(e){
      await Future.delayed(Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
        type.emit(PickerType.ImagePicker);
      });
    }

    setState(() {});
  }

  ///Close the image picker: Called from image controller
  Future<void> closeImagePicker() async {

    type.emit(null);

    widget.controller._update();

    if(widget.imagePickerDelegate == null){
      // No image picker
      return;
    }

    await imageSheetController.snapTo(0);

  }

  ///Close the giphy picker: Called from picker controller
  Future<void> closeGiphyPicker() async {
    type.emit(null);
    widget.controller._update();

    if(widget.giphyPickerDelegate == null){
      // No gif picker
      return;
    }

    await gifSheetController.snapTo(0);
  }

  Future<void> closeCustomPicker() async {
    type.emit(null);
    widget.controller._update();

    if(widget.customPickerDelegate == null){
      // No custom picker
      return;
    }

    await customSheetController.snapTo(0);
  }

  ///Opens the giphy picker: Called from picker controller
  Future<void> openGiphyPicker(String gif, [bool? overrideLock]) async {

    if(gif != '' && mounted){
      giphyPickerController!.addAsset(gif);
    }

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

    if(widget.giphyPickerDelegate == null){
      // No gif picker
      paddingLock = false;
      setState((){});
      return;
    }

    currentlyOpen = closeGiphyPicker;

    try{
      await gifSheetController.snapTo(widget.initialExtent, duration: Duration(milliseconds: 300)).then((value) {
        type.emit(PickerType.GiphyPickerView);
        paddingLock = false;
      });
    }catch(e){
      await Future.delayed(Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
      });
    }
    setState((){});
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

    if(widget.customPickerDelegate == null){
      // No custom picker
      paddingLock = false;
      setState((){});
      return;
    }

    currentlyOpen = closeCustomPicker;
    try{
      await customSheetController.snapTo(widget.initialExtent, duration: Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
        type.emit(PickerType.Custom);
      });
    }catch(e){
      await Future.delayed(Duration(milliseconds: 300)).then((value) {
        paddingLock = false;
        type.emit(PickerType.Custom);
      });
    }

    setState(() {});
  }

  ///Handles the giphy receiving
  void _giphyReceiver() {
    if(imagePickerController != null && giphyPickerController?.gif?.isNotEmpty == true){
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
      body: Stack(
        children: [

          Positioned.fill(
            child: BlocBuilder<ConcreteCubit<double>, double>(
              bloc: sheetState,
              builder: (context, extent) {

                double animationOffset = (extent - widget.initialExtent).clamp(0, 1.0) / (widget.expandedExtent - widget.initialExtent); 

                return Stack(
                  children: [
                    AnimatedPadding(
                      duration: Duration(milliseconds: 0),
                      curve: Curves.linear,
                      padding: EdgeInsets.only(bottom: extent > widget.initialExtent || paddingLock ? bottomPadding : (bottomPadding/widget.minExtent)*extent),
                      child: widget.child,
                    ),

                    IgnorePointer(
                      ignoring: animationOffset < 0.1,
                        child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: (){
                          snapPickerTo(PickerExpansion.INITIAL);
                        },
                        child: Container(
                          color: Color.lerp(Colors.transparent, widget.maxBackdropColor, animationOffset),
                        ),
                      )
                    )
                  ],
                );
              }
            ),
          ),
          if(widget.imagePickerDelegate != null)
            ImagePicker(
              key: Key('ImagePicker'), 
              openType: type,
              sheetController: imageSheetController,
              controller: imagePickerController, 
              initialExtent: widget.initialExtent, 
              minExtent: 0,
              mediumExtent: widget.mediumExtent,
              expandedExtent: widget.expandedExtent,
              delegate: widget.imagePickerDelegate!,
              listener: multiSheetStateListener,
            ),
          if(widget.giphyPickerDelegate != null)
            GiphyPicker(
              key: Key('GiphyPicker'), 
              openType: type,
              sheetController: gifSheetController,
              controller: giphyPickerController, 
              initialExtent: widget.initialExtent, 
              minExtent: 0,
              mediumExtent: widget.mediumExtent,
              expandedExtent: widget.expandedExtent,
              delegate: widget.giphyPickerDelegate!,
              listener: multiSheetStateListener,
            ),
          if(widget.customPickerDelegate != null)
            CustomPicker(
              openType: type,
              sheetController: customSheetController, 
              initialExtent: widget.initialExtent, 
              minExtent: 0,
              mediumExtent: widget.mediumExtent,
              expandedExtent: widget.expandedExtent,
              delegate: widget.customPickerDelegate!,
              listener: multiSheetStateListener,
            ) 
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

    bool onlyPhotos = false,

    bool? overrideLock

  }) => _state!.openImagePicker(selectedAssets, duration, imageCount, onlyPhotos, overrideLock);

  void closePicker() => _state!.closePicker();
  
  /// Initially open picker
  void openPicker({
    PickerType? index,
    List<AssetEntity>? selectedAssets,
    String? gif, 
    DurationConstraint? duration, 
    int? imageCount, 
    bool? onlyPhotos,
    bool? overrideLock
  }) => _state!.openPicker(
    index: index,
    selectedAssets: selectedAssets,
    gif: gif,
    duration: duration,
    imageCount: imageCount,
    onlyPhotos: onlyPhotos,
    overrideLock: overrideLock
  );

  /// Close the image picker
  void closeImagePicker() => _state!.closeImagePicker();

  /// Close the giphy picker
  void closeGiphyPicker() => _state!.closeGiphyPicker();

  /// Open the giphy picker
  void openGiphyPicker(bool? overrideLock) => _state!.openGiphyPicker('', overrideLock);

  /// Open the custom picker (specified by user)
  void openCustomPicker(bool? overrideLock) => _state!.openCustomPicker(overrideLock);

  /// Close the custom picker (specified by user)
  void closeCustomPicker() => _state!.closeCustomPicker();

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

