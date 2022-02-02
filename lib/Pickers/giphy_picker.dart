import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fort/fort.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/delegates/giphy_picker_delegate.dart';
import 'package:piky/state/state.dart';
import 'package:piky/util/functions.dart';
import 'package:redux_epics/redux_epics.dart';

import 'imager_picker.dart';


class GiphyPicker extends StatefulWidget {

  /// Giphy Client API Key
  final String apiKey;

  /// Sliding sheet controller
  final SheetController sheetController;

  /// GiphyPicker State
  final GiphyPickerController? controller;

  /// Picker State
  final PickerController? pickerController;

  /// [SlidingSheet] extents
  final double initialExtent;
  final double minExtent;
  final double mediumExtent;
  final double expandedExtent;

  /// Background color when images are not loaded in
  final Color backgroundColor;

  /// Header color displayed behind the search bar 
  final Color headerColor;

  /// Search bar color
  final Color searchColor;

  /// Color of the growable Header
  final Color statusBarPaddingColor;

  /// Cancel button
  final TextStyle cancelButtonStyle;

  /// Search field hint text style
  final TextStyle hiddentTextStyle;

  /// Sty;e for the text
  final TextStyle style;

  /// Search field hint icon style
  final TextStyle iconStyle;

  /// Search field hint icon
  final Icon icon;

  /// Notch for the search bar
  final Widget? notch;

  /// Backdrop Colors
  final Color minBackdropColor;
  final Color maxBackdropColor;

  /// Loading Indicators
  Widget? Function(BuildContext, ScrollController,  double)? loadingIndicator;
  Widget? Function(BuildContext, double)? connectivityIndicator;
  Widget? loadingTileIndicator;

  /// Overlay Widget of the selected asset
  final Widget Function(BuildContext context, int index)? overlayBuilder;

  /// If the giphy picker is in a locked state
  bool isLocked;

  /// Allows the picker to see the sheetstate
  final Function(SheetState state) listener;

  GiphyPicker({
    required Key key,
    required this.apiKey, 
    required this.controller,
    required this.sheetController, 
    required this.listener,
    required this.isLocked,
    this.statusBarPaddingColor = Colors.white,
    this.headerColor = Colors.white,
    this.overlayBuilder,
    this.minExtent = 0.0,
    this.initialExtent = 0.4,
    this.mediumExtent = 0.4,
    this.expandedExtent = 1.0,
    this.pickerController,
    this.notch,
    this.cancelButtonStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
    this.hiddentTextStyle = const TextStyle(fontSize: 14, color: Colors.black),
    this.style = const TextStyle(fontSize: 14),
    this.icon = const Icon(Icons.search, size: 24, color: Colors.black),
    this.iconStyle = const TextStyle(color: Colors.grey),
    this.backgroundColor = Colors.white,
    this.searchColor = Colors.grey,
    this.minBackdropColor = Colors.transparent,
    this.maxBackdropColor = Colors.black,
    this.loadingIndicator,
    this.loadingTileIndicator,
    this.connectivityIndicator
  }) : super(key: key);
  @override
  _GiphyPickerState createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> with SingleTickerProviderStateMixin {

/*
 
      ____                _   
     / ___|___  _ __  ___| |_ 
    | |   / _ \| '_ \/ __| __|
    | |__| (_) | | | \__ \ |_ 
     \____\___/|_| |_|___/\__|
                              
 
*/

  double HEADER_HEIGHT = 60;

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

  /// The current state of the [GiphyPicker]
  PikyOption type = PikyOption.Open;

  /// Primary [FocusNode] for the [TextField] 
  /// Used to see if the [TextField] has focus
  FocusNode focusNode = FocusNode();

  /// Primary [TextEditingController] to get the current value of the [TextField]
  TextEditingController searchFieldController = TextEditingController();

  /// The primary [Cubit] for the headerBuilder inside [SlidingSheet]
  ConcreteCubit<bool> sheetCubit = ConcreteCubit<bool>(false);

  /// Primary [Cubit] to track the textfields current value
  String searchValue = '';

  /// The [ScrollController] for the giphy preview grid
  ScrollController giphyScrollController = ScrollController();

  /// Controls the animation of the backdrop color reletive the the [SlidingSheet]
  late AnimationController animationController;

  /// Animates the color from min extent to medium extent
  late Animation<Color?> colorTween;

  /// If the sliding sheet is currently snapping
  bool snapping = false;

  /// If assets are finished loading
  bool assetsLoadingComplete = false;

  /// If the search is currently queued up
  bool queued = true;

  /// Tracks the sheet extent
  late ConcreteCubit<double> sheetExtent = ConcreteCubit<double>(widget.initialExtent);

  late Store<GiphyState> store;

  //Adds a listener to the scroll position of the staggered grid view
  @override
  void initState() {
    super.initState();

    store = Store<GiphyState>(
      giphyStateReducer,
      initialState: GiphyState.initial(widget.apiKey),
    );

    delegate = GiphyPickerPickerBuilderDelegate(
      store,
      giphyScrollController, 
      widget.controller,
      sheetExtent,
      sheetCubit,
      widget.loadingIndicator,
      widget.connectivityIndicator,
      widget.loadingTileIndicator,
      mediumExtent: widget.mediumExtent,
      overlayBuilder: widget.overlayBuilder
    );

    //Initiate animation
    animationController = AnimationController(
      vsync: this,
      value: widget.initialExtent/widget.mediumExtent,
      duration: Duration(milliseconds: 0)
    );
    colorTween = ColorTween(begin: widget.minBackdropColor, end: widget.maxBackdropColor).animate(animationController);

    // Initiate Listeners
    initiateScrollListener(giphyScrollController);

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



  // void searchGiphy(String value){
  //   searchValue = value;
  //   if(assetsLoadingComplete == false){
  //     queued = true;
  //   }
  //   else if(assetsLoadingComplete){
  //     provider.loadMoreAssetsFromSearching(0, searchValue);
  //     queued = false;
  //   }
  // }

  // void initiateSearchListener(){
  //   provider.addListener(() { 
  //     assetsLoadingComplete = provider.assetsLoadingComplete;
  //   });
  //   if(queued){
  //     searchGiphy(searchValue);
  //   }
  // }

  void unSelectAsset(){
    store.dispatch(unSelectGif());
    widget.controller?.update();
  }

  /// Matches the widget.sheetController state to the scroll offset of the feed
  void initiateScrollListener(ScrollController scrollController){
    scrollController.addListener(() {
      if(scrollController.offset <= -50 && widget.sheetController.state!.extent != widget.minExtent && !snapping){
        if(widget.sheetController.state!.extent == widget.expandedExtent){
          snapping = true;
          Future.delayed(Duration(milliseconds: 0), () {
            widget.sheetController.snapToExtent(widget.mediumExtent, duration: Duration(milliseconds: 300));
            focusNode.unfocus();
            sheetCubit.emit(false);
            scrollController.jumpTo(0.0);
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          });
        }
        else if(widget.sheetController.state!.extent == widget.mediumExtent){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.sheetController.snapToExtent(widget.minExtent, duration: Duration(milliseconds: 300));
            focusNode.unfocus();
            sheetCubit.emit(false);
            scrollController.jumpTo(0.0);
          });
          Future.delayed(Duration(milliseconds: 300)).then((value) => {
            snapping = false
          });
        }
      }
    });
  }

