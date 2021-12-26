import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/util/functions.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class CustomPicker extends StatefulWidget {

  /// Sliding sheet controller
  final SheetController sheetController;

  /// Picker controller
  final PickerController? pickerController;

  /// Sheet sizing extents
  final double initialExtent;
  final double expandedExtent;
  final double mediumExtent;
  final double minExtent;

  /// Color of the growable Header
  final Color statusBarPaddingColor;

  /// Backdrop Colors
  final Color minBackdropColor;
  final Color maxBackdropColor;

  /// Custom picker body builder
  final Widget Function(BuildContext context, double extent, ScrollController scrollController, SheetState state) customBodyBuilder;

  final Widget Function(BuildContext context, SheetController sheetController, FocusNode focusNode, TextEditingController searchFieldController) headerBuilder;

  /// Allows the picker to see the sheetstate
  final Function(SheetState state) listener;

  final bool isLocked;
  
  const CustomPicker({ 
    Key? key, 
    required this.sheetController,
    required this.pickerController,
    required this.customBodyBuilder,
    required this.headerBuilder,
    required this.listener,
    this.initialExtent = 0.55,
    this.minExtent = 0.2,
    this.mediumExtent = 0.55,
    this.expandedExtent = 1.0,
    this.statusBarPaddingColor = Colors.white,
    this.minBackdropColor = Colors.transparent,
    this.maxBackdropColor = Colors.black, 
    this.isLocked = false
  }) : super(key: key);

  @override
  _CustomPickerState createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker> with SingleTickerProviderStateMixin {

  /// Controls the animation of the backdrop color reletive the the [SlidingSheet]
  late AnimationController animationController;

  /// Animates the color from min extent to medium extent
  late Animation<Color?> colorTween;

  /// Sheet cubit state
  late ConcreteCubit<double> sheetExtent = ConcreteCubit<double>(widget.initialExtent);

  /// Scroll offset of the custom sheet
  ScrollController scrollController = ScrollController();

  /// If the sheet is currently snapping
  bool snapping = false;

  FocusNode focusNode = FocusNode();

  TextEditingController searchFieldController = TextEditingController();

  @override
  void initState(){
    super.initState();
    //Initiate animation
    animationController = AnimationController(
      vsync: this,
      value: widget.initialExtent/widget.mediumExtent,
      duration: Duration(milliseconds: 0)
    );
    colorTween = ColorTween(begin: widget.minBackdropColor, end: widget.maxBackdropColor).animate(animationController);

    initiateListener(scrollController);
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

  void initiateListener(ScrollController scrollController){
    scrollController.addListener(() {
      if(scrollController.offset <= -50 && widget.sheetController.state!.extent != widget.minExtent && !snapping){
        if(widget.sheetController.state!.extent == widget.expandedExtent){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.sheetController.snapToExtent(widget.mediumExtent, duration: Duration(milliseconds: 300));
            focusNode.unfocus();
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
          });
          Future.delayed(Duration(milliseconds: 300)).then((value) => {
            snapping = false
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    var statusBarHeight = MediaQueryData.fromWindow(window).padding.top;

    return BlocBuilder<ConcreteCubit<double>, double>(
      bloc: sheetExtent,
      builder: (context, extent) {
        double topExtentValue = Functions.animateOver(extent, percent: 0.9);
        return SlidingSheet(
          controller: widget.sheetController,
          isBackdropInteractable: false,
          duration: Duration(milliseconds: 300),
          cornerRadius: 32,
          cornerRadiusOnFullscreen: 0,
          backdropColor: extent > widget.initialExtent ? colorTween.value : null,
          listener: sheetListener,
          snapSpec: SnapSpec(
            initialSnap: widget.minExtent,
            snappings: [widget.minExtent, widget.initialExtent, widget.mediumExtent, widget.expandedExtent],
            onSnap: (state, _){
              // if(state.isCollapsed && widget.minExtent == 0){
              //   // ~~~~~ Change ~~~~~
              //   widget.pickerController!.closeImagePicker();
              // }
              if(state.extent == widget.mediumExtent){
                // if(sheetCubit.state) sheetCubit.emit(false);
                // if(pageCubit.state) pageCubit.emit(false);
              }
              else if(state.isExpanded){
                // if(!sheetCubit.state) sheetCubit.emit(true);
              }
            },
          ),
          headerBuilder: (context, state){
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: lerpDouble(0, statusBarHeight, topExtentValue)!, color: widget.statusBarPaddingColor,),
                widget.headerBuilder(context, widget.sheetController, focusNode, searchFieldController),
              ],
            );
          },
          customBuilder: (context, controller, sheetState){
            return Container(

              child: SingleChildScrollView(
                controller: controller,
                physics: AlwaysScrollableScrollPhysics(),
                child: widget.customBodyBuilder(context, extent, scrollController, sheetState),
              ),
            );
          },
        );
      }
    );
  }
}

class CustomPickerController extends ChangeNotifier {
  _CustomPickerState? _state;

  CustomPickerController();

  /// Bind to state
  void _bind(_CustomPickerState bind) => _state = bind;

  /// Notify listeners
  void update() => _state != null ? notifyListeners() : null;

  /// Get the current state of the [ImagePicker]
  Option? get type => _state != null ? type : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
  }
}