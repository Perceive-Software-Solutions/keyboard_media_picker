import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fort/fort.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/configuration_delegates/giphy_picker_config_delegate.dart';
import 'package:piky/delegates/giphy_picker_delegate.dart';
import 'package:piky/state/state.dart';
import 'package:piky/util/functions.dart';
import 'package:redux_epics/redux_epics.dart';

import 'imager_picker.dart';


class GiphyPicker extends StatefulWidget {

  /// Sliding sheet controller
  final PerceiveSlidableController sheetController;

  /// GiphyPicker State
  final GiphyPickerController? controller;

  /// [SlidingSheet] extents
  final double initialExtent;
  final double minExtent;
  final double mediumExtent;
  final double expandedExtent;

  /// The delegate for this
  final GiphyPickerConfigDelegate delegate;

  /// If the giphy picker is in a locked state
  final ConcreteCubit<PickerType?> openType;

  /// Allows the picker to see the sheetstate
  final Function(double extent) listener;

  const GiphyPicker({
    required Key key,
    required this.delegate, 
    required this.controller,
    required this.sheetController, 
    required this.listener,
    required this.openType,
    this.minExtent = 0.0,
    this.initialExtent = 0.4,
    this.mediumExtent = 0.4,
    this.expandedExtent = 1.0,
  }) : super(key: key);
  @override
  _GiphyPickerState createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> {

/*
 
     ____  _        _       
    / ___|| |_ __ _| |_ ___ 
    \___ \| __/ _` | __/ _ \
     ___) | || (_| | ||  __/
    |____/ \__\__,_|\__\___|
                            
 
*/

  /// Primary [FocusNode] for the [TextField] 
  /// Used to see if the [TextField] has focus
  late final FocusNode focusNode = FocusNode()..addListener(() {
    //Expands the sheet if the focus node has focus
    if(focusNode.hasFocus && widget.sheetController.extent != widget.expandedExtent){
      widget.sheetController.snapTo(widget.expandedExtent, duration: Duration(milliseconds: 300));
    }
  });

  /// Primary [TextEditingController] to get the current value of the [TextField]
  late final TextEditingController searchFieldController = TextEditingController()..addListener(() {
    //When the text is edited, a search is run
    store.dispatch(CancelSearchAction());
    store.dispatch(LoadAssetsFromSearching(0, searchFieldController.text, store));
  });

  /// The [ScrollController] for the giphy preview grid
  ScrollController giphyScrollController = ScrollController();

  /// The store for the giphy state
  late final Tower<GiphyState> store = Tower<GiphyState>(
    giphyStateReducer,
    initialState: GiphyState.initial(widget.delegate.apiKey),
    middleware: [EpicMiddleware<GiphyState>(giphySearchEpic)],
  );

  //Adds a listener to the scroll position of the staggered grid view
  @override
  void initState() {
    super.initState();

    checkConnectivity();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none){
        store.dispatch(ChangeConnectivityStatus(false));
      }
      else{
        store.dispatch(ChangeConnectivityStatus(true));
        reload();
      }
    });

    store.dispatch(hydrateAction());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller?._bind(this);
  }

  void checkConnectivity() async {
    store.dispatch(ChangeConnectivityStatus((await Connectivity().checkConnectivity()) != ConnectivityResult.none));
  }

  /// Add asset to the giphy provider
  void addAsset(String gif){
    store.dispatch(SetSelectedAsset(gif));
  }

  Future<void> reload() async {
    await store.dispatch(hydrateAction());
  }

  void unSelectAsset(){
    store.dispatch(unSelectGif());
    widget.controller?.update();
  }

  void sheetListener(double extent){
    if(extent <= widget.initialExtent/3 && widget.openType.state == PickerType.GiphyPickerView){
      if(extent == 0){
        Future.delayed(Duration(milliseconds: 100)).then((value){
          widget.sheetController.snapTo(widget.initialExtent);
        });
      }
      else{
        widget.sheetController.snapTo(widget.initialExtent);
      }
    }
    widget.listener(extent);
  }

  
  Widget _buildHeader(BuildContext context, Widget spacer, double borderRadius){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    Widget header = Column(
      children: [
        spacer,
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: widget.delegate.notchBuilder(context) ?? Container(
            width: 20,
            height: 4,
            color: Colors.grey,
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 16, right: !focusNode.hasFocus ? 16 : 0),
                  child: Container(
                    width: focusNode.hasFocus ? width - 91 : width - 32,
                    height: 36,
                    child: TextFormField(
                      controller: searchFieldController,
                      focusNode: focusNode,
                      style: widget.delegate.style,
                      decoration: InputDecoration(
                        prefixStyle: widget.delegate.iconStyle,
                        prefixIcon: widget.delegate.icon,
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: widget.delegate.searchColor,
                        hintText: 'Search GIPHY',
                        hintStyle: widget.delegate.hiddenTextStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none
                        ),
                      ),
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
                    padding: EdgeInsets.only(left: 10, right: 16, top: 1),
                    child: Text('Cancel', style: widget.delegate.cancelButtonStyle),
                  ),
                  onTap: (){
                    focusNode.unfocus();
                    searchFieldController.clear();
                  },
                ) : Container()
              ],
            ),
          ),
        ),
      ],
    );

    final Widget? delegateHeader = widget.delegate.headerWrapper(context, borderRadius, header);
    if(delegateHeader != null){
      header = delegateHeader;
    }

    return header;
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: PerceiveSlidable(
        controller: widget.sheetController,
        backgroundColor: widget.delegate.backgroundColor,
        staticSheet: true,
        closeOnBackdropTap: false,
        isBackgroundIntractable: false,
        doesPop: false,
        additionalSnappings: [widget.initialExtent],
        initialExtent: 0,
        minExtent: widget.minExtent,
        mediumExtent: widget.mediumExtent,
        expandedExtent: widget.expandedExtent,
        extentListener: sheetListener,
        delegate: GiphyPickerPickerBuilderDelegate(
          store,
          widget.delegate,
          widget.controller,
          _buildHeader,
          mediumExtent: widget.mediumExtent,
        )
      ),
    );
  }

}

  class GiphyPickerController extends ChangeNotifier{

    _GiphyPickerState? _state;

    ///Binds the feed state
    void _bind(_GiphyPickerState bind) => _state = bind;

    void update() => notifyListeners();
    
    /// Get individual Gif asset
    String? get gif => _state != null ? _state!.store.state.selectedAsset : null;

    /// Get the current state of the [ImagePicker]
    PikyOption? get type => _state != null ? type : null;

    /// Clear the selected Gifs
    void clearGif() => _state != null ? _state!.unSelectAsset() : null;

    void addAsset(String gif) => _state != null ? _state!.addAsset(gif) : null;

    void reload() => _state != null ? _state!.reload() : null;

    //Disposes of the controller
    @override
    void dispose() {
      _state = null;
      super.dispose();
    }
  }