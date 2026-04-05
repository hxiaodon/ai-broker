// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewsArticle {

 String get id; String get title; String get summary; String get source; DateTime get publishedAt; String get url;
/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsArticleCopyWith<NewsArticle> get copyWith => _$NewsArticleCopyWithImpl<NewsArticle>(this as NewsArticle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.source, source) || other.source == source)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,summary,source,publishedAt,url);

@override
String toString() {
  return 'NewsArticle(id: $id, title: $title, summary: $summary, source: $source, publishedAt: $publishedAt, url: $url)';
}


}

/// @nodoc
abstract mixin class $NewsArticleCopyWith<$Res>  {
  factory $NewsArticleCopyWith(NewsArticle value, $Res Function(NewsArticle) _then) = _$NewsArticleCopyWithImpl;
@useResult
$Res call({
 String id, String title, String summary, String source, DateTime publishedAt, String url
});




}
/// @nodoc
class _$NewsArticleCopyWithImpl<$Res>
    implements $NewsArticleCopyWith<$Res> {
  _$NewsArticleCopyWithImpl(this._self, this._then);

  final NewsArticle _self;
  final $Res Function(NewsArticle) _then;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? source = null,Object? publishedAt = null,Object? url = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsArticle].
extension NewsArticlePatterns on NewsArticle {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsArticle value)  $default,){
final _that = this;
switch (_that) {
case _NewsArticle():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsArticle value)?  $default,){
final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String summary,  String source,  DateTime publishedAt,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.source,_that.publishedAt,_that.url);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String summary,  String source,  DateTime publishedAt,  String url)  $default,) {final _that = this;
switch (_that) {
case _NewsArticle():
return $default(_that.id,_that.title,_that.summary,_that.source,_that.publishedAt,_that.url);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String summary,  String source,  DateTime publishedAt,  String url)?  $default,) {final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.source,_that.publishedAt,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _NewsArticle implements NewsArticle {
  const _NewsArticle({required this.id, required this.title, required this.summary, required this.source, required this.publishedAt, required this.url});
  

@override final  String id;
@override final  String title;
@override final  String summary;
@override final  String source;
@override final  DateTime publishedAt;
@override final  String url;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsArticleCopyWith<_NewsArticle> get copyWith => __$NewsArticleCopyWithImpl<_NewsArticle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.source, source) || other.source == source)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,summary,source,publishedAt,url);

@override
String toString() {
  return 'NewsArticle(id: $id, title: $title, summary: $summary, source: $source, publishedAt: $publishedAt, url: $url)';
}


}

/// @nodoc
abstract mixin class _$NewsArticleCopyWith<$Res> implements $NewsArticleCopyWith<$Res> {
  factory _$NewsArticleCopyWith(_NewsArticle value, $Res Function(_NewsArticle) _then) = __$NewsArticleCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String summary, String source, DateTime publishedAt, String url
});




}
/// @nodoc
class __$NewsArticleCopyWithImpl<$Res>
    implements _$NewsArticleCopyWith<$Res> {
  __$NewsArticleCopyWithImpl(this._self, this._then);

  final _NewsArticle _self;
  final $Res Function(_NewsArticle) _then;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? source = null,Object? publishedAt = null,Object? url = null,}) {
  return _then(_NewsArticle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
