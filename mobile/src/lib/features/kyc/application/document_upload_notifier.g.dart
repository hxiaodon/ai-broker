// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_upload_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DocumentUploadNotifier)
final documentUploadProvider = DocumentUploadNotifierProvider._();

final class DocumentUploadNotifierProvider
    extends $NotifierProvider<DocumentUploadNotifier, DocumentUploadState> {
  DocumentUploadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentUploadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentUploadNotifierHash();

  @$internal
  @override
  DocumentUploadNotifier create() => DocumentUploadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentUploadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentUploadState>(value),
    );
  }
}

String _$documentUploadNotifierHash() =>
    r'6bfc0ef852977cc167f6ca2a24c333ca03854dc6';

abstract class _$DocumentUploadNotifier extends $Notifier<DocumentUploadState> {
  DocumentUploadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DocumentUploadState, DocumentUploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DocumentUploadState, DocumentUploadState>,
              DocumentUploadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
