// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git.commands.revert;

import 'dart:async';
import 'package:dart_git/src/entry.dart';

import '../object.dart';
import '../options.dart';
import 'index.dart';
import 'status.dart';

/**
 * Reverts a given list of file entries to the git head state.
 */
class Revert {
  static Future revert(GitOptions options, List<FileEntry> entries) {
    return Future.forEach(entries, (entry) {
      return Status.updateAndGetStatus(options.store, entry)
          .then((FileStatus status) {
        return options.store.retrieveObjectBlobsAsString([status.headSha]).then(
            (List<LooseObject> objects) {
          return (entry as ChromeFileEntry).writeText(objects.first.data);
        });
      });
    });
  }
}
