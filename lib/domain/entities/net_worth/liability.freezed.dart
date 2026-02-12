// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Liability _$LiabilityFromJson(Map<String, dynamic> json) {
  return _Liability.fromJson(json);
}

/// @nodoc
mixin _$Liability {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  LiabilityType get type => throw _privateConstructorUsedError;
  int get currentBalance => throw _privateConstructorUsedError; // in cents
  String get currency => throw _privateConstructorUsedError;
  double? get interestRate => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  int? get minPayment => throw _privateConstructorUsedError; // in cents
  // Metadata
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError; // Sync
  bool get isDeleted => throw _privateConstructorUsedError;
  int get revision => throw _privateConstructorUsedError;

  /// Serializes this Liability to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Liability
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiabilityCopyWith<Liability> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiabilityCopyWith<$Res> {
  factory $LiabilityCopyWith(Liability value, $Res Function(Liability) then) =
      _$LiabilityCopyWithImpl<$Res, Liability>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    LiabilityType type,
    int currentBalance,
    String currency,
    double? interestRate,
    DateTime? dueDate,
    int? minPayment,
    DateTime createdAt,
    DateTime updatedAt,
    String? notes,
    bool isDeleted,
    int revision,
  });
}

/// @nodoc
class _$LiabilityCopyWithImpl<$Res, $Val extends Liability>
    implements $LiabilityCopyWith<$Res> {
  _$LiabilityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Liability
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? type = null,
    Object? currentBalance = null,
    Object? currency = null,
    Object? interestRate = freezed,
    Object? dueDate = freezed,
    Object? minPayment = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? notes = freezed,
    Object? isDeleted = null,
    Object? revision = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as LiabilityType,
            currentBalance: null == currentBalance
                ? _value.currentBalance
                : currentBalance // ignore: cast_nullable_to_non_nullable
                      as int,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            interestRate: freezed == interestRate
                ? _value.interestRate
                : interestRate // ignore: cast_nullable_to_non_nullable
                      as double?,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            minPayment: freezed == minPayment
                ? _value.minPayment
                : minPayment // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            revision: null == revision
                ? _value.revision
                : revision // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiabilityImplCopyWith<$Res>
    implements $LiabilityCopyWith<$Res> {
  factory _$$LiabilityImplCopyWith(
    _$LiabilityImpl value,
    $Res Function(_$LiabilityImpl) then,
  ) = __$$LiabilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    LiabilityType type,
    int currentBalance,
    String currency,
    double? interestRate,
    DateTime? dueDate,
    int? minPayment,
    DateTime createdAt,
    DateTime updatedAt,
    String? notes,
    bool isDeleted,
    int revision,
  });
}

/// @nodoc
class __$$LiabilityImplCopyWithImpl<$Res>
    extends _$LiabilityCopyWithImpl<$Res, _$LiabilityImpl>
    implements _$$LiabilityImplCopyWith<$Res> {
  __$$LiabilityImplCopyWithImpl(
    _$LiabilityImpl _value,
    $Res Function(_$LiabilityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Liability
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? type = null,
    Object? currentBalance = null,
    Object? currency = null,
    Object? interestRate = freezed,
    Object? dueDate = freezed,
    Object? minPayment = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? notes = freezed,
    Object? isDeleted = null,
    Object? revision = null,
  }) {
    return _then(
      _$LiabilityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as LiabilityType,
        currentBalance: null == currentBalance
            ? _value.currentBalance
            : currentBalance // ignore: cast_nullable_to_non_nullable
                  as int,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        interestRate: freezed == interestRate
            ? _value.interestRate
            : interestRate // ignore: cast_nullable_to_non_nullable
                  as double?,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        minPayment: freezed == minPayment
            ? _value.minPayment
            : minPayment // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        revision: null == revision
            ? _value.revision
            : revision // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiabilityImpl implements _Liability {
  const _$LiabilityImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currentBalance,
    this.currency = 'EUR',
    this.interestRate,
    this.dueDate,
    this.minPayment,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isDeleted = false,
    this.revision = 0,
  });

  factory _$LiabilityImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiabilityImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final LiabilityType type;
  @override
  final int currentBalance;
  // in cents
  @override
  @JsonKey()
  final String currency;
  @override
  final double? interestRate;
  @override
  final DateTime? dueDate;
  @override
  final int? minPayment;
  // in cents
  // Metadata
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? notes;
  // Sync
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  @JsonKey()
  final int revision;

  @override
  String toString() {
    return 'Liability(id: $id, userId: $userId, name: $name, type: $type, currentBalance: $currentBalance, currency: $currency, interestRate: $interestRate, dueDate: $dueDate, minPayment: $minPayment, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes, isDeleted: $isDeleted, revision: $revision)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiabilityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.currentBalance, currentBalance) ||
                other.currentBalance == currentBalance) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.interestRate, interestRate) ||
                other.interestRate == interestRate) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.minPayment, minPayment) ||
                other.minPayment == minPayment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.revision, revision) ||
                other.revision == revision));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    type,
    currentBalance,
    currency,
    interestRate,
    dueDate,
    minPayment,
    createdAt,
    updatedAt,
    notes,
    isDeleted,
    revision,
  );

  /// Create a copy of Liability
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiabilityImplCopyWith<_$LiabilityImpl> get copyWith =>
      __$$LiabilityImplCopyWithImpl<_$LiabilityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiabilityImplToJson(this);
  }
}

abstract class _Liability implements Liability {
  const factory _Liability({
    required final String id,
    required final String userId,
    required final String name,
    required final LiabilityType type,
    required final int currentBalance,
    final String currency,
    final double? interestRate,
    final DateTime? dueDate,
    final int? minPayment,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String? notes,
    final bool isDeleted,
    final int revision,
  }) = _$LiabilityImpl;

  factory _Liability.fromJson(Map<String, dynamic> json) =
      _$LiabilityImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  LiabilityType get type;
  @override
  int get currentBalance; // in cents
  @override
  String get currency;
  @override
  double? get interestRate;
  @override
  DateTime? get dueDate;
  @override
  int? get minPayment; // in cents
  // Metadata
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get notes; // Sync
  @override
  bool get isDeleted;
  @override
  int get revision;

  /// Create a copy of Liability
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiabilityImplCopyWith<_$LiabilityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
