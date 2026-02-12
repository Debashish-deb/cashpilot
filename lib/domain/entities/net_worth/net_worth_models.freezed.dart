// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'net_worth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NetWorthHistoryPoint _$NetWorthHistoryPointFromJson(Map<String, dynamic> json) {
  return _NetWorthHistoryPoint.fromJson(json);
}

/// @nodoc
mixin _$NetWorthHistoryPoint {
  DateTime get date => throw _privateConstructorUsedError;
  int get valueCents => throw _privateConstructorUsedError;

  /// Serializes this NetWorthHistoryPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NetWorthHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetWorthHistoryPointCopyWith<NetWorthHistoryPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetWorthHistoryPointCopyWith<$Res> {
  factory $NetWorthHistoryPointCopyWith(
    NetWorthHistoryPoint value,
    $Res Function(NetWorthHistoryPoint) then,
  ) = _$NetWorthHistoryPointCopyWithImpl<$Res, NetWorthHistoryPoint>;
  @useResult
  $Res call({DateTime date, int valueCents});
}

/// @nodoc
class _$NetWorthHistoryPointCopyWithImpl<
  $Res,
  $Val extends NetWorthHistoryPoint
>
    implements $NetWorthHistoryPointCopyWith<$Res> {
  _$NetWorthHistoryPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetWorthHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? valueCents = null}) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            valueCents: null == valueCents
                ? _value.valueCents
                : valueCents // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NetWorthHistoryPointImplCopyWith<$Res>
    implements $NetWorthHistoryPointCopyWith<$Res> {
  factory _$$NetWorthHistoryPointImplCopyWith(
    _$NetWorthHistoryPointImpl value,
    $Res Function(_$NetWorthHistoryPointImpl) then,
  ) = __$$NetWorthHistoryPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, int valueCents});
}

