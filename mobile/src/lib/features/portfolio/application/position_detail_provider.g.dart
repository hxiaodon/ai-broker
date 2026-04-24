// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(positionDetail)
final positionDetailProvider = PositionDetailFamily._();

final class PositionDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<PositionDetail>,
          PositionDetail,
          FutureOr<PositionDetail>
        >
    with $FutureModifier<PositionDetail>, $FutureProvider<PositionDetail> {
  PositionDetailProvider._({
    required PositionDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'positionDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$positionDetailHash();

  @override
  String toString() {
    return r'positionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PositionDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PositionDetail> create(Ref ref) {
    final argument = this.argument as String;
    return positionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PositionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$positionDetailHash() => r'8567dfa62ef9bcdd426bca5080b00ed95e41ab7f';

final class PositionDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PositionDetail>, String> {
  PositionDetailFamily._()
    : super(
        retry: null,
        name: r'positionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PositionDetailProvider call(String symbol) =>
      PositionDetailProvider._(argument: symbol, from: this);

  @override
  String toString() => r'positionDetailProvider';
}
