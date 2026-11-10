// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetUserProgressCollection on Isar {
  IsarCollection<UserProgress> get userProgress => this.collection();
}

const UserProgressSchema = CollectionSchema(
  name: r'UserProgress',
  id: 518958300452706037,
  properties: {
    r'finishedLessonNames': PropertySchema(
      id: 0,
      name: r'finishedLessonNames',
      type: IsarType.stringList,
    ),
    r'totalBuildsCreated': PropertySchema(
      id: 1,
      name: r'totalBuildsCreated',
      type: IsarType.long,
    ),
  },

  estimateSize: _userProgressEstimateSize,
  serialize: _userProgressSerialize,
  deserialize: _userProgressDeserialize,
  deserializeProp: _userProgressDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _userProgressGetId,
  getLinks: _userProgressGetLinks,
  attach: _userProgressAttach,
  version: '3.4.1',
);

int _userProgressEstimateSize(
  UserProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.finishedLessonNames.length * 3;
  {
    for (var i = 0; i < object.finishedLessonNames.length; i++) {
      final value = object.finishedLessonNames[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _userProgressSerialize(
  UserProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.finishedLessonNames);
  writer.writeLong(offsets[1], object.totalBuildsCreated);
}

UserProgress _userProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserProgress();
  object.finishedLessonNames = reader.readStringList(offsets[0]) ?? [];
  object.id = id;
  object.totalBuildsCreated = reader.readLong(offsets[1]);
  return object;
}

P _userProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userProgressGetId(UserProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userProgressGetLinks(UserProgress object) {
  return [];
}

void _userProgressAttach(
  IsarCollection<dynamic> col,
  Id id,
  UserProgress object,
) {
  object.id = id;
}

extension UserProgressQueryWhereSort
    on QueryBuilder<UserProgress, UserProgress, QWhere> {
  QueryBuilder<UserProgress, UserProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserProgressQueryWhere
    on QueryBuilder<UserProgress, UserProgress, QWhereClause> {
  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension UserProgressQueryFilter
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {
  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'finishedLessonNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'finishedLessonNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'finishedLessonNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'finishedLessonNames',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'finishedLessonNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'finishedLessonNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'finishedLessonNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'finishedLessonNames',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'finishedLessonNames', value: ''),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'finishedLessonNames',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'finishedLessonNames',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'finishedLessonNames', 0, true, 0, true);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'finishedLessonNames', 0, false, 999999, true);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'finishedLessonNames', 0, true, length, include);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'finishedLessonNames',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  finishedLessonNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'finishedLessonNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  totalBuildsCreatedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalBuildsCreated', value: value),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  totalBuildsCreatedGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalBuildsCreated',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  totalBuildsCreatedLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalBuildsCreated',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
  totalBuildsCreatedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalBuildsCreated',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension UserProgressQueryObject
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {}

extension UserProgressQueryLinks
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {}

extension UserProgressQuerySortBy
    on QueryBuilder<UserProgress, UserProgress, QSortBy> {
  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
  sortByTotalBuildsCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBuildsCreated', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
  sortByTotalBuildsCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBuildsCreated', Sort.desc);
    });
  }
}

extension UserProgressQuerySortThenBy
    on QueryBuilder<UserProgress, UserProgress, QSortThenBy> {
  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
  thenByTotalBuildsCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBuildsCreated', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
  thenByTotalBuildsCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBuildsCreated', Sort.desc);
    });
  }
}

extension UserProgressQueryWhereDistinct
    on QueryBuilder<UserProgress, UserProgress, QDistinct> {
  QueryBuilder<UserProgress, UserProgress, QDistinct>
  distinctByFinishedLessonNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finishedLessonNames');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
  distinctByTotalBuildsCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalBuildsCreated');
    });
  }
}

extension UserProgressQueryProperty
    on QueryBuilder<UserProgress, UserProgress, QQueryProperty> {
  QueryBuilder<UserProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserProgress, List<String>, QQueryOperations>
  finishedLessonNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finishedLessonNames');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations>
  totalBuildsCreatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalBuildsCreated');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetBlockBuildCollection on Isar {
  IsarCollection<BlockBuild> get blockBuilds => this.collection();
}

const BlockBuildSchema = CollectionSchema(
  name: r'BlockBuild',
  id: 2256549593807844680,
  properties: {
    r'buildName': PropertySchema(
      id: 0,
      name: r'buildName',
      type: IsarType.string,
    ),
    r'imageBase64': PropertySchema(
      id: 1,
      name: r'imageBase64',
      type: IsarType.string,
    ),
    r'saveDate': PropertySchema(
      id: 2,
      name: r'saveDate',
      type: IsarType.dateTime,
    ),
    r'sceneDataJson': PropertySchema(
      id: 3,
      name: r'sceneDataJson',
      type: IsarType.string,
    ),
  },

  estimateSize: _blockBuildEstimateSize,
  serialize: _blockBuildSerialize,
  deserialize: _blockBuildDeserialize,
  deserializeProp: _blockBuildDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _blockBuildGetId,
  getLinks: _blockBuildGetLinks,
  attach: _blockBuildAttach,
  version: '3.4.1',
);