  void sheetListener(SheetState state){
    if(state.extent<= widget.mediumExtent && (state.extent - widget.minExtent) >= 0){
      animationController.animateTo((state.extent - widget.minExtent) / widget.mediumExtent);
    }
    sheetExtent.emit(state.extent);
    if(state.extent <= widget.initialExtent/3 && widget.isLocked){
      widget.sheetController.snapToExtent(widget.initialExtent);
    }
    widget.listener(state);
  }

  @override
  Widget build(BuildContext context) {
    var statusBarHeight = MediaQueryData.fromWindow(window).padding.top;
    return StoreProvider(
      store: store,
      child: BlocProvider(
        create: (context) => sheetCubit,
        child: BlocBuilder<ConcreteCubit<bool>, bool>(
          bloc: sheetCubit,
          buildWhen: (o, n) => o != n,
          builder: (context, sheetCubitState) {
            return BlocBuilder<ConcreteCubit<double>, double>(
              bloc: sheetExtent,
              builder: (context, extent) {
                double topExtentValue = Functions.animateOver(extent, percent: 0.9);
                return SlidingSheet(
                    controller: widget.sheetController,
                    isBackdropInteractable: false,
                    duration: Duration(milliseconds: 300),
                    cornerRadius: 32,
                    cornerRadiusWhenExpanded: 0,
                    backdropColor: extent > widget.initialExtent ? colorTween.value : null,
                    listener: sheetListener,
                    snapSpec: SnapSpec(
                      initialSnap: widget.minExtent,
                      snappings: [widget.minExtent, widget.initialExtent, widget.mediumExtent, widget.expandedExtent],
                      onSnap: (state, _){
                        if(state.extent == widget.mediumExtent){
                          if(sheetCubitState) sheetCubit.emit(false);
                        }
                        else if(state.isExpanded){
                          sheetCubit.emit(true);
                        }
                      },
                    ),
                    headerBuilder: (context, _){
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(height: lerpDouble(0, statusBarHeight, topExtentValue)!, color: widget.statusBarPaddingColor,),
                          Container(
                            color: widget.headerColor,
                            child: _buildHeader(context),
                          ),
                        ],
                      );
                    },
                    customBuilder: (context, controller, sheetState){
                      controller.addListener(() {
                        if(controller.offset > 0 && !sheetCubitState){
                          sheetCubit.emit(true);
                          widget.sheetController.snapToExtent(widget.expandedExtent);
                        }
                      });
                      if(delegate == null){
                        return Container();
                      }
                      return SingleChildScrollView(
                        controller: controller,
                        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: delegate.build(context)
                      );
                    },
                  );
              }
            );
          }
        )
      ),
    );
  }

  Widget _buildHeader(BuildContext context){

    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: HEADER_HEIGHT,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: widget.notch ?? Container(
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
                        style: widget.style,
                        decoration: InputDecoration(
                          prefixStyle: widget.iconStyle,
                          prefixIcon: widget.icon,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: widget.searchColor,
                          hintText: 'Search GIPHY',
                          hintStyle: widget.hiddentTextStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none
                          ),
                        ),
                        onChanged: (value){
                          store.dispatch(CancelSearchAction());
                          store.dispatch(LoadAssetsFromSearching(0, value, store));
                        },
                        onTap: (){
                          setState(() {
                            widget.sheetController.snapToExtent(widget.expandedExtent, duration: Duration(milliseconds: 300));
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
                      padding: EdgeInsets.only(left: 10, right: 16, top: 1),
                      child: Text('Cancel', style: widget.cancelButtonStyle),
                    ),
                    onTap: (){
                      focusNode.unfocus();
                      searchValue = '';
                    },
                  ) : Container()
                ],
              ),
            ),
          ),
        ],
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