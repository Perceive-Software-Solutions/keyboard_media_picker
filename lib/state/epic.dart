part of 'state.dart';

Stream<dynamic> autocompleteEpic(
  Stream<dynamic> actions,
  EpicStore<GiphyState> store,
) {
  return actions
      .whereType<LoadAssetsFromSearching>()
      .switchMap((action) {
        return Stream.fromFuture(GiphyFunctions().loadAssetsFromSearching(action.offset, action.value, action.store)
        .then((results) => SetDisplayAssets(results)));
  });
}