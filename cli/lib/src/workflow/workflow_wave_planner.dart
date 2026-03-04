import 'workflow_context.dart';

/// A group of steps that can execute concurrently.
class Wave {
  const Wave(this.stepIndices);

  /// 0-based indices of steps in this wave.
  final List<int> stepIndices;

  int get length => stepIndices.length;
}

/// Groups workflow steps into concurrent waves using topological levels.
///
/// Steps with no dependencies form wave 0. Steps whose dependencies are all
/// in earlier waves form the next wave, and so on.
///
/// Algorithm:
/// ```
/// level[i] = 0                                if deps[i] is empty
/// level[i] = max(level[j] for j in deps[i]) + 1  otherwise
/// ```
class WavePlanner {
  const WavePlanner();

  /// Plans execution waves from the given step entries.
  ///
  /// Returns a list of [Wave]s in execution order. Steps within each wave
  /// are independent and can run in parallel.
  List<Wave> plan(List<WorkflowStepEntry> steps) {
    if (steps.isEmpty) return const [];

    // Compute level for each step
    final levels = List.filled(steps.length, 0);

    for (var i = 0; i < steps.length; i++) {
      final deps = steps[i].needs;
      if (deps.isEmpty) {
        levels[i] = 0;
      } else {
        var maxLevel = 0;
        for (final dep in deps) {
          if (dep >= 0 && dep < steps.length) {
            if (levels[dep] > maxLevel) {
              maxLevel = levels[dep];
            }
          }
        }
        levels[i] = maxLevel + 1;
      }
    }

    // Group by level
    final maxLevel = levels.fold(0, (a, b) => a > b ? a : b);
    final waves = <Wave>[];
    for (var level = 0; level <= maxLevel; level++) {
      final indices = <int>[];
      for (var i = 0; i < steps.length; i++) {
        if (levels[i] == level) {
          indices.add(i);
        }
      }
      if (indices.isNotEmpty) {
        waves.add(Wave(indices));
      }
    }

    return waves;
  }
}
