part of 'state.dart';

class GiphyEvent {}

class LoadAssetsFromTrending extends GiphyEvent{
  int offset;
  Store<GiphyState> store;
  LoadAssetsFromTrending(this.offset, this.store);
}

class LoadAssetsFromSearching extends GiphyEvent{
  int offset;
  String value;
  Store<GiphyState> store;
  LoadAssetsFromSearching(this.offset, this.value, this.store);
}

class ChangeConnectivityStatus extends GiphyEvent{
  bool connectivity;
  ChangeConnectivityStatus(this.connectivity);
}

class Reset extends GiphyEvent{
  Reset();
}

class SetSelectedAsset extends GiphyEvent{
  String asset;
  SetSelectedAsset(this.asset);
}

class SetDisplayAssets extends GiphyEvent{
  Map<String, double> displayAssets;
  SetDisplayAssets(this.displayAssets);
}

class SearchResultsErrorAction extends GiphyEvent{
  dynamic error;
  SearchResultsErrorAction(this.error);
}

class SearchCancelAction extends GiphyEvent{
  SearchCancelAction();
}

class CancelSearchAction extends GiphyEvent{
  CancelSearchAction();
}

/*
 
      _        _   _                 
     / \   ___| |_(_) ___  _ __  ___ 
    / _ \ / __| __| |/ _ \| '_ \/ __|
   / ___ \ (__| |_| | (_) | | | \__ \
  /_/   \_\___|\__|_|\___/|_| |_|___/
                                     
 
*/

ThunkAction<GiphyState> hydrateAction(){
  return (Store<GiphyState> store) async {
    Map<String, double> _list = await GiphyFunctions.loadAssetsFromTrending(0, store);
    store.dispatch(SetDisplayAssets(_list));
  };
}

ThunkAction<GiphyState> selectAsset(String asset){
  return (Store<GiphyState> store) {
    if (asset == '' || store.state.selectedAsset == asset) {
      return;
    }
    if(store.state.selectedAsset != ''){
      store.dispatch(unSelectAsset());
    }
    store.dispatch(SetSelectedAsset(asset));
  };
}

ThunkAction<GiphyState> unSelectAsset(){
  return (Store<GiphyState> store) {
    store.dispatch(SetSelectedAsset(''));
  };
}
