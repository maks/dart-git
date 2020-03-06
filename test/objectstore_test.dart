// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'dart:async';

import 'files_mock.dart';
import '../lib/src/file_operations.dart';
import '../lib/src/objectstore.dart';

final String GIT_ROOT_DIRECTORY_PATH = 'test/data/git';

Future getGitDirectory() {
  return getPackageDirectoryEntry().then((Directory dir) {
    return dir.getDirectory(GIT_ROOT_DIRECTORY_PATH);
  });
}

Future copyTestGitDirectory(MockFileSystem fs) {
  return getGitDirectory().then((Directory gitDir) {
    return fs.root.createDirectory('.git').then((dst) {
      return FileOps.copyDirectory(gitDir, dst);
    });
  });
}

Future<ObjectStore> initStore(fs) {
  return copyTestGitDirectory(fs).then((Directory root) {
    ObjectStore store = new ObjectStore(fs.root);
    return store.load().then((_) => store);
  });
}

defineTests() {
  group('git.objectstore', () {
//    // TODO: this test is timing out
//    test('Load and init store from git test directory.', () {
//      MockFileSystem fs = new MockFileSystem();
//      return initStore(fs).then((ObjectStore store) {
//        return store.getHeadRef().then((ref) {
//          expect(ref, 'refs/heads/master');
//          return store.getHeadSha().then((sha) {
//            expect(sha, 'dc85576bd94bdcaff1bd60b0fb4cd032c8fa2c54');
//            return store.getCommitGraph([sha], 32).then(
//                (CommitGraph graph) {
//                  List<CommitObject> commits = graph.commits;
//                  expect(commits.length, 5);
//                  expect(commits[0].treeSha,
//                      "85933892cd114abc0c2a4b7b3a25cddc471cd09d");
//                  expect(commits[1].author.name, 'Gaurav Agarwal');
//                  expect(commits[2].committer.email, 'grv@chromium.org');
//                  expect(commits[3].parents[0],
//                      "b37cdb5d6021562511df7602d164a2a0dc9ae2f8");
//                  expect(commits[4].parents.length, 0);
//            });
//          });
//        });
//      });
//    });
  });
}
