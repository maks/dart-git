// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'exception.dart';
import 'objectstore.dart';
import 'upload_pack_parser.dart';
import 'utils.dart';

final int COMMIT_LIMIT = 32;

class HttpFetcher {
  ObjectStore store;
  String name;
  String repoUrl;
  String username;
  String password;
  String url;
  Map<String, String> urlOptions = {};

  Map<String, GitRef> refs = {};

  HttpFetcher(this.store, this.name, this.repoUrl,
      [this.username, this.password]) {
    url = _getUrl(repoUrl);
    urlOptions = _queryParams(repoUrl);
  }

  /*
   * Get a new instance of HttpRequest. Exposed for tests to inject fake xhr.
   */
  http.Client get newHttpClient => http.Client();

  GitRef getRef(String name) => refs[this.name + "/" + name];

  List<GitRef> getRefs() => refs.values;

  Future<List<GitRef>> fetchReceiveRefs() => _fetchRefs('git-receive-pack');

  Future<List<GitRef>> fetchUploadRefs() => _fetchRefs('git-upload-pack');

  Future<void> pushRefs(
      List<GitRef> refPaths, List<int> packData, Function progress) async {
    String url = _makeUri('/git-receive-pack', {});
    final body = _pushRequest(refPaths, packData);

    final request = http.Request("POST", Uri.parse(url));
    request.headers.addAll(_authHeader(username, password));
    request.headers['Content-Type'] = 'application/x-git-receive-pack-request';
    // TODO: really should stream the body so don't have to hold in all in mem
    // and then we could also track progress by calling progress() callback
    request.body = String.fromCharCodes(body);

    final streamedResponse = await newHttpClient.send(request);
    if (streamedResponse.statusCode == 200) {
      final response = await http.Response.fromStream(streamedResponse);
      if (response.body.startsWith('000eunpack ok')) {
        return;
      } else {
        throw HttpGitException.fromResponse(response);
      }
    } else {
      final response = await http.Response.fromStream(streamedResponse);
      throw HttpGitException.fromResponse(response);
    }
  }

  Future<PackParseResult> fetchRef(
      List<String> wantRefs,
      List<String> haveRefs,
      String shallow,
      int depth,
      List<String> moreHaves,
      noCommon,
      Function progress,
      [Cancel cancel]) async {
    Function packProgress, receiveProgress;
    String url = _makeUri('/git-upload-pack', {});
    String body = _refWantRequst(wantRefs, haveRefs, shallow, depth, moreHaves);

    final request = http.Request("POST", Uri.parse(url));
    request.headers.addAll(_authHeader(username, password));
    request.headers['Content-Type'] = 'application/x-git-upload-pack-request';

    final streamedResponse = await newHttpClient.send(request);
    if (streamedResponse.statusCode == 200) {
      streamedResponse.stream.forEach((element) {
        final buffer = Uint8List.fromList(element).buffer;
        Uint8List data = Uint8List.view(buffer, 4, 3);

        if (haveRefs != null && utf8.decode(data.toList()) == "NAK") {
          if (moreHaves.isNotEmpty) {
            //TODO handle case of more haves.
            //store.getCommitGraph(headShas, COMMIT_LIMIT).then((obj) {
            //});
          } else if (noCommon) {
            noCommon();
          }
          throw Exception('error in git pull');
        } else {
          if (packProgress != null) {
            packProgress({'pct': 0, 'msg': "Parsing pack data"});
          }

          UploadPackParser parser = getUploadPackParser(cancel);
          return parser.parse(buffer, store, packProgress).then(
              (PackParseResult obj) {
            return obj;
          }, onError: (e) {
            throw e;
          });
        }
      });
    } else {
      // TODO
    }
  }

  /*
   * Get a new instance of uploadPackParser. Exposed for tests to inject fake parser.
   */
  UploadPackParser getUploadPackParser([Cancel cancel]) =>
      UploadPackParser(cancel);

  Map<String, String> _authHeader(String username, String password) => {
        'authorization':
            'Basic ' + base64Encode(utf8.encode('$username:$password'))
      };

  /**
   * Parses the uri and returns the query params map.
   */
  Map<String, String> _queryParams(String uri) {
    List<String> parts = uri.split('?');
    if (parts.length < 2) return {};

    String queryString = parts[1];

    List<String> paramStrings = queryString.split("&");
    Map params = {};
    paramStrings.forEach((String paramStrimg) {
      List<String> pair = paramStrimg.split("=");
      params[pair[0] = Uri.decodeQueryComponent(pair[1])];
    });
    return params;
  }

  /**
   * Constructs and calls a http get request
   */
  Future<String> _doGet(String url) async {
    final response = await newHttpClient.get(url);
    if (response.statusCode != 200) {
      throw HttpGitException.fromResponse(response);
    }
    return response.body;
  }

  /**
   * Some git repositories do not end with '.git' suffix. Validate those urls
   * by sending a request to the server.
   */
  Future<bool> isValidRepoUrl() {
    String uri = _makeUri('/info/refs', {"service": 'git-upload-pack'});
    try {
      return _doGet(uri).then((_) => true).catchError((e) {
        if (e.status == 401) {
          throw GitException(GitErrorConstants.GIT_AUTH_REQUIRED);
        }
        return Future.value(false);
      });
    } catch (e) {
      return Future.value(false);
    }
  }

