import 'package:fort/fort.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:piky/state/state.dart';

class GiphyFunctions{

  /// Load more assets from trending state
  Future<Map<String, double>> loadAssetsFromTrending(int offset, Store<GiphyState> store) async {
    try{
      Map<String, double> _displayAssets = {};
      GiphyCollection collection = await store.state.giphyClient!.trending(offset: offset, limit: store.state.pageSize).then((value) {
        return value;
      });
      List<GiphyGif>? _list = collection.data;
      if(offset == 0){
        store.dispatch(Reset());
      }
      if(_list != null){
        for(GiphyGif _gif in _list){
          String _url = _gif.images!.fixedWidth.url;
          double _displaySize = double.parse(_gif.images!.fixedWidthDownsampled!.width)/double.parse(_gif.images!.fixedWidthDownsampled!.height);
          _displayAssets[_url] = _displaySize;
        }
      }
      return _displayAssets;
    }
    catch(e){
      return {};
    }
  }

  Future<Map<String, double>> loadAssetsFromSearching(int offset, String value, Store<GiphyState> store) async{
    if(value == '' || value == null){
      return loadAssetsFromTrending(offset, store);
    }
    else{
      try{
        Map<String, double> _displayAssets = {};
        GiphyCollection collection = await store.state.giphyClient!.search(value, offset: offset, limit: store.state.pageSize, rating: GiphyRating.pg13).then((value) {
          return value;
        });
        List<GiphyGif>? _list = collection.data;
        if(offset == 0){
          store.dispatch(Reset());
        }
        if(_list != null){
          for(GiphyGif _gif in _list){
            String _url = _gif.images!.fixedWidth.url;
            double _displaySize = double.parse(_gif.images!.fixedWidthDownsampled!.width)/double.parse(_gif.images!.fixedWidthDownsampled!.height);
            _displayAssets[_url] = _displaySize;
          }
        }
        return _displayAssets;
      }
      catch(e){
        return {};
      }
    }
  }
}
