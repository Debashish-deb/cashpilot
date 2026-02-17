// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financial_tip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FinancialTip {

 String get id; String get title; String get content; String get category; String get actionLabel; String get actionRoute; String get type; String get languageCode; DateTime get createdAt; DateTime? get expiresAt;
/// Create a copy of FinancialTip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialTipCopyWith<FinancialTip> get copyWith => _$FinancialTipCopyWithImpl<FinancialTip>(this as FinancialTip, _$identity);

  /// Serializes this FinancialTip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialTip&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category)&&(identical(other.actionLabel, actionLabel) || other.actionLabel == actionLabel)&&(identical(other.actionRoute, actionRoute) || other.actionRoute == actionRoute)&&(identical(other.type, type) || other.type == type)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,category,actionLabel,actionRoute,type,languageCode,createdAt,expiresAt);

@override
String toString() {
  return 'FinancialTip(id: $id, title: $title, content: $content, category: $category, actionLabel: $actionLabel, actionRoute: $actionRoute, type: $type, languageCode: $languageCode, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $FinancialTipCopyWith<$Res>  {
  factory $FinancialTipCopyWith(FinancialTip value, $Res Function(FinancialTip) _then) = _$FinancialTipCopyWithImpl;
@useResult
$Res call({
 String id, String title, String content, String category, String actionLabel, String actionRoute, String type, String languageCode, DateTime createdAt, DateTime? expiresAt
});




}
/// @nodoc
class _$FinancialTipCopyWithImpl<$Res>
    implements $FinancialTipCopyWith<$Res> {
  _$FinancialTipCopyWithImpl(this._self, this._then);

  final FinancialTip _self;
  final $Res Function(FinancialTip) _then;

/// Create a copy of FinancialTip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? category = null,Object? actionLabel = null,Object? actionRoute = null,Object? type = null,Object? languageCode = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,actionLabel: null == actionLabel ? _self.actionLabel : actionLabel // ignore: cast_nullable_to_non_nullable
as String,actionRoute: null == actionRoute ? _self.actionRoute : actionRoute // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialTip].
extension FinancialTipPatterns on FinancialTip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialTip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialTip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialTip value)  $default,){
final _that = this;
switch (_that) {
case _FinancialTip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialTip value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialTip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String content,  String category,  String actionLabel,  String actionRoute,  String type,  String languageCode,  DateTime createdAt,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialTip() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.category,_that.actionLabel,_that.actionRoute,_that.type,_that.languageCode,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String content,  String category,  String actionLabel,  String actionRoute,  String type,  String languageCode,  DateTime createdAt,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _FinancialTip():
return $default(_that.id,_that.title,_that.content,_that.category,_that.actionLabel,_that.actionRoute,_that.type,_that.languageCode,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String content,  String category,  String actionLabel,  String actionRoute,  String type,  String languageCode,  DateTime createdAt,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _FinancialTip() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.category,_that.actionLabel,_that.actionRoute,_that.type,_that.languageCode,_that.createdAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinancialTip implements FinancialTip {
  const _FinancialTip({required this.id, required this.title, required this.content, required this.category, required this.actionLabel, required this.actionRoute, this.type = 'info', this.languageCode = 'en', required this.createdAt, required this.expiresAt});
  factory _FinancialTip.fromJson(Map<String, dynamic> json) => _$FinancialTipFromJson(json);

@override final  String id;
@override final  String title;
@override final  String content;
@override final  String category;
@override final  String actionLabel;
@override final  String actionRoute;
@override@JsonKey() final  String type;
@override@JsonKey() final  String languageCode;
@override final  DateTime createdAt;
@override final  DateTime? expiresAt;

/// Create a copy of FinancialTip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialTipCopyWith<_FinancialTip> get copyWith => __$FinancialTipCopyWithImpl<_FinancialTip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinancialTipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialTip&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category)&&(identical(other.actionLabel, actionLabel) || other.actionLabel == actionLabel)&&(identical(other.actionRoute, actionRoute) || other.actionRoute == actionRoute)&&(identical(other.type, type) || other.type == type)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,category,actionLabel,actionRoute,type,languageCode,createdAt,expiresAt);

@override
String toString() {
  return 'FinancialTip(id: $id, title: $title, content: $content, category: $category, actionLabel: $actionLabel, actionRoute: $actionRoute, type: $type, languageCode: $languageCode, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$FinancialTipCopyWith<$Res> implements $FinancialTipCopyWith<$Res> {
  factory _$FinancialTipCopyWith(_FinancialTip value, $Res Function(_FinancialTip) _then) = __$FinancialTipCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String content, String category, String actionLabel, String actionRoute, String type, String languageCode, DateTime createdAt, DateTime? expiresAt
});




}
/// @nodoc
class __$FinancialTipCopyWithImpl<$Res>
    implements _$FinancialTipCopyWith<$Res> {
  __$FinancialTipCopyWithImpl(this._self, this._then);

  final _FinancialTip _self;
  final $Res Function(_FinancialTip) _then;

/// Create a copy of FinancialTip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? category = null,Object? actionLabel = null,Object? actionRoute = null,Object? type = null,Object? languageCode = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_FinancialTip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,actionLabel: null == actionLabel ? _self.actionLabel : actionLabel // ignore: cast_nullable_to_non_nullable
as String,actionRoute: null == actionRoute ? _self.actionRoute : actionRoute // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
