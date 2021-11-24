import 'package:flutter/material.dart';
import 'package:piky/Pickers/giphy_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'imager_picker.dart';

enum PickerType {
  ImagePicker,
  GiphyPickerView,
}

enum Option {
  Open,
  Close,
}

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

  ///The height of either the minExtentHeaderBuilder or the height of the maxExtentHeaderBuilder
  ///Header height should always be passed in specifying the height of maxExtentImageHeaderBuilder
  ///or minExtentImageHeaderBuilder so the offset of the sliding sheet can be set accordingly
  final double headerHeight;

  ///Loading Indicator for the Media Viewer
  ///If not used [CircularProgressIndicator] will be its placeholder
  final Widget? imageLoadingIndicator;

  Picker({
    required this.apiKey,
    required this.child, 
    required this.backgroundColor, 
    required this.controller,  
    required this.imageHeaderBuilder,
    this.imageLoadingIndicator,
    this.initialExtent = 0.55, 
    this.minExtent = 0.0,
    this.mediumExtent = 0.55,
    this.expandedExtent= 1.0,
    this.headerHeight = 50
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

  @override
  void initState(){
    super.initState();
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

  ///Opens the image picker: Called from picker controller
  void openImagePicker(
    List<AssetEntity> selectedAssets, 
    DurationConstraint duration, 
    int imageCount, 
    bool onlyPhotos){
    
    /// Intialize the [ImagePickerController]
    imagePickerController = ImagePickerController(
      selectedAssets: selectedAssets, 
      duration: duration, 
      imageCount: imageCount, 
      onlyPhotos: onlyPhotos
    );

    // Set the picker type
    type = PickerType.ImagePicker;

    ///Calles onChange and returns the image list
    imagePickerController!.addListener(_imageReceiver);

    setState(() {});

    widget.controller._update();
  }

  ///Close the image picker: Called from image controller
  void closeImagePicker(){

    setState(() {

      type = null;

      imagePickerController!.removeListener(_imageReceiver);

      imagePickerController?.dispose();

      imagePickerController = null;

      widget.controller._update();

    });

  }

  ///Close the giphy picker: Called from picker controller
  void closeGiphyPicker(){

    setState(() {

      type = null;

      giphyPickerController!.removeListener(_giphyReceiver);

      giphyPickerController?.dispose();

      giphyPickerController = null;

      widget.controller._update();

    });

  }

  ///Opens the giphy picker: Called from picker controller
  void openGiphyPicker(){

    giphyPickerController = GiphyPickerController();

    type = PickerType.GiphyPickerView;

    giphyPickerController!.addListener(_giphyReceiver);

    setState(() {});

    widget.controller._update();

  }

  ///Handles the giphy receiving
  void _giphyReceiver() {
    widget.controller.onGiphyReceived(giphyPickerController!.gif);
  }

  ///Handles the image receiving
  void _imageReceiver() { 
    widget.controller.onImageReceived(imagePickerController!.list);
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
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInQuad,
            padding: EdgeInsets.only(bottom: type != null ? (height*(widget.initialExtent)) - 5 : MediaQuery.of(context).viewInsets.bottom),
            child: widget.child,
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                child: child,
                position: Tween<Offset>(
                  begin: Offset(0, -(height*(widget.initialExtent)) - 5), 
                  end: Offset.zero
                ).animate(animation),
              );
            },
            child: type == PickerType.ImagePicker ? 
            ImagePicker(
              key: Key('ImagePicker'), 
              controller: imagePickerController, 
              pickerController: widget.controller, 
              initialExtent: widget.initialExtent, 
              minExtent: widget.minExtent,
              mediumExtent: widget.mediumExtent,
              expandedExtent: widget.expandedExtent,
              headerBuilder: widget.imageHeaderBuilder,
              headerHeight: widget.headerHeight,
              loadingIndicator: widget.imageLoadingIndicator,
            ) : type == PickerType.GiphyPickerView ? 
            GiphyPicker(
              key: Key('GiphyPicker'), 
              apiKey: widget.apiKey, 
              controller: giphyPickerController, 
              pickerController: widget.controller, 
              initialExtent: widget.initialExtent, 
              expandedExtent: widget.expandedExtent
            ) :
            Container(),
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

  void openImagePicker({

    DurationConstraint duration = const DurationConstraint(max: Duration(minutes: 1)),

    List<AssetEntity> selectedAssets = const [],

    int imageCount = 5,

    bool onlyPhotos = false

  }) => _state!.openImagePicker(selectedAssets, duration, imageCount, onlyPhotos);

  void closeImagePicker() => _state!.closeImagePicker();

  void closeGiphyPicker() => _state!.closeGiphyPicker();

  void openGiphyPicker() => _state!.openGiphyPicker();

  PickerType? get type => _state != null ? _state!.type : null;

  ///Returns the gify controller
  GiphyPickerController? get gifController => _state!.giphyPickerController;

  ///Returns the image picker controller
  ImagePickerController? get imageController => _state!.imagePickerController;


  ///Notifies all listners
  void _update() => notifyListeners();

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

}