int _blockBuildEstimateSize(
  BlockBuild object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.buildName.length * 3;
  {
    final value = object.imageBase64;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sceneDataJson.length * 3;
  return bytesCount;
}

void _blockBuildSerialize(
  BlockBuild object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.buildName);
  writer.writeString(offsets[1], object.imageBase64);
  writer.writeDateTime(offsets[2], object.saveDate);
  writer.writeString(offsets[3], object.sceneDataJson);
}

BlockBuild _blockBuildDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BlockBuild();
  object.buildName = reader.readString(offsets[0]);
  object.id = id;
  object.imageBase64 = reader.readStringOrNull(offsets[1]);
  object.saveDate = reader.readDateTime(offsets[2]);
  object.sceneDataJson = reader.readString(offsets[3]);
  return object;
}

P _blockBuildDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _blockBuildGetId(BlockBuild object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _blockBuildGetLinks(BlockBuild object) {
  return [];
}

void _blockBuildAttach(IsarCollection<dynamic> col, Id id, BlockBuild object) {
  object.id = id;
}

extension BlockBuildQueryWhereSort
    on QueryBuilder<BlockBuild, BlockBuild, QWhere> {
  QueryBuilder<BlockBuild, BlockBuild, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BlockBuildQueryWhere
    on QueryBuilder<BlockBuild, BlockBuild, QWhereClause> {
  QueryBuilder<BlockBuild, BlockBuild, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BlockBuildQueryFilter
    on QueryBuilder<BlockBuild, BlockBuild, QFilterCondition> {
  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> buildNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'buildName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  buildNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'buildName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> buildNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'buildName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> buildNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'buildName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  buildNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'buildName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> buildNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'buildName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> buildNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'buildName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> buildNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'buildName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  buildNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'buildName', value: ''),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  buildNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'buildName', value: ''),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'imageBase64'),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'imageBase64'),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64EqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imageBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imageBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imageBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imageBase64',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imageBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64EndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imageBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imageBase64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imageBase64',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imageBase64', value: ''),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  imageBase64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imageBase64', value: ''),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> saveDateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'saveDate', value: value),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  saveDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'saveDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> saveDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'saveDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition> saveDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'saveDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sceneDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sceneDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sceneDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sceneDataJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sceneDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sceneDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sceneDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sceneDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sceneDataJson', value: ''),
      );
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterFilterCondition>
  sceneDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sceneDataJson', value: ''),
      );
    });
  }
}

extension BlockBuildQueryObject
    on QueryBuilder<BlockBuild, BlockBuild, QFilterCondition> {}

extension BlockBuildQueryLinks
    on QueryBuilder<BlockBuild, BlockBuild, QFilterCondition> {}

extension BlockBuildQuerySortBy
    on QueryBuilder<BlockBuild, BlockBuild, QSortBy> {
  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortByBuildName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildName', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortByBuildNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildName', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortByImageBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageBase64', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortByImageBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageBase64', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortBySaveDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveDate', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortBySaveDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveDate', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortBySceneDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneDataJson', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> sortBySceneDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneDataJson', Sort.desc);
    });
  }
}

extension BlockBuildQuerySortThenBy
    on QueryBuilder<BlockBuild, BlockBuild, QSortThenBy> {
  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenByBuildName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildName', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenByBuildNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'buildName', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenByImageBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageBase64', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenByImageBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageBase64', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenBySaveDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveDate', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenBySaveDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saveDate', Sort.desc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenBySceneDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneDataJson', Sort.asc);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QAfterSortBy> thenBySceneDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sceneDataJson', Sort.desc);
    });
  }
}

extension BlockBuildQueryWhereDistinct
    on QueryBuilder<BlockBuild, BlockBuild, QDistinct> {
  QueryBuilder<BlockBuild, BlockBuild, QDistinct> distinctByBuildName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'buildName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QDistinct> distinctByImageBase64({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageBase64', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QDistinct> distinctBySaveDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saveDate');
    });
  }

  QueryBuilder<BlockBuild, BlockBuild, QDistinct> distinctBySceneDataJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sceneDataJson',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension BlockBuildQueryProperty
    on QueryBuilder<BlockBuild, BlockBuild, QQueryProperty> {
  QueryBuilder<BlockBuild, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BlockBuild, String, QQueryOperations> buildNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'buildName');
    });
  }

  QueryBuilder<BlockBuild, String?, QQueryOperations> imageBase64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageBase64');
    });
  }

  QueryBuilder<BlockBuild, DateTime, QQueryOperations> saveDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saveDate');
    });
  }

  QueryBuilder<BlockBuild, String, QQueryOperations> sceneDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sceneDataJson');
    });
  }
}
