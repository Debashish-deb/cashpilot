// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'knowledge_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KnowledgeArticle {

 String get id; String get title; String get summary; String get content; String get topic;// e.g., 'budgeting', 'investing', 'savings'
 List<String> get tags; String? get imageUrl; int get readTimeMinutes; String get languageCode; bool get isPremium; DateTime get publishedAt; DateTime get updatedAt;
/// Create a copy of KnowledgeArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KnowledgeArticleCopyWith<KnowledgeArticle> get copyWith => _$KnowledgeArticleCopyWithImpl<KnowledgeArticle>(this as KnowledgeArticle, _$identity);

  /// Serializes this KnowledgeArticle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KnowledgeArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.content, content) || other.content == content)&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.readTimeMinutes, readTimeMinutes) || other.readTimeMinutes == readTimeMinutes)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,summary,content,topic,const DeepCollectionEquality().hash(tags),imageUrl,readTimeMinutes,languageCode,isPremium,publishedAt,updatedAt);

@override
String toString() {
  return 'KnowledgeArticle(id: $id, title: $title, summary: $summary, content: $content, topic: $topic, tags: $tags, imageUrl: $imageUrl, readTimeMinutes: $readTimeMinutes, languageCode: $languageCode, isPremium: $isPremium, publishedAt: $publishedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $KnowledgeArticleCopyWith<$Res>  {
  factory $KnowledgeArticleCopyWith(KnowledgeArticle value, $Res Function(KnowledgeArticle) _then) = _$KnowledgeArticleCopyWithImpl;
@useResult
$Res call({
 String id, String title, String summary, String content, String topic, List<String> tags, String? imageUrl, int readTimeMinutes, String languageCode, bool isPremium, DateTime publishedAt, DateTime updatedAt
});




}
/// @nodoc
class _$KnowledgeArticleCopyWithImpl<$Res>
    implements $KnowledgeArticleCopyWith<$Res> {
  _$KnowledgeArticleCopyWithImpl(this._self, this._then);

  final KnowledgeArticle _self;
  final $Res Function(KnowledgeArticle) _then;

/// Create a copy of KnowledgeArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? content = null,Object? topic = null,Object? tags = null,Object? imageUrl = freezed,Object? readTimeMinutes = null,Object? languageCode = null,Object? isPremium = null,Object? publishedAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,readTimeMinutes: null == readTimeMinutes ? _self.readTimeMinutes : readTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [KnowledgeArticle].
extension KnowledgeArticlePatterns on KnowledgeArticle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KnowledgeArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KnowledgeArticle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KnowledgeArticle value)  $default,){
final _that = this;
switch (_that) {
case _KnowledgeArticle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KnowledgeArticle value)?  $default,){
final _that = this;
switch (_that) {
case _KnowledgeArticle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String summary,  String content,  String topic,  List<String> tags,  String? imageUrl,  int readTimeMinutes,  String languageCode,  bool isPremium,  DateTime publishedAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KnowledgeArticle() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.content,_that.topic,_that.tags,_that.imageUrl,_that.readTimeMinutes,_that.languageCode,_that.isPremium,_that.publishedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String summary,  String content,  String topic,  List<String> tags,  String? imageUrl,  int readTimeMinutes,  String languageCode,  bool isPremium,  DateTime publishedAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _KnowledgeArticle():
return $default(_that.id,_that.title,_that.summary,_that.content,_that.topic,_that.tags,_that.imageUrl,_that.readTimeMinutes,_that.languageCode,_that.isPremium,_that.publishedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String summary,  String content,  String topic,  List<String> tags,  String? imageUrl,  int readTimeMinutes,  String languageCode,  bool isPremium,  DateTime publishedAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _KnowledgeArticle() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.content,_that.topic,_that.tags,_that.imageUrl,_that.readTimeMinutes,_that.languageCode,_that.isPremium,_that.publishedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KnowledgeArticle implements KnowledgeArticle {
  const _KnowledgeArticle({required this.id, required this.title, required this.summary, required this.content, required this.topic, required final  List<String> tags, required this.imageUrl, this.readTimeMinutes = 0, this.languageCode = 'en', this.isPremium = false, required this.publishedAt, required this.updatedAt}): _tags = tags;
  factory _KnowledgeArticle.fromJson(Map<String, dynamic> json) => _$KnowledgeArticleFromJson(json);

@override final  String id;
@override final  String title;
@override final  String summary;
@override final  String content;
@override final  String topic;
// e.g., 'budgeting', 'investing', 'savings'
 final  List<String> _tags;
// e.g., 'budgeting', 'investing', 'savings'
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String? imageUrl;
@override@JsonKey() final  int readTimeMinutes;
@override@JsonKey() final  String languageCode;
@override@JsonKey() final  bool isPremium;
@override final  DateTime publishedAt;
@override final  DateTime updatedAt;

/// Create a copy of KnowledgeArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KnowledgeArticleCopyWith<_KnowledgeArticle> get copyWith => __$KnowledgeArticleCopyWithImpl<_KnowledgeArticle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KnowledgeArticleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KnowledgeArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.content, content) || other.content == content)&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.readTimeMinutes, readTimeMinutes) || other.readTimeMinutes == readTimeMinutes)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,summary,content,topic,const DeepCollectionEquality().hash(_tags),imageUrl,readTimeMinutes,languageCode,isPremium,publishedAt,updatedAt);

@override
String toString() {
  return 'KnowledgeArticle(id: $id, title: $title, summary: $summary, content: $content, topic: $topic, tags: $tags, imageUrl: $imageUrl, readTimeMinutes: $readTimeMinutes, languageCode: $languageCode, isPremium: $isPremium, publishedAt: $publishedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$KnowledgeArticleCopyWith<$Res> implements $KnowledgeArticleCopyWith<$Res> {
  factory _$KnowledgeArticleCopyWith(_KnowledgeArticle value, $Res Function(_KnowledgeArticle) _then) = __$KnowledgeArticleCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String summary, String content, String topic, List<String> tags, String? imageUrl, int readTimeMinutes, String languageCode, bool isPremium, DateTime publishedAt, DateTime updatedAt
});




}
/// @nodoc
class __$KnowledgeArticleCopyWithImpl<$Res>
    implements _$KnowledgeArticleCopyWith<$Res> {
  __$KnowledgeArticleCopyWithImpl(this._self, this._then);

  final _KnowledgeArticle _self;
  final $Res Function(_KnowledgeArticle) _then;

/// Create a copy of KnowledgeArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? content = null,Object? topic = null,Object? tags = null,Object? imageUrl = freezed,Object? readTimeMinutes = null,Object? languageCode = null,Object? isPremium = null,Object? publishedAt = null,Object? updatedAt = null,}) {
  return _then(_KnowledgeArticle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,readTimeMinutes: null == readTimeMinutes ? _self.readTimeMinutes : readTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
