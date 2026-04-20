// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrdersNotifier)
final ordersProvider = OrdersNotifierFamily._();

final class OrdersNotifierProvider
    extends $AsyncNotifierProvider<OrdersNotifier, List<Order>> {
  OrdersNotifierProvider._({
    required OrdersNotifierFamily super.from,
    required OrderStatus? super.argument,
  }) : super(
         retry: null,
         name: r'ordersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ordersNotifierHash();

  @override
  String toString() {
    return r'ordersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrdersNotifier create() => OrdersNotifier();

  @override
  bool operator ==(Object other) {
    return other is OrdersNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ordersNotifierHash() => r'0f1b52ca2431708b7bdd161d672a705f8cbf2dc7';

final class OrdersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          OrdersNotifier,
          AsyncValue<List<Order>>,
          List<Order>,
          FutureOr<List<Order>>,
          OrderStatus?
        > {
  OrdersNotifierFamily._()
    : super(
        retry: null,
        name: r'ordersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrdersNotifierProvider call({OrderStatus? filterStatus}) =>
      OrdersNotifierProvider._(argument: filterStatus, from: this);

  @override
  String toString() => r'ordersProvider';
}

abstract class _$OrdersNotifier extends $AsyncNotifier<List<Order>> {
  late final _$args = ref.$arg as OrderStatus?;
  OrderStatus? get filterStatus => _$args;

  FutureOr<List<Order>> build({OrderStatus? filterStatus});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Order>>, List<Order>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Order>>, List<Order>>,
              AsyncValue<List<Order>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(filterStatus: _$args));
  }
}
