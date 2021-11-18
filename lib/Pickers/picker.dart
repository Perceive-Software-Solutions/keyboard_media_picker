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

  final String apiKey;

  ///Child be padded when image or giphy picker is shown
  final Widget child;

  ///Background color of picker
  final Color backgroundColor;

  ///Picker of controller
  final PickerController controller;
  ///Initial extent of the sheet
  final double initialExtent;

  ///Expanded extent of the sheet
  final double expandedExtent;

  Picker({
    required this.apiKey,
    required this.child, 
    required this.backgroundColor, 
    required this.controller,  
    this.initialExtent = 0.4, 
    this.expandedExtent= 1.0
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
            ImagePicker(key: Key('ImagePicker'), controller: imagePickerController, initialExtent: widget.initialExtent, expandedExtent: widget.expandedExtent) :
            type == PickerType.GiphyPickerView ? 
            GiphyPicker(key: Key('GiphyPicker'), apiKey: widget.apiKey, controller: giphyPickerController, initialExtent: widget.initialExtent, expandedExtent: widget.expandedExtent) :
            Container(),
          )
        ],
      ),
    );
  }
}

class PickerController extends ChangeNotifier{

  _PickerState? _state;

  Function(List<AssetEntity>? images) onImageReceived;
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

