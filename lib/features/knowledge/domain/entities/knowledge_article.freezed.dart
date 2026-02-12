// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'knowledge_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

KnowledgeArticle _$KnowledgeArticleFromJson(Map<String, dynamic> json) {
  return _KnowledgeArticle.fromJson(json);
}

/// @nodoc
mixin _$KnowledgeArticle {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get topic =>
      throw _privateConstructorUsedError; // e.g., 'budgeting', 'investing', 'savings'
  List<String> get tags => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  int get readTimeMinutes => throw _privateConstructorUsedError;
  String get languageCode => throw _privateConstructorUsedError;
  bool get isPremium => throw _privateConstructorUsedError;
  DateTime get publishedAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this KnowledgeArticle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KnowledgeArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KnowledgeArticleCopyWith<KnowledgeArticle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KnowledgeArticleCopyWith<$Res> {
  factory $KnowledgeArticleCopyWith(
    KnowledgeArticle value,
    $Res Function(KnowledgeArticle) then,
  ) = _$KnowledgeArticleCopyWithImpl<$Res, KnowledgeArticle>;
  @useResult
  $Res call({
    String id,
    String title,
    String summary,
    String content,
    String topic,
    List<String> tags,
    String? imageUrl,
    int readTimeMinutes,
    String languageCode,
    bool isPremium,
    DateTime publishedAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$KnowledgeArticleCopyWithImpl<$Res, $Val extends KnowledgeArticle>
    implements $KnowledgeArticleCopyWith<$Res> {
  _$KnowledgeArticleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KnowledgeArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? summary = null,
    Object? content = null,
    Object? topic = null,
    Object? tags = null,
    Object? imageUrl = freezed,
    Object? readTimeMinutes = null,
    Object? languageCode = null,
    Object? isPremium = null,
    Object? publishedAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            topic: null == topic
                ? _value.topic
                : topic // ignore: cast_nullable_to_non_nullable
                      as String,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            readTimeMinutes: null == readTimeMinutes
                ? _value.readTimeMinutes
                : readTimeMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            languageCode: null == languageCode
                ? _value.languageCode
                : languageCode // ignore: cast_nullable_to_non_nullable
                      as String,
            isPremium: null == isPremium
                ? _value.isPremium
                : isPremium // ignore: cast_nullable_to_non_nullable
                      as bool,
            publishedAt: null == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KnowledgeArticleImplCopyWith<$Res>
    implements $KnowledgeArticleCopyWith<$Res> {
  factory _$$KnowledgeArticleImplCopyWith(
    _$KnowledgeArticleImpl value,
    $Res Function(_$KnowledgeArticleImpl) then,
  ) = __$$KnowledgeArticleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String summary,
    String content,
    String topic,
    List<String> tags,
    String? imageUrl,
    int readTimeMinutes,
    String languageCode,
    bool isPremium,
    DateTime publishedAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$KnowledgeArticleImplCopyWithImpl<$Res>
    extends _$KnowledgeArticleCopyWithImpl<$Res, _$KnowledgeArticleImpl>
    implements _$$KnowledgeArticleImplCopyWith<$Res> {
  __$$KnowledgeArticleImplCopyWithImpl(
    _$KnowledgeArticleImpl _value,
    $Res Function(_$KnowledgeArticleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KnowledgeArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? summary = null,
    Object? content = null,
    Object? topic = null,
    Object? tags = null,
    Object? imageUrl = freezed,
    Object? readTimeMinutes = null,
    Object? languageCode = null,
    Object? isPremium = null,
    Object? publishedAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$KnowledgeArticleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        topic: null == topic
            ? _value.topic
            : topic // ignore: cast_nullable_to_non_nullable
                  as String,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        readTimeMinutes: null == readTimeMinutes
            ? _value.readTimeMinutes
            : readTimeMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        languageCode: null == languageCode
            ? _value.languageCode
            : languageCode // ignore: cast_nullable_to_non_nullable
                  as String,
        isPremium: null == isPremium
            ? _value.isPremium
            : isPremium // ignore: cast_nullable_to_non_nullable
                  as bool,
        publishedAt: null == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KnowledgeArticleImpl implements _KnowledgeArticle {
  const _$KnowledgeArticleImpl({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.topic,
    required final List<String> tags,
    required this.imageUrl,
    this.readTimeMinutes = 0,
    this.languageCode = 'en',
    this.isPremium = false,
    required this.publishedAt,
    required this.updatedAt,
  }) : _tags = tags;

  factory _$KnowledgeArticleImpl.fromJson(Map<String, dynamic> json) =>
      _$$KnowledgeArticleImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String summary;
  @override
  final String content;
  @override
  final String topic;
  // e.g., 'budgeting', 'investing', 'savings'
  final List<String> _tags;
  // e.g., 'budgeting', 'investing', 'savings'
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final int readTimeMinutes;
  @override
  @JsonKey()
  final String languageCode;
  @override
  @JsonKey()
  final bool isPremium;
  @override
  final DateTime publishedAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'KnowledgeArticle(id: $id, title: $title, summary: $summary, content: $content, topic: $topic, tags: $tags, imageUrl: $imageUrl, readTimeMinutes: $readTimeMinutes, languageCode: $languageCode, isPremium: $isPremium, publishedAt: $publishedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KnowledgeArticleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.readTimeMinutes, readTimeMinutes) ||
                other.readTimeMinutes == readTimeMinutes) &&
            (identical(other.languageCode, languageCode) ||
                other.languageCode == languageCode) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    summary,
    content,
    topic,
    const DeepCollectionEquality().hash(_tags),
    imageUrl,
    readTimeMinutes,
    languageCode,
    isPremium,
    publishedAt,
    updatedAt,
  );

  /// Create a copy of KnowledgeArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KnowledgeArticleImplCopyWith<_$KnowledgeArticleImpl> get copyWith =>
      __$$KnowledgeArticleImplCopyWithImpl<_$KnowledgeArticleImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$KnowledgeArticleImplToJson(this);
  }
}

abstract class _KnowledgeArticle implements KnowledgeArticle {
  const factory _KnowledgeArticle({
    required final String id,
    required final String title,
    required final String summary,
    required final String content,
    required final String topic,
    required final List<String> tags,
    required final String? imageUrl,
    final int readTimeMinutes,
    final String languageCode,
    final bool isPremium,
    required final DateTime publishedAt,
    required final DateTime updatedAt,
  }) = _$KnowledgeArticleImpl;

  factory _KnowledgeArticle.fromJson(Map<String, dynamic> json) =
      _$KnowledgeArticleImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get summary;
  @override
  String get content;
  @override
  String get topic; // e.g., 'budgeting', 'investing', 'savings'
  @override
  List<String> get tags;
  @override
  String? get imageUrl;
  @override
  int get readTimeMinutes;
  @override
  String get languageCode;
  @override
  bool get isPremium;
  @override
  DateTime get publishedAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of KnowledgeArticle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KnowledgeArticleImplCopyWith<_$KnowledgeArticleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
