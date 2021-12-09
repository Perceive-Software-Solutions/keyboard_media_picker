import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:piky/piky.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(key: Key('MyHomePage'), title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required Key key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late PickerController pickerController;

  List<AssetEntity> imageAssets = <AssetEntity>[];

  String? gifAsset;

  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    pickerController = PickerController(
      onGiphyReceived: (value){
        // setState(() {
        //   imageAssets.clear();
        //   gifAsset = value!;
        // });
      },
      onImageReceived: (value){
        setState(() {
          gifAsset = null;
          imageAssets = value!;
        });
      } 
    );
  }

  /// Item widgets when the thumb data load failed.
  Widget failedItemBuilder(BuildContext context) {
    return Center(
      child: Container()
    );
  }

  /// Displays an individual asset
  Widget _displayImageAssets(AssetEntity imageAsset){

    int defaultGridThumbSize = 200;

    final AssetEntityImageProvider imageProvider = AssetEntityImageProvider(
      imageAsset,
      isOriginal: false,
      thumbSize: <int>[defaultGridThumbSize, defaultGridThumbSize],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 300,
        minHeight: 125, 
      ),
      child: AssetEntityGridItemBuilder(
        image: imageProvider,
        failedItemBuilder: failedItemBuilder,
      ),
    );
  }

  /// Displays the selected assets inside a wrap
  Widget _displayWrap(List<AssetEntity> imageAssets){
    return Wrap(
      children: [
        for(AssetEntity asset in imageAssets)
          _displayImageAssets(asset)
      ],
    );
  }

  /// Displays an individual gif using [NetworkImage]
  Widget _displayGifAsset(BuildContext context, String gif){

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 200,
        minHeight: 125,
        maxWidth: 200
      ),
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey,
        image: DecorationImage(
          image: NetworkImage(gif),
            fit: BoxFit.cover
          ),
        ),
      ),
    );
  }

  Widget imageHeaderBuilder(String path, bool state){
    return Container(
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
          Icon(!state ? Icons.arrow_downward : Icons.arrow_upward, size: 16)
        ],
      ),
    );
  }

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

  Widget? gifTileLoadingIndicator(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(12)
      ),
    );
  }

  Widget gifLoadingIndicator(BuildContext context, bool sheetCubitState){
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    List<double> ratios = [];
    for(int i = 0; i < 20; i++){
      ratios.add(Random().nextDouble() + 0.5);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: !sheetCubitState ? height*0.55 - 60 : height - 65 - MediaQuery.of(context).padding.top,
          child: StaggeredGridView.countBuilder(
            controller: ScrollController(),
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            padding: EdgeInsets.only(left: 5, right: 5, bottom: 5),
            itemCount: 20,
            scrollDirection: !sheetCubitState ? Axis.horizontal : Axis.vertical,
            crossAxisCount: 2,
            itemBuilder: (context, i){
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12)
                ),
              );
            },
            staggeredTileBuilder: (int index) => StaggeredTile.extent(1, !sheetCubitState ? (height*0.165)*ratios[index] - 15 : (width*0.5)/ratios[index] - 15),
          ),
        ),
      ],
    );
  }

  Widget imageLoadingIndicator(){
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

  Widget albumMenuBuilder(Map<AssetPathEntity, Uint8List?> pathEntityList, ScrollController controller, dynamic Function(AssetPathEntity) onTap){

    pathEntityList.removeWhere((key, value) => value == null);

    AssetPathEntity? recents; 
    AssetPathEntity? favorites;
    if(pathEntityList.isNotEmpty){
      try{
        recents = pathEntityList.keys.firstWhere((element) => element.name == (Platform.isIOS ? "Recents" : "Recent"));
        favorites = pathEntityList.keys.firstWhere((element) => element.name == (Platform.isIOS ? "Favorites" : "Camera"));
      }catch(e){}
    }
    List<Widget> children = [];
    pathEntityList.forEach((key, value) { 
      if(key.name != (Platform.isIOS ? "Recents" : "Recent") && key.name != (Platform.isIOS ? "Favorites" : "Camera"))
        children.add(tileItemBuilder(context, key, value, onTap));
    });
    Widget _cupertinoList(Map<AssetPathEntity, Uint8List?> assets){
      return ListView(
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
                  tileItemBuilder(context, recents, pathEntityList[recents], onTap),
                  Padding(
                    padding: const EdgeInsets.only(left: 62, top: 10, bottom: 10),
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.4),
                    ),
                  ),
                  tileItemBuilder(context, favorites, pathEntityList[favorites], onTap)
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
                      )
                  ]
                ),
              ),
            ),
          )
        ],
      );
    }

    return _cupertinoList(pathEntityList);
  }

  @override
  Widget build(BuildContext context) {
    return Picker(
      apiKey: 'oJwtzrKQKhVvDfUShkeRV7Lb88CllYgn',
      initialValue: PickerType.ImagePicker,
      controller: pickerController,
      backgroundColor: Colors.white,
      initialExtent: 0.2,
      minExtent: 0.2,
      mediumExtent: 0.55,
      expandedExtent: 1.0,
      minBackdropColor: Colors.transparent,
      maxBackdropColor: Colors.black.withOpacity(0.4),
      imageLoadingIndicator: imageLoadingIndicator(),
      gifLoadingTileIndicator: gifTileLoadingIndicator(),
      imageHeaderBuilder: imageHeaderBuilder,
      albumMenuBuilder: albumMenuBuilder,
      gifLoadingIndicator: gifLoadingIndicator,
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          floatingActionButton: GestureDetector(
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.blue
              ),
            ),
            onTap: (){
              pickerController.closePicker();
            },
          ),
          body: Column(
            children: [
              Spacer(),
              Container(
                child: Center(
                  child: Text('Picker', style: TextStyle(fontSize: 40),),
                ),
              ),
              Spacer(),
              GestureDetector(
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 1.5)),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(
                      Icons.expand,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                onTap: () async {
                  if(pickerController.isOpen){
                    pickerController.closePicker();
                  }
                  else{
                    pickerController.openPicker();
                  }
                },
              ),
              Spacer(),
              Row(
                children: [
                    Spacer(),
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5)),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 34,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if(pickerController.isOpen){
                        pickerController.openImagePicker(imageCount: 5, overrideLock: true);
                      }
                      else{
                        pickerController.openImagePicker(imageCount: 5, overrideLock: false);
                      }
                    },
                  ),
                  Spacer(),
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5)),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 34,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if(pickerController.isOpen){
                        pickerController.openGiphyPicker(true);
                      }
                      else{
                        pickerController.openGiphyPicker(false);
                      }
                    },
                  ),
                  Spacer(),
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5)),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 34,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if(pickerController.isOpen){
                        pickerController.openCustomPicker(true);
                      }
                      else{
                        pickerController.openCustomPicker(false);
                      }
                    },
                  ),
                  Spacer()
                ],
              ),
              Spacer(),
              imageAssets.isNotEmpty ? 
              _displayWrap(imageAssets) :
              gifAsset != "" && gifAsset != null ?
              _displayGifAsset(context, gifAsset!) :
              Container(),
              Spacer()
            ],
          )
        ),
        customBodyBuilder: (context, controller, state){
          return Text("This is Custom");
        },
        headerBuilder: (context, state){
          return Text("This is custom header");
        },
        customStatusBarColor: Colors.white,
    );

  }
}

class ConcreteCubit<T> extends Cubit<T> {
  ConcreteCubit(T initialState) : super(initialState);
}
