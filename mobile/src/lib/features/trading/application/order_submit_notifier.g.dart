// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_submit_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrderSubmitNotifier)
final orderSubmitProvider = OrderSubmitNotifierProvider._();

final class OrderSubmitNotifierProvider
    extends $NotifierProvider<OrderSubmitNotifier, OrderSubmitState> {
  OrderSubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderSubmitNotifierHash();

  @$internal
  @override
  OrderSubmitNotifier create() => OrderSubmitNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderSubmitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderSubmitState>(value),
    );
  }
}

String _$orderSubmitNotifierHash() =>
    r'f428d83e6f0344ac6a3e39c182a99b8af4e5a37c';

abstract class _$OrderSubmitNotifier extends $Notifier<OrderSubmitState> {
  OrderSubmitState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OrderSubmitState, OrderSubmitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OrderSubmitState, OrderSubmitState>,
              OrderSubmitState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
