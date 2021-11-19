import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/delegates/giphy_picker_delegate.dart';
import 'package:piky/provider/giphy_picker_provider.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import 'imager_picker.dart';


class GiphyPicker extends StatefulWidget {

  /// Giphy Client API Key
  final String apiKey;

  /// GiphyPicker State
  final GiphyPickerController? controller;

  /// Picker State
  final PickerController pickerController;

  /// Initial extent of the [SlidingSheet]
  final double initialExtent;

  /// Expanded extent of the [SlidingSheet]
  final double expandedExtent;

  /// Background color when images are not loaded in
  final Color backgroundColor;

  /// Search bar color
  final Color searchColor;

  /// Cancel button
  final TextStyle cancelButtonStyle;

  /// Search field hint text style
  final TextStyle hiddentTextStyle;

  /// Search field hint icon style
  final TextStyle iconStyle;

  /// Search field hint icon
  final Icon icon;

  GiphyPicker({
    required Key key,
    required this.pickerController,
    required this.apiKey, 
    required this.controller, 
    required this.initialExtent, 
    required this.expandedExtent,

    this.cancelButtonStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    this.hiddentTextStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    this.icon = const Icon(Icons.search, size: 24, color: Colors.grey),
    this.iconStyle = const TextStyle(color: Colors.grey),
    this.backgroundColor = Colors.white,
    this.searchColor = Colors.grey
  }) : super(key: key);
  @override
  _GiphyPickerState createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> {

/*
 
      ____                _   
     / ___|___  _ __  ___| |_ 
    | |   / _ \| '_ \/ __| __|
    | |__| (_) | | | \__ \ |_ 
     \____\___/|_| |_|___/\__|
                              
 
*/

  static const double HEADER_HEIGHT = 50.0;

/*
 
     ____  _        _       
    / ___|| |_ __ _| |_ ___ 
    \___ \| __/ _` | __/ _ \
     ___) | || (_| | ||  __/
    |____/ \__\__,_|\__\___|
                            
 
*/

  /// Primary delegate for displaying assets
  late GiphyPickerPickerBuilderDelegate delegate;

  /// The currently slected Gif
  String? selectedAsset;

  /// Primary provider for loading assets
  late GiphyPickerProvider provider;

  /// The current state of the [GiphyPicker]
  Option type = Option.Open;

  /// Primary [FocusNode] for the [TextField] 
  /// Used to see if the [TextField] has focus
  FocusNode focusNode = FocusNode();

  /// The primary controller for the [SlidingSheet]
  SheetController sheetController = SheetController();

  /// Primary [TextEditingController] to get the current value of the [TextField]
  TextEditingController searchFieldController = TextEditingController();

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  ConcreteCubit<bool> sheetCubit = ConcreteCubit<bool>(false);

  /// Primary [Cubit] to track the textfields current value
  ConcreteCubit<String> valueCubit = ConcreteCubit<String>('');

  /// The [ScrollController] for the giphy preview grid
  ScrollController giphyScrollController = ScrollController();

  /// If the sliding sheet is currently snapping
  bool snapping = false;

  //Adds a listener to the scroll position of the staggered grid view
  @override
  void initState() {
    super.initState();
    provider = GiphyPickerProvider(pageSize: 43, apiKey: widget.apiKey);
    delegate = GiphyPickerPickerBuilderDelegate(
      provider,
      giphyScrollController, 
      widget.controller,
      sheetCubit,
      valueCubit
    );

    // Initiate Listeners
    initiateListener(giphyScrollController);
  }

  /// Matches the sheetController state to the scroll offset of the feed
  void initiateListener(ScrollController scrollController){
    scrollController.addListener(() {
      if(scrollController.offset <= -20 && !snapping){
        if(sheetController.state!.extent == 1.0){
          snapping = true;
          Future.delayed(Duration(milliseconds: 0), () {
            sheetController.snapToExtent(widget.initialExtent, duration: Duration(milliseconds: 300));
            focusNode.unfocus();
            sheetCubit.emit(false);
            scrollController.jumpTo(0.0);
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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
  Widget build(BuildContext context) {

    return SafeArea(
      top: true,
      child: BlocProvider(
        create: (context) => valueCubit,
        child: BlocProvider(
          create: (context) => sheetCubit,
          child: SlidingSheet(
              controller: sheetController,
              backdropColor: Colors.transparent,
              closeOnBackdropTap: true,
              isBackdropInteractable: true,
              duration: Duration(milliseconds: 300),
              snapSpec: SnapSpec(
                initialSnap: widget.initialExtent,
                snappings: [0.0, widget.initialExtent, widget.expandedExtent],
                onSnap: (state, _){
                  if(state.isCollapsed){
                    widget.pickerController.closeGiphyPicker();
                  }
                  if(state.extent == 0.55){
                    if(sheetCubit.state) sheetCubit.emit(false);
                  }
                  else if(state.isExpanded){
                    sheetCubit.emit(true);
                  }
                },
              ),
              headerBuilder: (context, _){
                return Container(
                  color: widget.backgroundColor,
                  child: _buildHeader(context),
                );
              },
              customBuilder: (context, controller, sheetState){
                controller.addListener(() {
                  if(controller.offset > 0 && !sheetCubit.state){
                    sheetCubit.emit(true);
                    sheetController.snapToExtent(widget.expandedExtent);
                  }
                });
                if(delegate == null){
                  return Container();
                }
                return SingleChildScrollView(
                  controller: controller,
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height - HEADER_HEIGHT - MediaQuery.of(context).padding.top,
                    child: delegate.build(context)
                  )
                );
              },
            )
        ),
      )
    );
  }

  Widget _buildHeader(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: HEADER_HEIGHT,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 10, left: 16, right: !focusNode.hasFocus ? 16 : 0),
                child: Container(
                  width: focusNode.hasFocus ? width*0.84 - 26 : width - 32,
                  height: 36,
                  child: TextFormField(
                    controller: searchFieldController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixStyle: widget.iconStyle,
                      prefixIcon: widget.icon,
                      prefixIconConstraints: BoxConstraints(
                        maxHeight: 36,
                        minHeight: 36,
                        maxWidth: 30,
                        minWidth: 30
                      ),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: widget.searchColor,
                      hintText: 'Search GIPHY',
                      hintStyle: widget.hiddentTextStyle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                      ),
                    ),
                    onChanged: (value){
                      provider.loadMoreAssetsFromSearching(0, value);
                      valueCubit.emit(value);
                    },
                    onTap: (){
                      setState(() {
                        sheetController.snapToExtent(widget.expandedExtent, duration: Duration(milliseconds: 300));
                      });
                    },
                    onEditingComplete: (){
                      setState(() {
                        focusNode.unfocus();
                      });
                    },
                  ),
                ),
              ),
              focusNode.hasFocus ? GestureDetector(
                child: Padding(
                  padding: EdgeInsets.only(left: 10, right: 16, top: 10),
                  child: Text('Cancel', style: widget.cancelButtonStyle),
                ),
                onTap: (){
                  focusNode.unfocus();
                  valueCubit.emit('');
                },
              ) : Container()
            ],
          ),
        ),
      )
    );
  }
}

  class GiphyPickerController extends ChangeNotifier{

    _GiphyPickerState? _state;

    ///Binds the feed state
    void _bind(_GiphyPickerState bind) => _state = bind;

    void update() => notifyListeners();
    
    String? get gif => _state != null ? _state!.provider.selectedAsset : null;

    /// Get the current state of the [ImagePicker]
    Option? get type => _state != null ? type : null;

    //Disposes of the controller
    @override
    void dispose() {
      _state = null;
      super.dispose();
    }
  }