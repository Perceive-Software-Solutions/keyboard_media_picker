import 'package:flutter/material.dart';
import 'package:piky/piky.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


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
        setState(() {
          imageAssets.clear();
          gifAsset = value!;
        });
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

  @override
  Widget build(BuildContext context) {
    return Picker(
      apiKey: 'OI5ZOVhKTzf16it9QmrOZGSGdRudnk4H',
      controller: pickerController,
      backgroundColor: Colors.white,
      initialExtent: 0.55,
      minExtent: 0.0,
      mediumExtent: 0.55,
      expandedExtent: 1.0,
      minBackdropColor: Colors.transparent,
      maxBackdropColor: Colors.black.withOpacity(0.4),
      imageLoadingIndicator: imageLoadingIndicator(),
      imageHeaderBuilder: (String path, bool state){
        return imageHeaderBuilder(path, state);
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Spacer(),
              Container(
                child: Center(
                  child: Text('Picker', style: TextStyle(fontSize: 40),),
                ),
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
                      pickerController.openImagePicker(imageCount: 5);
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
                      pickerController.openGiphyPicker();
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
    );

  }
}
