// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:intl/intl.dart';

final NumberFormat _nf = new NumberFormat.decimalPattern();

/**
 * A simple class to do `print()` profiling. It is used to profile a single
 * operation, and can time multiple sequential tasks within that operation.
 * Each call to [emit] reset the task timer, but does not effect the operation
 * timer. Call [finish] when the whole operation is complete.
 */
class PrintProfiler {
  final String name;
  final bool printToStdout;

  int _previousTaskTime = 0;
  Stopwatch _stopwatch = new Stopwatch();

  /**
   * Create a profiler to time a single operation (`name`).
   */
  PrintProfiler(this.name, {this.printToStdout: false}) {
    _stopwatch.start();
  }

  /**
   * The elapsed time for the current task.
   */
  int currentElapsedMs() => _stopwatch.elapsedMilliseconds;

  /**
   * Finish the current task and print out that task's elapsed time.
   */
  String finishCurrentTask(String taskName) {
    _stopwatch.stop();
    int ms = _stopwatch.elapsedMilliseconds;
    _previousTaskTime += ms;
    _stopwatch.reset();
    _stopwatch.start();
    String output = '${name}, ${taskName} ${_nf.format(ms)}ms';
    if (printToStdout) print(output);
    return output;
  }

  /**
   * Stop the timer, and print out the total time for the operation.
   */
  String finishProfiler() {
    _stopwatch.stop();
    String output = '${name} total: ${_nf.format(totalElapsedMs())}ms';
    if (printToStdout) print(output);
    return output;
  }

  /**
   * The elapsed time for the whole operation.
   */
  int totalElapsedMs() => _previousTaskTime + _stopwatch.elapsedMilliseconds;
}