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

// class SelectAsset extends GiphyEvent{
//   String asset;
//   SelectAsset(this.asset);
// }

// class UnselectAsset extends GiphyEvent{
//   UnselectAsset();
// }

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

