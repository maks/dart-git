// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * General utilities for testing the git library.
 */
import 'dart:async';
import 'dart:math' show Random;

import 'package:dart_git/src/file_io.dart';

final String sampleRepoUrl = 'https://github.com/maks/sandbox.git';

class GitLocation {
  String _name;
  Directory entry;

  GitLocation() {
    Random r = new Random();
    _name = 'git_${r.nextInt(100)}';
  }

  String get name => _name;

  Future init() {
    // Create `git/git_xxx`. Delete the directory if it already exists.
    return getLocalDataDir('git').then((Directory gitDir) {
      return gitDir.getDirectory(name).then((dir) {
        return _safeDelete(dir).then((_) {
          return gitDir.createDirectory(name).then((d) {
            entry = d;
          });
        });
      }).catchError((e) {
        return gitDir.createDirectory(name).then((d) {
          entry = d;
        });
      });
    });
  }

  Future dispose() {
    return new Future.value();
  }

  Future _safeDelete(Directory dir) {
    return dir.removeRecursively().catchError((e) => null);
  }
}
