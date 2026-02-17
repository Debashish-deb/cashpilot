// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'net_worth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetWorthHistoryPoint {

 DateTime get date; int get valueCents;
/// Create a copy of NetWorthHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetWorthHistoryPointCopyWith<NetWorthHistoryPoint> get copyWith => _$NetWorthHistoryPointCopyWithImpl<NetWorthHistoryPoint>(this as NetWorthHistoryPoint, _$identity);

  /// Serializes this NetWorthHistoryPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetWorthHistoryPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.valueCents, valueCents) || other.valueCents == valueCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,valueCents);

@override
String toString() {
  return 'NetWorthHistoryPoint(date: $date, valueCents: $valueCents)';
}


}

/// @nodoc
abstract mixin class $NetWorthHistoryPointCopyWith<$Res>  {
  factory $NetWorthHistoryPointCopyWith(NetWorthHistoryPoint value, $Res Function(NetWorthHistoryPoint) _then) = _$NetWorthHistoryPointCopyWithImpl;
@useResult
$Res call({
 DateTime date, int valueCents
});




}
/// @nodoc
class _$NetWorthHistoryPointCopyWithImpl<$Res>
    implements $NetWorthHistoryPointCopyWith<$Res> {
  _$NetWorthHistoryPointCopyWithImpl(this._self, this._then);

  final NetWorthHistoryPoint _self;
  final $Res Function(NetWorthHistoryPoint) _then;

/// Create a copy of NetWorthHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? valueCents = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,valueCents: null == valueCents ? _self.valueCents : valueCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NetWorthHistoryPoint].
extension NetWorthHistoryPointPatterns on NetWorthHistoryPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetWorthHistoryPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetWorthHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetWorthHistoryPoint value)  $default,){
final _that = this;
switch (_that) {
case _NetWorthHistoryPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetWorthHistoryPoint value)?  $default,){
final _that = this;
switch (_that) {
case _NetWorthHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  int valueCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetWorthHistoryPoint() when $default != null:
return $default(_that.date,_that.valueCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  int valueCents)  $default,) {final _that = this;
switch (_that) {
case _NetWorthHistoryPoint():
return $default(_that.date,_that.valueCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  int valueCents)?  $default,) {final _that = this;
switch (_that) {
case _NetWorthHistoryPoint() when $default != null:
return $default(_that.date,_that.valueCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetWorthHistoryPoint implements NetWorthHistoryPoint {
  const _NetWorthHistoryPoint({required this.date, required this.valueCents});
  factory _NetWorthHistoryPoint.fromJson(Map<String, dynamic> json) => _$NetWorthHistoryPointFromJson(json);

@override final  DateTime date;
@override final  int valueCents;

/// Create a copy of NetWorthHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetWorthHistoryPointCopyWith<_NetWorthHistoryPoint> get copyWith => __$NetWorthHistoryPointCopyWithImpl<_NetWorthHistoryPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetWorthHistoryPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetWorthHistoryPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.valueCents, valueCents) || other.valueCents == valueCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,valueCents);

@override
String toString() {
  return 'NetWorthHistoryPoint(date: $date, valueCents: $valueCents)';
}


}

/// @nodoc
abstract mixin class _$NetWorthHistoryPointCopyWith<$Res> implements $NetWorthHistoryPointCopyWith<$Res> {
  factory _$NetWorthHistoryPointCopyWith(_NetWorthHistoryPoint value, $Res Function(_NetWorthHistoryPoint) _then) = __$NetWorthHistoryPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, int valueCents
});




}
/// @nodoc
class __$NetWorthHistoryPointCopyWithImpl<$Res>
    implements _$NetWorthHistoryPointCopyWith<$Res> {
  __$NetWorthHistoryPointCopyWithImpl(this._self, this._then);

  final _NetWorthHistoryPoint _self;
  final $Res Function(_NetWorthHistoryPoint) _then;

/// Create a copy of NetWorthHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? valueCents = null,}) {
  return _then(_NetWorthHistoryPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,valueCents: null == valueCents ? _self.valueCents : valueCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NetWorthSummaryData {

 int get totalAssets; int get totalLiabilities; int get netWorth;
/// Create a copy of NetWorthSummaryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetWorthSummaryDataCopyWith<NetWorthSummaryData> get copyWith => _$NetWorthSummaryDataCopyWithImpl<NetWorthSummaryData>(this as NetWorthSummaryData, _$identity);

  /// Serializes this NetWorthSummaryData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetWorthSummaryData&&(identical(other.totalAssets, totalAssets) || other.totalAssets == totalAssets)&&(identical(other.totalLiabilities, totalLiabilities) || other.totalLiabilities == totalLiabilities)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalAssets,totalLiabilities,netWorth);

@override
String toString() {
  return 'NetWorthSummaryData(totalAssets: $totalAssets, totalLiabilities: $totalLiabilities, netWorth: $netWorth)';
}


}

/// @nodoc
abstract mixin class $NetWorthSummaryDataCopyWith<$Res>  {
  factory $NetWorthSummaryDataCopyWith(NetWorthSummaryData value, $Res Function(NetWorthSummaryData) _then) = _$NetWorthSummaryDataCopyWithImpl;
@useResult
$Res call({
 int totalAssets, int totalLiabilities, int netWorth
});




}
/// @nodoc
class _$NetWorthSummaryDataCopyWithImpl<$Res>
    implements $NetWorthSummaryDataCopyWith<$Res> {
  _$NetWorthSummaryDataCopyWithImpl(this._self, this._then);

  final NetWorthSummaryData _self;
  final $Res Function(NetWorthSummaryData) _then;

/// Create a copy of NetWorthSummaryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalAssets = null,Object? totalLiabilities = null,Object? netWorth = null,}) {
  return _then(_self.copyWith(
totalAssets: null == totalAssets ? _self.totalAssets : totalAssets // ignore: cast_nullable_to_non_nullable
as int,totalLiabilities: null == totalLiabilities ? _self.totalLiabilities : totalLiabilities // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NetWorthSummaryData].
extension NetWorthSummaryDataPatterns on NetWorthSummaryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetWorthSummaryData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetWorthSummaryData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetWorthSummaryData value)  $default,){
final _that = this;
switch (_that) {
case _NetWorthSummaryData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetWorthSummaryData value)?  $default,){
final _that = this;
switch (_that) {
case _NetWorthSummaryData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalAssets,  int totalLiabilities,  int netWorth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetWorthSummaryData() when $default != null:
return $default(_that.totalAssets,_that.totalLiabilities,_that.netWorth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalAssets,  int totalLiabilities,  int netWorth)  $default,) {final _that = this;
switch (_that) {
case _NetWorthSummaryData():
return $default(_that.totalAssets,_that.totalLiabilities,_that.netWorth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalAssets,  int totalLiabilities,  int netWorth)?  $default,) {final _that = this;
switch (_that) {
case _NetWorthSummaryData() when $default != null:
return $default(_that.totalAssets,_that.totalLiabilities,_that.netWorth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetWorthSummaryData implements NetWorthSummaryData {
  const _NetWorthSummaryData({required this.totalAssets, required this.totalLiabilities, required this.netWorth});
  factory _NetWorthSummaryData.fromJson(Map<String, dynamic> json) => _$NetWorthSummaryDataFromJson(json);

@override final  int totalAssets;
@override final  int totalLiabilities;
@override final  int netWorth;

/// Create a copy of NetWorthSummaryData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetWorthSummaryDataCopyWith<_NetWorthSummaryData> get copyWith => __$NetWorthSummaryDataCopyWithImpl<_NetWorthSummaryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetWorthSummaryDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetWorthSummaryData&&(identical(other.totalAssets, totalAssets) || other.totalAssets == totalAssets)&&(identical(other.totalLiabilities, totalLiabilities) || other.totalLiabilities == totalLiabilities)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalAssets,totalLiabilities,netWorth);

@override
String toString() {
  return 'NetWorthSummaryData(totalAssets: $totalAssets, totalLiabilities: $totalLiabilities, netWorth: $netWorth)';
}


}

/// @nodoc
abstract mixin class _$NetWorthSummaryDataCopyWith<$Res> implements $NetWorthSummaryDataCopyWith<$Res> {
  factory _$NetWorthSummaryDataCopyWith(_NetWorthSummaryData value, $Res Function(_NetWorthSummaryData) _then) = __$NetWorthSummaryDataCopyWithImpl;
@override @useResult
$Res call({
 int totalAssets, int totalLiabilities, int netWorth
});




}
/// @nodoc
class __$NetWorthSummaryDataCopyWithImpl<$Res>
    implements _$NetWorthSummaryDataCopyWith<$Res> {
  __$NetWorthSummaryDataCopyWithImpl(this._self, this._then);

  final _NetWorthSummaryData _self;
  final $Res Function(_NetWorthSummaryData) _then;

/// Create a copy of NetWorthSummaryData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalAssets = null,Object? totalLiabilities = null,Object? netWorth = null,}) {
  return _then(_NetWorthSummaryData(
totalAssets: null == totalAssets ? _self.totalAssets : totalAssets // ignore: cast_nullable_to_non_nullable
as int,totalLiabilities: null == totalLiabilities ? _self.totalLiabilities : totalLiabilities // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
