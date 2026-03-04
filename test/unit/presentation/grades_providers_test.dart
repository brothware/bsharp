import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Mark mark({
    int id = 1,
    int markGroupsId = 1,
    double? markValue = 5,
    int weight = 1,
    int? markScalesId,
  }) {
    return Mark(
      id: id,
      markGroupsId: markGroupsId,
      pupilUsersId: 1,
      teacherUsersId: 1,
      markValue: markValue,
      markScalesId: markScalesId,
      weight: weight,
      getDate: DateTime(2026, 2, 27),
      modified: 0,
    );
  }

  group('currentTermProvider', () {
    test('returns null when no terms', () {
      final container = ProviderContainer(
        overrides: [termsProvider.overrideWithBuild((ref, _) => [])],
      );
      addTearDown(container.dispose);
      expect(container.read(currentTermProvider), isNull);
    });

    test('returns selected term when id set', () {
      final term1 = Term(
        id: 1,
        name: 'Semester 1',
        type: TermType.semester,
        startDate: DateTime(2025, 9),
        endDate: DateTime(2026, 1, 31),
      );
      final term2 = Term(
        id: 2,
        name: 'Semester 2',
        type: TermType.semester,
        startDate: DateTime(2026, 2),
        endDate: DateTime(2026, 6, 30),
      );

      final container = ProviderContainer(
        overrides: [
          termsProvider.overrideWithBuild((ref, _) => [term1, term2]),
          selectedTermIdProvider.overrideWithBuild((ref, _) => 2),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentTermProvider)?.id, 2);
    });

    test('auto-selects current term by date', () {
      final past = Term(
        id: 1,
        name: 'Past',
        type: TermType.semester,
        startDate: DateTime(2025),
        endDate: DateTime(2025, 6, 30),
      );
      final current = Term(
        id: 2,
        name: 'Current',
        type: TermType.semester,
        startDate: DateTime(2025, 9),
        endDate: DateTime(2027, 6, 30),
      );

      final container = ProviderContainer(
        overrides: [
          termsProvider.overrideWithBuild((ref, _) => [past, current]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentTermProvider)?.id, 2);
    });

    test('falls back to first term', () {
      final term = Term(
        id: 1,
        name: 'Old',
        type: TermType.year,
        startDate: DateTime(2020, 9),
        endDate: DateTime(2021, 6, 30),
      );

      final container = ProviderContainer(
        overrides: [
          termsProvider.overrideWithBuild((ref, _) => [term]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentTermProvider)?.id, 1);
    });
  });

  group('subjectGradesProvider', () {
    test('returns empty list when no marks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(subjectGradesProvider), isEmpty);
    });

    test('groups marks by subject via mark groups', () {
      final container = ProviderContainer(
        overrides: [
          marksProvider.overrideWithBuild(
            (ref, _) => [
              mark(markGroupsId: 10),
              mark(id: 2, markGroupsId: 10, markValue: 4),
              mark(id: 3, markGroupsId: 20, markValue: 3),
            ],
          ),
          markGroupsProvider.overrideWithBuild(
            (ref, _) => [
              const MarkGroup(
                id: 10,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 500,
              ),
              const MarkGroup(
                id: 20,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 501,
              ),
            ],
          ),
          eventTypeTermsProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
              const EventTypeTerm(id: 501, termsId: 1, eventTypesId: 249),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 248,
                subjectsId: 100,
                teachingLevel: 0,
                substitution: 0,
              ),
              const EventType(
                id: 249,
                subjectsId: 200,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(
                id: 100,
                subjectsEduId: 100,
                name: 'Math',
                abbr: 'MAT',
              ),
              const Subject(
                id: 200,
                subjectsEduId: 200,
                name: 'Polish',
                abbr: 'POL',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      expect(result.length, 2);

      final math = result.firstWhere((sg) => sg.subjectName == 'Math');
      expect(math.resolvedMarks.length, 2);

      final polish = result.firstWhere((sg) => sg.subjectName == 'Polish');
      expect(polish.resolvedMarks.length, 1);
    });

    test(
      'resolves scale-based marks with abbreviation and effective value',
      () {
        final container = ProviderContainer(
          overrides: [
            marksProvider.overrideWithBuild(
              (ref, _) => [mark(markGroupsId: 10, markScalesId: 118)],
            ),
            markGroupsProvider.overrideWithBuild(
              (ref, _) => [
                const MarkGroup(
                  id: 10,
                  isPattern: 0,
                  markType: 1,
                  visibility: 1,
                  position: 0,
                  eventTypeTermsId: 500,
                ),
              ],
            ),
            markScalesProvider.overrideWithBuild(
              (ref, _) => [
                const MarkScale(
                  id: 118,
                  markScaleGroupsId: 10,
                  abbreviation: '4+',
                  name: 'B plus',
                  markValue: 4.5,
                  classified: 1,
                  noCountToAverage: 0,
                ),
              ],
            ),
            eventTypeTermsProvider.overrideWithBuild(
              (ref, _) => [
                const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
              ],
            ),
            eventTypesProvider.overrideWithBuild(
              (ref, _) => [
                const EventType(
                  id: 248,
                  subjectsId: 100,
                  teachingLevel: 0,
                  substitution: 0,
                ),
              ],
            ),
            subjectsProvider.overrideWithBuild(
              (ref, _) => [
                const Subject(
                  id: 100,
                  subjectsEduId: 100,
                  name: 'Music',
                  abbr: 'MUZ',
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(subjectGradesProvider);
        expect(result.length, 1);
        final rm = result.first.resolvedMarks.first;
        expect(rm.displayValue, '4+');
        expect(rm.effectiveValue, 4.5);
      },
    );

    test('resolves point-based marks with value/max format', () {
      final container = ProviderContainer(
        overrides: [
          marksProvider.overrideWithBuild(
            (ref, _) => [mark(markGroupsId: 10, markValue: 8)],
          ),
          markGroupsProvider.overrideWithBuild(
            (ref, _) => [
              const MarkGroup(
                id: 10,
                isPattern: 0,
                markType: 2,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 500,
                markValueRangeMax: 10,
              ),
            ],
          ),
          eventTypeTermsProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 248,
                subjectsId: 100,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(
                id: 100,
                subjectsEduId: 100,
                name: 'Education',
                abbr: 'EDU',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      final rm = result.first.resolvedMarks.first;
      expect(rm.displayValue, '8/10');
      expect(rm.isPointBased, true);
    });

    test('sorts subjects alphabetically', () {
      final container = ProviderContainer(
        overrides: [
          marksProvider.overrideWithBuild(
            (ref, _) => [mark(markGroupsId: 10), mark(id: 2, markGroupsId: 20)],
          ),
          markGroupsProvider.overrideWithBuild(
            (ref, _) => [
              const MarkGroup(
                id: 10,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 500,
              ),
              const MarkGroup(
                id: 20,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 501,
              ),
            ],
          ),
          eventTypeTermsProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
              const EventTypeTerm(id: 501, termsId: 1, eventTypesId: 249),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 248,
                subjectsId: 200,
                teachingLevel: 0,
                substitution: 0,
              ),
              const EventType(
                id: 249,
                subjectsId: 100,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(
                id: 100,
                subjectsEduId: 100,
                name: 'English',
                abbr: 'ANG',
              ),
              const Subject(
                id: 200,
                subjectsEduId: 200,
                name: 'Biology',
                abbr: 'BIO',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      expect(result[0].subjectName, 'Biology');
      expect(result[1].subjectName, 'English');
    });

    test('sorts marks by date descending within subject', () {
      final container = ProviderContainer(
        overrides: [
          marksProvider.overrideWithBuild(
            (ref, _) => [
              mark(markGroupsId: 10, markValue: 3),
              Mark(
                id: 2,
                markGroupsId: 10,
                pupilUsersId: 1,
                teacherUsersId: 1,
                markValue: 5,
                getDate: DateTime(2026, 3),
                modified: 0,
              ),
            ],
          ),
          markGroupsProvider.overrideWithBuild(
            (ref, _) => [
              const MarkGroup(
                id: 10,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 500,
              ),
            ],
          ),
          eventTypeTermsProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 248,
                subjectsId: 100,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(
                id: 100,
                subjectsEduId: 100,
                name: 'Math',
                abbr: 'MAT',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      expect(result.first.resolvedMarks.first.mark.id, 2);
    });
  });

  group('overallWeightedAverageProvider', () {
    test('returns null when no subjects', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(overallWeightedAverageProvider), isNull);
    });

    test('calculates mean of subject weighted averages', () {
      final container = ProviderContainer(
        overrides: [
          marksProvider.overrideWithBuild(
            (ref, _) => [
              mark(markGroupsId: 10),
              mark(id: 2, markGroupsId: 20, markValue: 3),
            ],
          ),
          markGroupsProvider.overrideWithBuild(
            (ref, _) => [
              const MarkGroup(
                id: 10,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 500,
              ),
              const MarkGroup(
                id: 20,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 501,
              ),
            ],
          ),
          eventTypeTermsProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
              const EventTypeTerm(id: 501, termsId: 1, eventTypesId: 249),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 248,
                subjectsId: 100,
                teachingLevel: 0,
                substitution: 0,
              ),
              const EventType(
                id: 249,
                subjectsId: 200,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(id: 100, subjectsEduId: 100, name: 'A', abbr: 'A'),
              const Subject(id: 200, subjectsEduId: 200, name: 'B', abbr: 'B'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(overallWeightedAverageProvider), 4.0);
    });
  });

  group('overallSimpleAverageProvider', () {
    test('returns null when no subjects', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(overallSimpleAverageProvider), isNull);
    });
  });

  group('gradeDistributionProvider', () {
    test('returns empty map for no marks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(gradeDistributionProvider), isEmpty);
    });

    test('counts by rounded effective value', () {
      final container = ProviderContainer(
        overrides: [
          marksProvider.overrideWithBuild(
            (ref, _) => [
              mark(markGroupsId: 10),
              mark(id: 2, markGroupsId: 10),
              mark(id: 3, markGroupsId: 10, markValue: 4),
            ],
          ),
          markGroupsProvider.overrideWithBuild(
            (ref, _) => [
              const MarkGroup(
                id: 10,
                isPattern: 0,
                markType: 1,
                visibility: 1,
                position: 0,
                eventTypeTermsId: 500,
              ),
            ],
          ),
          eventTypeTermsProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTerm(id: 500, termsId: 1, eventTypesId: 248),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 248,
                subjectsId: 100,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(id: 100, subjectsEduId: 100, name: 'A', abbr: 'A'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final dist = container.read(gradeDistributionProvider);
      expect(dist['5'], 2);
      expect(dist['4'], 1);
    });
  });
}
