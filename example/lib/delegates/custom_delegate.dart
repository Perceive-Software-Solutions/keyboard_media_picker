
import 'package:flutter/material.dart';
import 'package:piky/configuration_delegates/custom_picker_config_delegate.dart';

class ExampleCustomPickerConfigDelegate extends CustomPickerConfigDelegate{


  @override
  Widget? bodyBuilder(BuildContext context, double extent, ScrollController scrollController, bool scrollLocked, double footerHeight) {
    return Text("This is Custom");
  }

  @override
  Widget? headerBuilder(BuildContext context, Widget spacer, FocusNode focusNode, TextEditingController searchFieldController, double borderRadius) {
    return Text("This is custom header");
  }

}