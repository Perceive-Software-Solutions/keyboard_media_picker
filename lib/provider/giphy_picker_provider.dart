import 'package:flutter/foundation.dart';
import 'package:giphy_get/giphy_get.dart';

class GiphyPickerProvider extends ChangeNotifier {
  GiphyPickerProvider({
    this.pageSize = 40,
    String? selectedAsset,
    Duration routeDuration = const Duration(milliseconds: 300),
    required String apiKey
  }) {
    {
      Future<void>.delayed(routeDuration).then(
        (dynamic _) async {
          /// Initialize API Client
          initializeGiphyClient(apiKey);
          /// Load initial state
          await loadMoreAssetsFromTrending(0);
        },
      );
    }
  }

  /// Assets should be loaded per page
  /// 
  /// User `null` to display all assets into a single grid
  final int pageSize;

  /// Stores a reference to giphy API
  late GiphyClient client;

  /// Stores the current selected Asset
  String _selectedAsset = '';

  /// 
  bool assetsLoadingComplete = true;

  /// Get [_selectedAsset]
  String get selectedAsset => _selectedAsset;

  /// Set [_selectedAsset]
  set selectedAsset(String value) {
    _selectedAsset = value;
    notifyListeners();
  }

  /// Get [_displayAssets.isNotEmpty]
  bool get hasAssetsToDisplay => _displayAssets.isNotEmpty;

  /// Total count for assets
  int _totalAssetsCount = 0;

  /// Get [_totalAssetsCount]
  int get totalAssetsCount => _totalAssetsCount;

  /// Set [_totalAssetsCount]
  set totalAssetsCount(int value){
    if(value == _totalAssetsCount){
      return;
    }
    _totalAssetsCount = value;
    notifyListeners();
  }

  /// [Map] for all giphy assets
  /// 
  /// Using [Map] in order to store how the assets should be displayed
  /// in the staggered grid view
  Map<String, double> _displayAssets = <String, double>{};

  /// Get [_displayAssets]
  Map<String, double> get displayAssets => _displayAssets;

  /// Set [_displayAssets]
  set displayAssets(Map<String, double> value){
    if(value == _displayAssets){
      return;
    }
    _displayAssets = Map<String, double>.from(value);
    notifyListeners();
  }

  void initializeGiphyClient(String apiKey){
    client = GiphyClient(apiKey: apiKey, randomId: '154');
  }

  /// Clears the [_displayAssets] and the [_totalAssetsCount]
  void reset(){
    totalAssetsCount = 0;
    displayAssets = <String, double>{};
  }

   /// Select asset.
  void selectAsset(String asset) {
    if (asset == '' || selectedAsset == asset) {
      return;
    }
    if(selectedAsset != ''){
      unSelectAsset();
    }
    selectedAsset = asset;
  }

  /// Un-select asset.
  void unSelectAsset() {
    selectedAsset = '';
  }

  /// Load more assets from trending state
  Future<void> loadMoreAssetsFromTrending(int offset) async {
    assetsLoadingComplete = false;
    notifyListeners();
    GiphyCollection collection = await client.trending(offset: offset, limit: pageSize).then((value) {
      return value;
    });
    List<GiphyGif>? _list = collection.data;
    if(offset == 0){
      reset();
    }
    totalAssetsCount += _list!.length;
    for(GiphyGif _gif in _list){
      String _url = _gif.images!.fixedWidth.url;
      double _displaySize = double.parse(_gif.images!.fixedWidthDownsampled!.width)/double.parse(_gif.images!.fixedWidthDownsampled!.height);
      _displayAssets[_url] = _displaySize;
    }
    assetsLoadingComplete = true;
    notifyListeners();
  }
  
  /// Load more assets from searching state
  Future<void> loadMoreAssetsFromSearching(int offset, String value) async {
    if(value == '' || value == null){
      loadMoreAssetsFromTrending(offset);
    }
    else{
      assetsLoadingComplete = false;
      GiphyCollection collection = await client.search(value, offset: offset, limit: pageSize, rating: GiphyRating.r).then((value) {
        assetsLoadingComplete = true;
        return value;
      });
      List<GiphyGif>? _list = collection.data;
      if(offset == 0){
        reset();
      }
      totalAssetsCount += _list!.length;
      for(GiphyGif _gif in _list){
        String _url = _gif.images!.fixedWidth.url;
        double _displaySize = double.parse(_gif.images!.fixedWidthDownsampled!.width)/double.parse(_gif.images!.fixedWidthDownsampled!.height);
        _displayAssets[_url] = _displaySize;
      }
      assetsLoadingComplete = true;
      notifyListeners();
    }
  }
}