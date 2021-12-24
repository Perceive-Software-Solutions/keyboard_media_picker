import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fort/fort.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:piky/state/giphy_functions.dart';
import 'package:redux_epics/redux_epics.dart';
import 'package:rxdart/rxdart.dart';

part 'events.dart';
part 'reducer.dart';
part 'epic.dart';

class GiphyState extends FortState{

  /// How many gifs load per page
  final int pageSize;

  /// The current selected asset
  final String? selectedAsset;

  /// Page duration
  final Duration routeDuration;

  /// Api clinet key
  final String apiKey;

  /// If connected to the internet
  final bool connectivity;

  /// [Map] for all giphy assets
  /// 
  /// Using [Map] in order to store how the assets should be displayed
  /// in the staggered grid view
  final Map<String, double> displayAssets;
  
  /// The current client
  GiphyClient? giphyClient;

  GiphyState({
    required this.apiKey,
    this.selectedAsset,
    this.pageSize = 40,
    this.routeDuration = const Duration(milliseconds: 300),
    this.giphyClient,
    this.connectivity = true,
    this.displayAssets = const {},
  }){
    /// Initialize API Client
    initializeGiphyClient(apiKey);
  }

  void initializeGiphyClient(String apiKey){
    giphyClient = GiphyClient(apiKey: apiKey, randomId: '154');
  }


  factory GiphyState.initial(String apiKey) => GiphyState(
    apiKey: apiKey,
    selectedAsset: '',
    routeDuration: Duration(milliseconds: 300),
    pageSize: 40
  );

  @override
  FortState copyWith(FortState other) {
    return this;
  }

  @override
  toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

/*
 
     _   _      _                     
    | | | | ___| |_ __   ___ _ __ ___ 
    | |_| |/ _ \ | '_ \ / _ \ '__/ __|
    |  _  |  __/ | |_) |  __/ |  \__ \
    |_| |_|\___|_| .__/ \___|_|  |___/
                 |_|                  
 
*/

  /// Get [_totalAssetsCount]
  int get totalAssetsCount => displayAssets.length;

  /// Get [_displayAssets.isNotEmpty]
  bool get hasAssetsToDisplay => displayAssets.isNotEmpty;
}