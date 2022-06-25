
import 'package:flutter/material.dart';

abstract class GiphyPickerConfigDelegate {

  final TextStyle cancelButtonStyle;
  final TextStyle hiddenTextStyle;
  final TextStyle style;
  final Icon icon;
  final TextStyle iconStyle;
  final Color searchColor;
  final Color statusBarColor;
  final Color backgroundColor;

  ///Giphy API Key
  final String apiKey;

  GiphyPickerConfigDelegate({
    required this.apiKey, 
    this.cancelButtonStyle = const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
    this.hiddenTextStyle = const TextStyle(fontSize: 14, color: Colors.black),
    this.style = const TextStyle(fontSize: 14),
    this.icon = const Icon(Icons.search, size: 24, color: Colors.black),
    this.iconStyle = const TextStyle(color: Colors.grey),
    this.searchColor = Colors.grey, 
    this.statusBarColor = Colors.white,
    this.backgroundColor = Colors.white,
  });

  /// Builds a wrapper around the gif header and provides the border radius
  Widget? headerWrapper(BuildContext context, double borderRadius, Widget child);
  
  /// Overlay Widget of the selected asset
  Widget? overlayBuilder(BuildContext context, int index);

  ///Loading Indicator for the Gif viewer when no Gifs are loaded
  Widget? loadingIndicator(BuildContext context);

  ///Connectivity Indiciator when there are no gifs and not connected to the internet
  Widget? connectivityIndicator(BuildContext context, double extent);

  ///Loading Indicator for the Gif viewer when Gifs are currently beiing rendered
  Widget? loadingTileIndicator(BuildContext context);

  /// Builds the notch on the sliding sheet
  Widget? notchBuilder(BuildContext context);
}