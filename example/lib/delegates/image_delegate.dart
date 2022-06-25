
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:piky/piky.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ExampleImagePickerConfigDelegate extends ImagePickerConfigDelegate{

  final ScrollController scrollController;

  ExampleImagePickerConfigDelegate({
    required this.scrollController
  });

/*
 
   _   _      _                     
  | | | | ___| |_ __   ___ _ __ ___ 
  | |_| |/ _ \ | '_ \ / _ \ '__/ __|
  |  _  |  __/ | |_) |  __/ |  \__ \
  |_| |_|\___|_| .__/ \___|_|  |___/
               |_|                  
 
*/

  Widget itemBuilder(int index){
    return AnimationConfiguration.staggeredGrid(
      columnCount: 4,
      position: index,
      duration: const Duration(milliseconds: 375),
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Container(
            height: 200,
            width: 200,
            color: Colors.grey.withOpacity(0.4),
          ),
        )
      )
    );
  }
  
  Widget tileItemBuilder(BuildContext context, AssetPathEntity? assetPathEntity, Uint8List? thumbNail, dynamic Function(AssetPathEntity) onTap){
    return GestureDetector(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: thumbnailItemBuilder(context, thumbNail),
              ),
              Container(
                height: 36,
                child: assetPathEntity != null ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(assetPathEntity.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(assetPathEntity.assetCount.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.4)))
                  ],
                ) : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      onTap: assetPathEntity != null ? (){
        onTap(assetPathEntity);
      } : (){},
    );
  }
  
  /// Builds the apping thumbnail
  Widget thumbnailItemBuilder(
    BuildContext context, Uint8List? thumbNail){
      Widget assetItemBuilder(){
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            width: 36,
            child: thumbNail != null ? Image.memory(
              thumbNail,
              filterQuality: FilterQuality.high,
              fit: BoxFit.fitWidth,
            ) : Container()
          ),
        );
      }

    if(thumbNail != null)
      return assetItemBuilder();
    else
      return SizedBox.shrink();
    
  }

/*
 
    ___                      _     _           
   / _ \__   _____ _ __ _ __(_) __| | ___  ___ 
  | | | \ \ / / _ \ '__| '__| |/ _` |/ _ \/ __|
  | |_| |\ V /  __/ |  | |  | | (_| |  __/\__ \
   \___/  \_/ \___|_|  |_|  |_|\__,_|\___||___/
                                               
 
*/

  @override
  Widget albumMenuBuilder(BuildContext context, String selectedAlbum, Map<String, Tuple2<AssetPathEntity, Uint8List?>?> assets, ScrollController controller, bool scrollLock, double footerHeight, Function(AssetPathEntity asset) onSelect) {
    
    assets.removeWhere((key, value) => value == null);

    AssetPathEntity? recents; 
    AssetPathEntity? favorites;
    if(assets.isNotEmpty){
      try{
        recents = assets.values.firstWhere((element) => element?.item1.name == (Platform.isIOS ? "Recents" : "Recent"))?.item1;
        favorites = assets.values.firstWhere((element) => element?.item1.name == (Platform.isIOS ? "Favorites" : "Camera"))?.item1;
      }catch(e){}
    }
    List<Widget> children = [];
    assets.forEach((key, value) { 
      if(value?.item1.name != (Platform.isIOS ? "Recents" : "Recent") && value?.item1.name != (Platform.isIOS ? "Favorites" : "Camera"))
        children.add(tileItemBuilder(context, value?.item1, value?.item2, onSelect));
    });
    Widget _cupertinoList(){
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Pick an album', style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.4))),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              color: Colors.white,
              height: 124,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tileItemBuilder(context, recents, assets.values.firstWhere((element) => element?.item1 == recents)?.item2, onSelect),
                  Padding(
                    padding: const EdgeInsets.only(left: 62, top: 10, bottom: 10),
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.4),
                    ),
                  ),
                  tileItemBuilder(context, favorites, assets.values.firstWhere((element) => element?.item1 == favorites)?.item2, onSelect),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 8),
            child: Text('My Albums', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  children: [
                    for(int i = 0; i < children.length; i++)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          children[i],
                          i != children.length - 1 ? Padding(
                            padding: const EdgeInsets.only(left: 62, top: 10, bottom: 10),
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.4),
                            ),
                          ) : SizedBox.shrink()
                        ],
                      ),
                  ]
                ),
              ),
            ),
          )
        ],
      );
    }

    return _cupertinoList();
  }

  @override
  Widget headerBuilder(BuildContext context, Widget spacer, String path, bool albumMode, double borderRadius) {
    return Column(
      children: [
        spacer,
        Container(
          key: Key("Picker-Max-View"),
          height: 59.75,
          color: Colors.grey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Text(path, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Icon(!albumMode ? Icons.arrow_downward : Icons.arrow_upward, size: 16)
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget? imageLoadingIndicator(BuildContext context) {
    return CustomScrollView(
      scrollDirection: Axis.vertical,
      physics: NeverScrollableScrollPhysics(),
      controller: scrollController,
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate((_, int index) => Builder(
            builder: (BuildContext c){
              return itemBuilder(index);
              },
            ),
            childCount: 100,
          ), 
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1
          )
        ),
      ],
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
  Widget? albumLoadingIndicator(BuildContext context) => null;

  @override
  Widget? lockOverlayBuilder(BuildContext context, int index) => null;

  @override
  Widget? overlayBuilder(BuildContext context, int index) => null;

  @override
  Widget? tileLoadingIndicator(BuildContext context) => null;

  @override
  Widget? videoIndicator(BuildContext context, String duration) => null;
  
}