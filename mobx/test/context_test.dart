import 'package:mobx/mobx.dart';
import 'package:test/test.dart';

void main() {
  group('ReactiveContext', () {
    test('comes with default config', () {
      final ctx = ReactiveContext();

      expect(ctx.config, equals(ReactiveConfig.main));
    });

    test('global onReactionError is invoked for reaction errors', () {
      var caught = false;

      final dispose = mainContext.onReactionError((_, rxn) {
        caught = true;
        expect(rxn.errorValue, isNotNull);
      });
      final dispose1 = autorun((_) => throw Exception('autorun FAIL'));

      expect(caught, isTrue);

      dispose();
      dispose1();
    });

    test('can change observables inside computed if there are no observers',
        () {
      final x = Observable(0);

      final c = Computed(() => x.value++);

      expect(() => c.value, returnsNormally);
    });

    test('cannot change observables inside computed if they have observers',
        () {
      final x = Observable(0);

      final c = Computed<int>(() => x.value++);

      expect(() {
        final d = autorun((_) => x.value);
        // Fetch the value which is in turn mutating the observable (x.value).
        // This is not allowed because there is an observer: autorun.
        c.value;
        d();
      }, throwsException);
    });

    test('throws Exception for reactions that do not converge', () {
      var firstTime = true;
      final a = Observable(0);
      final d = autorun((_) {
        a.value;
        if (firstTime) {
          firstTime = false;
          return;
        }

        // cyclic-dependency!!!
        // this autorun() will keep on getting triggered as a.value keeps changing
        // every time it's invoked
        runInAction(() {
          a.value = a.value + 1;
        });
      }, name: 'Cyclic Reaction');

      expect(() => runInAction(() => a.value = 1),
          throwsA(const TypeMatcher<MobXCyclicReactionException>()));
      d();
    });

    test('throws AssertionError if a name prefix is not provided', () {
      final context = createContext();

      expect(() => context.nameFor(null),
          throwsA(const TypeMatcher<AssertionError>()));
    });
  });

  group('ReactiveConfig', () {
    test('clone works', () {
      final config = ReactiveConfig.main;
      final clone = config.clone(maxIterations: 10);

      expect(clone.maxIterations, equals(10));
      expect(clone.maxIterations != config.maxIterations, isTrue);
      expect(clone.disableErrorBoundaries == config.disableErrorBoundaries,
          isTrue);
      expect(clone.writePolicy == config.writePolicy, isTrue);
      expect(clone.readPolicy == config.readPolicy, isTrue);
    });

    test('when no overrides are provided the clone reuses source values', () {
      final config = ReactiveConfig.main;
      final clone = config.clone(); // No change

      expect(clone.maxIterations, equals(config.maxIterations));
      expect(
          clone.disableErrorBoundaries, equals(config.disableErrorBoundaries));
      expect(clone.writePolicy, equals(config.writePolicy));
      expect(clone.readPolicy, equals(config.readPolicy));
    });
  });
}
