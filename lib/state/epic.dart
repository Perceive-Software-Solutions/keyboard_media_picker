part of 'state.dart';

Stream<dynamic> giphySearchEpic(
  Stream<dynamic> actions,
  EpicStore<GiphyState> store,
) {
  return actions
      .whereType<LoadAssetsFromSearching>()
      // .debounce(new Duration(milliseconds: 150))
      .switchMap((action) {
        return Stream.fromFuture(action.value.isEmpty
          ? GiphyFunctions.loadAssetsFromTrending(0, action.store) 
          : GiphyFunctions.loadAssetsFromSearching(action.offset, action.value, action.store)
        .then((results) => SetDisplayAssets(results)))
        .takeUntil(actions.whereType<CancelSearchAction>());
        
  });
}