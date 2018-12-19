// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git.commands.push;

import 'dart:async';

import '../config.dart';
import '../exception.dart';
import '../http_fetcher.dart';
import '../object.dart';
import '../objectstore.dart';
import '../options.dart';
import '../pack.dart';
import '../utils.dart';


/**
 * This class implements the git push command.
 */
class Push {

  static Future push(GitOptions options) {
    ObjectStore store = options.store;
    String username = options.username;
    String password = options.password;

    Function pushProgress;

    if (options.progressCallback != null) {
      // TODO(grv): Add progress chunker.
    } else {
      pushProgress = nopFunction;
    }

    Config config = store.config;
    String url = config.url != null ? config.url : options.repoUrl;

    if (url == null) {
      return new Future.error(
        new GitException(GitErrorConstants.GIT_PUSH_NO_REMOTE));
    }

    // Currently only pushing to 'origin' is supported.
    HttpFetcher fetcher = new HttpFetcher(store, 'origin', url, username,
        password);
    return fetcher.fetchReceiveRefs().then((List<GitRef> refs) {
      return store.getCommitsForPush(refs, config.remoteHeads).then(
          (CommitPushEntry pushEntry) {
        if (pushEntry == null) {
          return new Future.error(
            new GitException(GitErrorConstants.GIT_PUSH_NO_COMMITS));
        }
        PackBuilder builder = new PackBuilder(pushEntry.commits, store);
        return builder.build().then((List<int> packData) {
          return fetcher.pushRefs([pushEntry.ref], packData, pushProgress).then((_) {
            config.remoteHeads[pushEntry.ref.name] = pushEntry.ref.head;
            config.url = url;
            return store.writeConfig();
          });
        });
      });
    });
  }

  static Future<List<CommitObject>> getPendingCommits(GitOptions options) {
    ObjectStore store = options.store;
    Config config = store.config;
    String username = options.username;
    String password = options.password;

    String url = config.url != null ? config.url : options.repoUrl;

    if (url == null) {
      return new Future.error(
       new GitException(GitErrorConstants.GIT_PUSH_NO_REMOTE));
    }

   HttpFetcher fetcher = new HttpFetcher(store, 'origin', url, username, password);
   return fetcher.fetchReceiveRefs().then((List<GitRef> refs) {
     return store.getCommitsForPush(refs, config.remoteHeads).then(
         (CommitPushEntry pushEntry) => pushEntry.commits);
   });
 }
}
