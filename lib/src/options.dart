// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'file_io.dart';
import 'objectstore.dart';

class GitOptions {
  // The directory entry where the git checkout resides.
  Directory root;

  // Optional

  // Remote repository username
  String username;
  // Remote repository password
  String password;
  // Repository url
  String repoUrl;
  // Current branch name
  String branchName;

  // Git objectstore.
  ObjectStore store;

  String email;
  String commitMessage;
  String name;
  int depth;
  Function progressCallback;

  GitOptions(
      {this.root,
      this.repoUrl,
      this.depth,
      this.store,
      this.branchName,
      this.commitMessage,
      this.email,
      this.name,
      this.username,
      this.password});

  // TODO(grv): Specialize the verification for different api methods.
  bool verify() {
    return this.root != null;
  }
}
