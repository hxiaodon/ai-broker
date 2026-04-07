// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injectable [SharedPreferences] provider.
///
/// Override in tests with `sharedPreferencesProvider.overrideWithValue(mock)`.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Injectable [SharedPreferences] provider.
///
/// Override in tests with `sharedPreferencesProvider.overrideWithValue(mock)`.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  /// Injectable [SharedPreferences] provider.
  ///
  /// Override in tests with `sharedPreferencesProvider.overrideWithValue(mock)`.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'ad13470fe866595ad0f58a3e26f11048d94ef22e';

/// Manages the search screen state.
///
/// ## Usage
/// ```dart
/// // Update query (debounced search triggers automatically)
/// ref.read(searchProvider.notifier).updateQuery('AAPL');
///
/// // Add to history after user taps a result
/// ref.read(searchProvider.notifier).addToHistory('AAPL');
///
/// // Clear history
/// ref.read(searchProvider.notifier).clearHistory();
/// ```
///
/// ## Minimum input length
/// - ASCII-only query (symbol / English name): ≥ 1 character.
/// - Query with non-ASCII characters (Chinese name / Pinyin initials): ≥ 2 characters.
///
/// Queries shorter than the minimum show an empty results list without
/// triggering a network call.

@ProviderFor(SearchNotifier)
final searchProvider = SearchNotifierProvider._();

/// Manages the search screen state.
///
/// ## Usage
/// ```dart
/// // Update query (debounced search triggers automatically)
/// ref.read(searchProvider.notifier).updateQuery('AAPL');
///
/// // Add to history after user taps a result
/// ref.read(searchProvider.notifier).addToHistory('AAPL');
///
/// // Clear history
/// ref.read(searchProvider.notifier).clearHistory();
/// ```
///
/// ## Minimum input length
/// - ASCII-only query (symbol / English name): ≥ 1 character.
/// - Query with non-ASCII characters (Chinese name / Pinyin initials): ≥ 2 characters.
///
/// Queries shorter than the minimum show an empty results list without
/// triggering a network call.
final class SearchNotifierProvider
    extends $NotifierProvider<SearchNotifier, SearchState> {
  /// Manages the search screen state.
  ///
  /// ## Usage
  /// ```dart
  /// // Update query (debounced search triggers automatically)
  /// ref.read(searchProvider.notifier).updateQuery('AAPL');
  ///
  /// // Add to history after user taps a result
  /// ref.read(searchProvider.notifier).addToHistory('AAPL');
  ///
  /// // Clear history
  /// ref.read(searchProvider.notifier).clearHistory();
  /// ```
  ///
  /// ## Minimum input length
  /// - ASCII-only query (symbol / English name): ≥ 1 character.
  /// - Query with non-ASCII characters (Chinese name / Pinyin initials): ≥ 2 characters.
  ///
  /// Queries shorter than the minimum show an empty results list without
  /// triggering a network call.
  SearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchNotifierHash();

  @$internal
  @override
  SearchNotifier create() => SearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }
}

String _$searchNotifierHash() => r'8985eb4607cc0644ddb280ecefb0e5d41436a00e';

/// Manages the search screen state.
///
/// ## Usage
/// ```dart
/// // Update query (debounced search triggers automatically)
/// ref.read(searchProvider.notifier).updateQuery('AAPL');
///
/// // Add to history after user taps a result
/// ref.read(searchProvider.notifier).addToHistory('AAPL');
///
/// // Clear history
/// ref.read(searchProvider.notifier).clearHistory();
/// ```
///
/// ## Minimum input length
/// - ASCII-only query (symbol / English name): ≥ 1 character.
/// - Query with non-ASCII characters (Chinese name / Pinyin initials): ≥ 2 characters.
///
/// Queries shorter than the minimum show an empty results list without
/// triggering a network call.

abstract class _$SearchNotifier extends $Notifier<SearchState> {
  SearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
