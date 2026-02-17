// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Liability {

 String get id; String get userId; String get name; LiabilityType get type; int get currentBalance;// in cents
 String get currency; double? get interestRate; DateTime? get dueDate; int? get minPayment;// in cents
// Metadata
 DateTime get createdAt; DateTime get updatedAt; String? get notes;// Sync
 bool get isDeleted; int get revision;
/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiabilityCopyWith<Liability> get copyWith => _$LiabilityCopyWithImpl<Liability>(this as Liability, _$identity);

  /// Serializes this Liability to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Liability&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.minPayment, minPayment) || other.minPayment == minPayment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.revision, revision) || other.revision == revision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,type,currentBalance,currency,interestRate,dueDate,minPayment,createdAt,updatedAt,notes,isDeleted,revision);

@override
String toString() {
  return 'Liability(id: $id, userId: $userId, name: $name, type: $type, currentBalance: $currentBalance, currency: $currency, interestRate: $interestRate, dueDate: $dueDate, minPayment: $minPayment, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes, isDeleted: $isDeleted, revision: $revision)';
}


}

/// @nodoc
abstract mixin class $LiabilityCopyWith<$Res>  {
  factory $LiabilityCopyWith(Liability value, $Res Function(Liability) _then) = _$LiabilityCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, LiabilityType type, int currentBalance, String currency, double? interestRate, DateTime? dueDate, int? minPayment, DateTime createdAt, DateTime updatedAt, String? notes, bool isDeleted, int revision
});




}
/// @nodoc
class _$LiabilityCopyWithImpl<$Res>
    implements $LiabilityCopyWith<$Res> {
  _$LiabilityCopyWithImpl(this._self, this._then);

  final Liability _self;
  final $Res Function(Liability) _then;

/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? type = null,Object? currentBalance = null,Object? currency = null,Object? interestRate = freezed,Object? dueDate = freezed,Object? minPayment = freezed,Object? createdAt = null,Object? updatedAt = null,Object? notes = freezed,Object? isDeleted = null,Object? revision = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LiabilityType,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,minPayment: freezed == minPayment ? _self.minPayment : minPayment // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Liability].
extension LiabilityPatterns on Liability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Liability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Liability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Liability value)  $default,){
final _that = this;
switch (_that) {
case _Liability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Liability value)?  $default,){
final _that = this;
switch (_that) {
case _Liability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  LiabilityType type,  int currentBalance,  String currency,  double? interestRate,  DateTime? dueDate,  int? minPayment,  DateTime createdAt,  DateTime updatedAt,  String? notes,  bool isDeleted,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Liability() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.type,_that.currentBalance,_that.currency,_that.interestRate,_that.dueDate,_that.minPayment,_that.createdAt,_that.updatedAt,_that.notes,_that.isDeleted,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  LiabilityType type,  int currentBalance,  String currency,  double? interestRate,  DateTime? dueDate,  int? minPayment,  DateTime createdAt,  DateTime updatedAt,  String? notes,  bool isDeleted,  int revision)  $default,) {final _that = this;
switch (_that) {
case _Liability():
return $default(_that.id,_that.userId,_that.name,_that.type,_that.currentBalance,_that.currency,_that.interestRate,_that.dueDate,_that.minPayment,_that.createdAt,_that.updatedAt,_that.notes,_that.isDeleted,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  LiabilityType type,  int currentBalance,  String currency,  double? interestRate,  DateTime? dueDate,  int? minPayment,  DateTime createdAt,  DateTime updatedAt,  String? notes,  bool isDeleted,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _Liability() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.type,_that.currentBalance,_that.currency,_that.interestRate,_that.dueDate,_that.minPayment,_that.createdAt,_that.updatedAt,_that.notes,_that.isDeleted,_that.revision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Liability implements Liability {
  const _Liability({required this.id, required this.userId, required this.name, required this.type, required this.currentBalance, this.currency = 'EUR', this.interestRate, this.dueDate, this.minPayment, required this.createdAt, required this.updatedAt, this.notes, this.isDeleted = false, this.revision = 0});
  factory _Liability.fromJson(Map<String, dynamic> json) => _$LiabilityFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  LiabilityType type;
@override final  int currentBalance;
// in cents
@override@JsonKey() final  String currency;
@override final  double? interestRate;
@override final  DateTime? dueDate;
@override final  int? minPayment;
// in cents
// Metadata
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? notes;
// Sync
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  int revision;

/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiabilityCopyWith<_Liability> get copyWith => __$LiabilityCopyWithImpl<_Liability>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiabilityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Liability&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.minPayment, minPayment) || other.minPayment == minPayment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.revision, revision) || other.revision == revision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,type,currentBalance,currency,interestRate,dueDate,minPayment,createdAt,updatedAt,notes,isDeleted,revision);

@override
String toString() {
  return 'Liability(id: $id, userId: $userId, name: $name, type: $type, currentBalance: $currentBalance, currency: $currency, interestRate: $interestRate, dueDate: $dueDate, minPayment: $minPayment, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes, isDeleted: $isDeleted, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$LiabilityCopyWith<$Res> implements $LiabilityCopyWith<$Res> {
  factory _$LiabilityCopyWith(_Liability value, $Res Function(_Liability) _then) = __$LiabilityCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, LiabilityType type, int currentBalance, String currency, double? interestRate, DateTime? dueDate, int? minPayment, DateTime createdAt, DateTime updatedAt, String? notes, bool isDeleted, int revision
});




}
/// @nodoc
class __$LiabilityCopyWithImpl<$Res>
    implements _$LiabilityCopyWith<$Res> {
  __$LiabilityCopyWithImpl(this._self, this._then);

  final _Liability _self;
  final $Res Function(_Liability) _then;

/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? type = null,Object? currentBalance = null,Object? currency = null,Object? interestRate = freezed,Object? dueDate = freezed,Object? minPayment = freezed,Object? createdAt = null,Object? updatedAt = null,Object? notes = freezed,Object? isDeleted = null,Object? revision = null,}) {
  return _then(_Liability(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LiabilityType,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,minPayment: freezed == minPayment ? _self.minPayment : minPayment // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