/// @nodoc
class __$$NetWorthHistoryPointImplCopyWithImpl<$Res>
    extends _$NetWorthHistoryPointCopyWithImpl<$Res, _$NetWorthHistoryPointImpl>
    implements _$$NetWorthHistoryPointImplCopyWith<$Res> {
  __$$NetWorthHistoryPointImplCopyWithImpl(
    _$NetWorthHistoryPointImpl _value,
    $Res Function(_$NetWorthHistoryPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NetWorthHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? valueCents = null}) {
    return _then(
      _$NetWorthHistoryPointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        valueCents: null == valueCents
            ? _value.valueCents
            : valueCents // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NetWorthHistoryPointImpl implements _NetWorthHistoryPoint {
  const _$NetWorthHistoryPointImpl({
    required this.date,
    required this.valueCents,
  });

  factory _$NetWorthHistoryPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetWorthHistoryPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final int valueCents;

  @override
  String toString() {
    return 'NetWorthHistoryPoint(date: $date, valueCents: $valueCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetWorthHistoryPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.valueCents, valueCents) ||
                other.valueCents == valueCents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, valueCents);

  /// Create a copy of NetWorthHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetWorthHistoryPointImplCopyWith<_$NetWorthHistoryPointImpl>
  get copyWith =>
      __$$NetWorthHistoryPointImplCopyWithImpl<_$NetWorthHistoryPointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NetWorthHistoryPointImplToJson(this);
  }
}

abstract class _NetWorthHistoryPoint implements NetWorthHistoryPoint {
  const factory _NetWorthHistoryPoint({
    required final DateTime date,
    required final int valueCents,
  }) = _$NetWorthHistoryPointImpl;

  factory _NetWorthHistoryPoint.fromJson(Map<String, dynamic> json) =
      _$NetWorthHistoryPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  int get valueCents;

  /// Create a copy of NetWorthHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetWorthHistoryPointImplCopyWith<_$NetWorthHistoryPointImpl>
  get copyWith => throw _privateConstructorUsedError;
}

NetWorthSummaryData _$NetWorthSummaryDataFromJson(Map<String, dynamic> json) {
  return _NetWorthSummaryData.fromJson(json);
}

/// @nodoc
mixin _$NetWorthSummaryData {
  int get totalAssets => throw _privateConstructorUsedError;
  int get totalLiabilities => throw _privateConstructorUsedError;
  int get netWorth => throw _privateConstructorUsedError;

  /// Serializes this NetWorthSummaryData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NetWorthSummaryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetWorthSummaryDataCopyWith<NetWorthSummaryData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetWorthSummaryDataCopyWith<$Res> {
  factory $NetWorthSummaryDataCopyWith(
    NetWorthSummaryData value,
    $Res Function(NetWorthSummaryData) then,
  ) = _$NetWorthSummaryDataCopyWithImpl<$Res, NetWorthSummaryData>;
  @useResult
  $Res call({int totalAssets, int totalLiabilities, int netWorth});
}

/// @nodoc
class _$NetWorthSummaryDataCopyWithImpl<$Res, $Val extends NetWorthSummaryData>
    implements $NetWorthSummaryDataCopyWith<$Res> {
  _$NetWorthSummaryDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetWorthSummaryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAssets = null,
    Object? totalLiabilities = null,
    Object? netWorth = null,
  }) {
    return _then(
      _value.copyWith(
            totalAssets: null == totalAssets
                ? _value.totalAssets
                : totalAssets // ignore: cast_nullable_to_non_nullable
                      as int,
            totalLiabilities: null == totalLiabilities
                ? _value.totalLiabilities
                : totalLiabilities // ignore: cast_nullable_to_non_nullable
                      as int,
            netWorth: null == netWorth
                ? _value.netWorth
                : netWorth // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NetWorthSummaryDataImplCopyWith<$Res>
    implements $NetWorthSummaryDataCopyWith<$Res> {
  factory _$$NetWorthSummaryDataImplCopyWith(
    _$NetWorthSummaryDataImpl value,
    $Res Function(_$NetWorthSummaryDataImpl) then,
  ) = __$$NetWorthSummaryDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int totalAssets, int totalLiabilities, int netWorth});
}

/// @nodoc
class __$$NetWorthSummaryDataImplCopyWithImpl<$Res>
    extends _$NetWorthSummaryDataCopyWithImpl<$Res, _$NetWorthSummaryDataImpl>
    implements _$$NetWorthSummaryDataImplCopyWith<$Res> {
  __$$NetWorthSummaryDataImplCopyWithImpl(
    _$NetWorthSummaryDataImpl _value,
    $Res Function(_$NetWorthSummaryDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NetWorthSummaryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAssets = null,
    Object? totalLiabilities = null,
    Object? netWorth = null,
  }) {
    return _then(
      _$NetWorthSummaryDataImpl(
        totalAssets: null == totalAssets
            ? _value.totalAssets
            : totalAssets // ignore: cast_nullable_to_non_nullable
                  as int,
        totalLiabilities: null == totalLiabilities
            ? _value.totalLiabilities
            : totalLiabilities // ignore: cast_nullable_to_non_nullable
                  as int,
        netWorth: null == netWorth
            ? _value.netWorth
            : netWorth // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NetWorthSummaryDataImpl implements _NetWorthSummaryData {
  const _$NetWorthSummaryDataImpl({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });

  factory _$NetWorthSummaryDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetWorthSummaryDataImplFromJson(json);

  @override
  final int totalAssets;
  @override
  final int totalLiabilities;
  @override
  final int netWorth;

  @override
  String toString() {
    return 'NetWorthSummaryData(totalAssets: $totalAssets, totalLiabilities: $totalLiabilities, netWorth: $netWorth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetWorthSummaryDataImpl &&
            (identical(other.totalAssets, totalAssets) ||
                other.totalAssets == totalAssets) &&
            (identical(other.totalLiabilities, totalLiabilities) ||
                other.totalLiabilities == totalLiabilities) &&
            (identical(other.netWorth, netWorth) ||
                other.netWorth == netWorth));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalAssets, totalLiabilities, netWorth);

  /// Create a copy of NetWorthSummaryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetWorthSummaryDataImplCopyWith<_$NetWorthSummaryDataImpl> get copyWith =>
      __$$NetWorthSummaryDataImplCopyWithImpl<_$NetWorthSummaryDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NetWorthSummaryDataImplToJson(this);
  }
}

abstract class _NetWorthSummaryData implements NetWorthSummaryData {
  const factory _NetWorthSummaryData({
    required final int totalAssets,
    required final int totalLiabilities,
    required final int netWorth,
  }) = _$NetWorthSummaryDataImpl;

  factory _NetWorthSummaryData.fromJson(Map<String, dynamic> json) =
      _$NetWorthSummaryDataImpl.fromJson;

  @override
  int get totalAssets;
  @override
  int get totalLiabilities;
  @override
  int get netWorth;

  /// Create a copy of NetWorthSummaryData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetWorthSummaryDataImplCopyWith<_$NetWorthSummaryDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
