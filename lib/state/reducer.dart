part of 'state.dart';

GiphyState giphyStateReducer(GiphyState state, dynamic event){
  if(event is GiphyEvent){
    return GiphyState(
      apiKey: state.apiKey,
      pageSize: state.pageSize,
      routeDuration: state.routeDuration,
      giphyClient: state.giphyClient,
      selectedAsset: selectedAssetReducer(state, event),
      connectivity: connectivityReducer(state, event),
      displayAssets: displayAssetsReducer(state, event),
    );
  }
  return state;
}

bool connectivityReducer(GiphyState state, dynamic event){
  if(event is ChangeConnectivityStatus){
    return event.connectivity;
  }
  return state.connectivity;
}

Map<String, double> displayAssetsReducer(GiphyState state, dynamic event){
  if(event is SetDisplayAssets){
    return event.displayAssets;
  }
  return state.displayAssets;
}

String? selectedAssetReducer(GiphyState state, dynamic event){
  if(event is SetSelectedAsset){
    return event.asset;
  }
  return state.selectedAsset;
}