// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git.commands.clone;

import 'dart:async';

import 'package:chrome/chrome_app.dart' as chrome;

import '../config.dart';
import '../constants.dart';
import '../exception.dart';
import '../file_operations.dart';
import '../http_fetcher.dart';
import '../objectstore.dart';
import '../object_utils.dart';
import '../options.dart';
import '../pack.dart';
import '../profiler.dart';
import '../upload_pack_parser.dart';
import '../utils.dart';

export '../options.dart';

/**
 * This class implements the git clone command.
 */
class Clone {
  PrintProfiler _stopwatch;

  Cancel _cancel;

  GitOptions _options;

  Clone(this._options) {
    if (_options.branchName == null) _options.branchName = 'master';
    if (_options.progressCallback == null) {
      _options.progressCallback = nopFunction;
    }

    _cancel = new CloneCancel();
  }

  chrome.DirectoryEntry get root => _options.root;

  ObjectStore get store => _options.store;

  /**
   * This function is exposed for mocking purpose.
   */
  HttpFetcher getHttpFetcher(ObjectStore store, String origin, String url,
      String username, String password) {
    return new HttpFetcher(store, origin, url, username, password);
  }

  Future clone() {
    _stopwatch = new PrintProfiler('clone');
    return _clone();
  }

  Future _clone() {
    HttpFetcher fetcher = getHttpFetcher(_options.store, "origin",
        _options.repoUrl, _options.username, _options.password);

    return fetcher.isValidRepoUrl().then((isValid) {
      if (isValid) {
        return startClone(fetcher).catchError((e) {
          _cleanup();
          throw e;
        });
      } else if (!_options.repoUrl.endsWith('.git')) {
        _options.repoUrl += '.git';
        return _clone();
      } else {
        throw new GitException(GitErrorConstants.GIT_INVALID_REPO_URL);
      }
    });
  }

  /**
   * Public for testing purpose.
   */
  Future startClone(HttpFetcher fetcher) {
    return _checkDirectory(root, store, true).then((_) {
      return _options.root.createDirectory(".git").then(
          (chrome.DirectoryEntry gitDir) {
        return _callMethod(fetcher.fetchUploadRefs,[]).then((List<GitRef> refs) {
          logger.info(_stopwatch.finishCurrentTask('fetchUploadRefs'));

          if (refs.isEmpty) {
            return _createInitialConfig(null, null);
          }

          GitRef remoteHeadRef, localHeadRef;
          String remoteHead;

          return _callMethod(store.writeRemoteRefs, [refs]).then((_) {
            refs.forEach((GitRef ref) {
              if (ref.name == "HEAD") {
                remoteHead = ref.sha;
              } else if (ref.name == REFS_HEADS + _options.branchName) {
                localHeadRef = ref;
              } else if (ref.name.indexOf(REFS_HEADS) == 0) {
                if (ref.sha == remoteHead) {
                  remoteHeadRef = ref;
                }
              }
            });

            if (localHeadRef == null) {
              if (_options.branchName == null) {
                //REMOTE_BRANCH_NOT_FOUND;
                return null;
              } else {
                localHeadRef = remoteHeadRef;
              }
            }

            logger.info(_stopwatch.finishCurrentTask('_writeRefs'));

            return _callMethod(_processClone, [gitDir, localHeadRef, fetcher]);
          });
        }).whenComplete(() {
          logger.info(_stopwatch.finishProfiler());
        });
      });
    });
  }

  Future _cleanup() {
    return FileOps.listFiles(_options.root).then((entries) {
      return Future.forEach(entries, (chrome.Entry entry) {
        if (entry.isDirectory) {
          return (entry as chrome.DirectoryEntry).removeRecursively();
        } else {
          return entry.remove();
        }
      });
    });
  }

  Future _createCurrentTreeFromPack(chrome.DirectoryEntry dir, ObjectStore store,
      String headSha) {
    return store.retrieveObject(headSha, ObjectTypes.COMMIT_STR).then((commit) {
      return ObjectUtils.expandTree(dir, store, commit.treeSha);
    });
  }

  Future _checkDirectory(chrome.DirectoryEntry dir, ObjectStore store,
                         [bool uninitializedOk = false]) {
    return FileOps.listFiles(dir).then((List entries) {
      if (entries.length == 0 && uninitializedOk) {
        return null;
      } else if (entries.length == 0) {
        throw new GitException(GitErrorConstants.GIT_CLONE_DIR_NOT_INITIALIZED);
      } else if (entries.length != 1 || entries.first.isFile ||
          entries.first.name != '.git') {
        throw new GitException(GitErrorConstants.GIT_CLONE_DIR_NOT_EMPTY);
      } else {
        return FileOps.listFiles(store.objectDir).then((List entries) {
          if (entries.length > 1) {
            throw new GitException(GitErrorConstants.GIT_CLONE_DIR_IN_USE);
          } else if (entries.length == 1) {
            if (entries.first.name == "pack") {
              return store.objectDir.getDirectory('pack').then((packDir) {
                return FileOps.listFiles(packDir).then((entries) {
                  if (entries.length > 0) {
                    throw new GitException(GitErrorConstants.GIT_CLONE_DIR_IN_USE);
                  } else {
                    return null;
                  }
                });
              });
            }
          }
        });
      }
    });
  }

  Future<chrome.Entry> _createInitialConfig(String shallow,
      GitRef localHeadRef) {
    Config config = _options.store.config;
    config.url = _options.repoUrl;
    config.time = new DateTime.now();

    if (_options.depth != null && shallow != null) {
      config.shallow = shallow;
    }

    if (localHeadRef != null) {
      config.remoteHeads[localHeadRef.name]= localHeadRef.sha;
    }
    return _options.store.writeConfig();
  }

  Future _processClone(chrome.DirectoryEntry gitDir, GitRef localHeadRef,
      HttpFetcher fetcher) {
    return _createHeadAndRef(gitDir, localHeadRef).then((_) {
      return _callMethod(
          fetcher.fetchRef,
          [[localHeadRef.sha],
           null,
           null,
           _options.depth,
           null,
           nopFunction,
           nopFunction,
           _cancel], 'create HEAD').then((PackParseResult result) {

        return _callMethod(Pack.createPackFiles, [store, result],
            'createPackFiles').then((_) {

          return _callMethod(_createCurrentTreeFromPack,
                             [root, store, localHeadRef.sha]
                           , 'createCurrentTreeFromPack').then((_) {
            return _createInitialConfig(result.shallow, localHeadRef).then((_) {
            });
          });
        });
      });
    });
  }

  Future _createHeadAndRef(chrome.DirectoryEntry gitDir, GitRef localHeadRef) {
    return FileOps.createFileWithContent(gitDir, "HEAD",
        "ref: ${localHeadRef.name}\n", "Text").then((_) {
      return FileOps.createFileWithContent(gitDir, localHeadRef.name,
          localHeadRef.sha, "Text");
    });
  }

  /**
   * Calls the [func] with given [args] and [namedArgs] which returns a future.
   * On completion checks the cancel object and calls performCancel if the operation
   * is cancelled.
   */
  Future _callMethod(Function func, List args, [String message]) {
    return Function.apply(func, args).then((dynamic result) {
      _cancel.check();
      if (message != null) {
        logger.info(_stopwatch.finishCurrentTask(message));
      }
      return result;
    });
  }

  /**
   * Cancels the clone operation.
   */
  void cancel() {
    _cancel.cancel = true;
  }
}

class CloneCancel extends Cancel {

  CloneCancel() : super(false);

  void performCancel() {
    throw new GitException(GitErrorConstants.GIT_CLONE_CANCEL);
  }
}
