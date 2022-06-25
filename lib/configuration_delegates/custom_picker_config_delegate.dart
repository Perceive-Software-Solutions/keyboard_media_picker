
import 'package:flutter/material.dart';

abstract class CustomPickerConfigDelegate {

  /// Custom picker
  Widget? bodyBuilder(BuildContext context, double extent, ScrollController scrollController, bool scrollLocked, double footerHeight);
  Widget? headerBuilder(BuildContext context, Widget spacer, FocusNode focusNode, TextEditingController searchFieldController, double borderRadius);
}