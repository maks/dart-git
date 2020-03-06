// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:dart_git/src/commands/clone.dart';
import 'package:dart_git/src/logger.dart';
import 'package:test/test.dart';

defineTests() {
  group('git.logger', () {
    test('creates file if it doesnt exist', () async {
      final options = GitOptions();
      String fromSha = '';
      String toSha = '';
      String mesg = 'a test';
      final logFile = await Logger.log(options, fromSha, toSha, mesg);

      expect(logFile.existsSync(), isTrue);
    });
  });
}
