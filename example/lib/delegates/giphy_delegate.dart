
import 'package:flutter/material.dart';
import 'package:piky/configuration_delegates/giphy_picker_config_delegate.dart';

class ExampleGiphyPickerConfigDelegate extends GiphyPickerConfigDelegate{
  
  ExampleGiphyPickerConfigDelegate({required String apiKey}) : super(apiKey: apiKey);

/*
 
    ___                      _     _           
   / _ \__   _____ _ __ _ __(_) __| | ___  ___ 
  | | | \ \ / / _ \ '__| '__| |/ _` |/ _ \/ __|
  | |_| |\ V /  __/ |  | |  | | (_| |  __/\__ \
   \___/  \_/ \___|_|  |_|  |_|\__,_|\___||___/
                                               
 
*/

  @override
  Widget? loadingIndicator(BuildContext context) {
    return SizedBox(
      height: 1000,
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
          ),
          Text("This is the loading state"),
          SizedBox(
            height: 200,
          ),
          Text("This is the loading state"),
          SizedBox(
            height: 200,
          ),
          Text("This is the loading state"),
          SizedBox(
            height: 200,
          ),
          Text("This is the loading state"),
          SizedBox(
            height: 200,
          ),
          Text("This is the loading state"),
          SizedBox(
            height: 200,
          ),
          Text("This is the loading state"),
          SizedBox(
            height: 200,
          ),
        ],
      ),
    );
  }

  @override
  Widget? loadingTileIndicator(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
      ),
    );
  }

/*
 
   _____                 _            ___                      _     _           
  | ____|_ __ ___  _ __ | |_ _   _   / _ \__   _____ _ __ _ __(_) __| | ___  ___ 
  |  _| | '_ ` _ \| '_ \| __| | | | | | | \ \ / / _ \ '__| '__| |/ _` |/ _ \/ __|
  | |___| | | | | | |_) | |_| |_| | | |_| |\ V /  __/ |  | |  | | (_| |  __/\__ \
  |_____|_| |_| |_| .__/ \__|\__, |  \___/  \_/ \___|_|  |_|  |_|\__,_|\___||___/
                  |_|        |___/                                               
 
*/

  @override
  Widget? connectivityIndicator(BuildContext context, double extent) => null;

  @override
  Widget? headerWrapper(BuildContext context, double borderRadius, Widget child) => null;

  @override
  Widget? notchBuilder(BuildContext context) => null;

  @override
  Widget? overlayBuilder(BuildContext context, int index) => null;

}