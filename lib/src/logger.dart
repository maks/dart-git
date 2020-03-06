// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
import 'dart:async';
import 'package:path/path.dart' as p;
import 'constants.dart';
import 'file_io.dart';
import 'options.dart';
import 'utils.dart';

/**
 * Logs the git commands. These logs are consumend in restoring git state.
 */
class Logger {
  static Future<File> log(
      GitOptions options, String fromSha, String toSha, String message) async {
    String dateString = getCurrentTimeAsString();
    String logString = [
      fromSha,
      toSha,
      options.username,
      '<${options.email}}>',
      dateString,
      message
    ].join(" ");
    logString += '\n';

    // make sure logs dir exists first
    final logDir =
        await Directory(p.join(options.root.path, LOGS_DIR)).create();

    return File(p.join(logDir.path, 'HEAD'))
        .writeAsString(logString, mode: FileMode.append);
  }
}