  String _makeUri(String path, Map<String, String> extraOptions) {
    String uri = url + path;
    Map<String, String> options = urlOptions;
    options.addAll(extraOptions);
    if (options.isNotEmpty) {
      Iterable<String> keys = options.keys;
      Iterable<String> optionStrings = keys.map((String key) {
        return key + "=" + Uri.encodeQueryComponent(options[key]);
      });
      return uri + "?" + optionStrings.join("&");
    }
    return uri;
  }

  String _getUrl(String url) =>
      repoUrl.replaceAll("\?.*", "").replaceAll("\/\$", "");

  Map _parseDiscovery(String data) {
    List<String> lines = data.split("\n");
    List<GitRef> refs = [];
    Map result = {"refs": refs};

    for (int i = 1; i < lines.length - 1; ++i) {
      String currentLine = lines[i];
      if (i == 1) {
        List<String> bits = currentLine.split("\u0000");
        result["capabilities"] = bits[1];
        List<String> bits2 = bits[0].split(" ");
        result["refs"].add(GitRef(bits2[0].substring(8), bits2[1]));
      } else {
        List<String> bits2 = currentLine.split(" ");
        result["refs"].add(GitRef(bits2[0].substring(4), bits2[1]));
      }
    }
    return result;
  }

  String _padWithZeros(int num) {
    String hex = num.toRadixString(16);
    int pad = 4 - hex.length;
    for (int i = 0; i < pad; ++i) {
      hex = '0' + hex;
    }
    return hex;
  }

  Uint8List _pushRequest(List<GitRef> refPaths, List<int> packData) {
    List<Uint8List> blobParts = [];
    String header = refPaths[0].getPktLine() + '\u0000report-status\n';
    header = _padWithZeros(header.length + 4) + header;
    blobParts.add(_toUint8(header));

    for (int i = 1; i < refPaths.length; ++i) {
      if (refPaths[i].head == null) continue;
      String val = refPaths[i].getPktLine() + '\n';
      blobParts.add(_toUint8(_padWithZeros(val.length + 4)));
    }

    blobParts.add(_toUint8('0000'));
    blobParts.add(Uint8List.fromList(packData));
    return Uint8List.fromList(blobParts.expand((x) => x).toList());
  }

  Uint8List _toUint8(String s) => Uint8List.fromList(s.codeUnits);

  /**
   * Constructs a want request from the server.
   */
  String _refWantRequst(List<String> wantRefs, List<String> haveRefs,
      String shallow, int depth, List<String> moreHaves) {
    StringBuffer request = StringBuffer("0067want ${wantRefs[0]} ");
    request.write("multi_ack_detailed side-band-64k thin-pack ofs-delta\n");
    for (int i = 1; i < wantRefs.length; ++i) {
      request.write("0032want ${wantRefs[i]}\n");
    }

    if (haveRefs != null) {
      if (shallow != null) {
        request.write("0034shallow " + shallow);
      }
      request.write("0000");
      haveRefs.forEach((String sha) {
        request.write("0032have ${sha}\n");
      });
      if (moreHaves.isNotEmpty) {
        request.write("0000");
      } else {
        request.write("0009done\n");
      }
    } else {
      if (depth != null) {
        String depthStr = "deepen ${depth}";
        request.write((_padWithZeros(depthStr.length + 4) + depthStr));
      }
      request.write("0000");
      request.write("0009done\n");
    }
    return request.toString();
  }

  _addRef(GitRef ref) {
    String type;
    String name;
    if (ref.name.length > 5 && ref.name.substring(0, 5) == "refs/") {
      type = ref.name.split("/")[1];
      name = this.name + "/" + ref.name.split("/")[2];
    } else {
      type = "HEAD";
      name = this.name + "/HEAD";
    }

    refs[name] = new GitRef(ref.sha, name, type, this);
  }

  Future<List<GitRef>> _fetchRefs(String service) {
    String uri = _makeUri('/info/refs', {"service": service});
    return _doGet(uri).then((String data) {
      Map discInfo = _parseDiscovery(data);
      discInfo["refs"].forEach((GitRef ref) => _addRef(ref));
      return new Future.value(discInfo["refs"]);
    });
  }
}

class HttpGitException extends GitException {
  int status;
  String statusText;

  HttpGitException(this.status, this.statusText,
      [String errorCode, String message, bool canIgnore])
      : super(errorCode, message, canIgnore);
  static fromResponse(http.Response response) {
    String errorCode;

    switch (response.statusCode) {
      case 401:
        errorCode = GitErrorConstants.GIT_AUTH_REQUIRED;
        break;
      case 403:
        errorCode = GitErrorConstants.GIT_HTTP_FORBIDDEN_ERROR;
        break;
      case 404:
        errorCode = GitErrorConstants.GIT_HTTP_NOT_FOUND_ERROR;
        break;
      case 0:
        errorCode = GitErrorConstants.GIT_HTTP_CONN_RESET;
        break;
      default:
        errorCode = GitErrorConstants.GIT_HTTP_ERROR;
        break;
    }
    return new HttpGitException(
        response.statusCode, response.reasonPhrase, errorCode, "", false);
  }

  /**
   * Returns `true` if the status is 401 Unauthorized.
   */
  bool get needsAuth => status == 401;

  String toString() => '${status} ${statusText}';
}
