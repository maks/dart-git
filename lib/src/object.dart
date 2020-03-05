// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git.objects;

import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'exception.dart';
import 'object_utils.dart';
import 'utils.dart';

/**
 * Encapsulates a Gitobject
 *
 * TODO(grv): Add unittests.
 */
abstract class GitObject {

  /**
   * Constructs a GitObject of the given type. [content] can be of type [String]
   * or [Uint8List].
   */
  static GitObject make(String sha, String type, dynamic content,
                        [LooseObject rawObj]) {
    switch (type) {
      case ObjectTypes.BLOB_STR:
        return new BlobObject(sha, content);
      case ObjectTypes.TREE_STR:
      case "Tree":
        return new TreeObject(sha, content, rawObj);
      case ObjectTypes.COMMIT_STR:
        return new CommitObject(sha, content, rawObj);
      case ObjectTypes.TAG_STR:
        return new TagObject(sha, content);
      default:
        throw new ArgumentError("Unsupported git object type: ${type}");
    }
  }

  GitObject([this.sha, this.data]);

  // The type of git object.
  String type;
  dynamic data;
  String sha;

  String toString() => data.toString();
}

/**
 * Represents an entry in a git TreeObject.
 */
class TreeEntry {

  final String name;
  List<int> shaBytes;
  final bool isBlob;
  final String permission;

  String get sha => shaBytesToString(shaBytes);

  TreeEntry(this.name, this.shaBytes, this.isBlob, this.permission);

  static TreeEntry dummyEntry(bool isBlob) {
    return new TreeEntry(null, null, isBlob, null);
  }
}

/**
 * Error thrown for a parse failure.
 */
class ParseError extends Error {
  final message;

  /** The [message] describes the parse failure. */
  ParseError([this.message]);

  String toString() {
    if (message != null) {
      return "Parse Error(s): $message";
    }
    return "Parse Error(s)";
  }
}

/**
 * A tree type git object.
 */
class TreeObject extends GitObject {

  List<TreeEntry> entries;
  LooseObject rawObj;

  TreeObject( [String sha, Uint8List data, LooseObject rawObj])
      : super(sha, data) {
    this.type = ObjectTypes.TREE_STR;
    this.rawObj  = rawObj;
    _parse();
  }

  sortEntries() {
    // TODO(grv): Implement.
  }

  // Parses the byte stream and constructs the tree object.
  void _parse() {
    Uint8List buffer = data;
    List<TreeEntry> treeEntries = [];
    int idx = 0;
    while (idx < buffer.length) {
      int entryStart = idx;
      while (buffer[idx] != 0) {
        if (idx >= buffer.length) {
          //TODO(grv): Better exception handling.
          throw new ParseError("Unable to parse git tree object");
        }
        idx++;
      }
      bool isBlob = buffer[entryStart] == 49; // '1' character
      if (buffer[entryStart + 1] == 54) {  // '6' character
        // Contains a submodule commit object, not supported yet.
        throw new GitException(
            GitErrorConstants.GIT_SUBMODULES_NOT_YET_SUPPORTED);
      }
      String permission = UTF8.decode(buffer.sublist(
          entryStart, entryStart + (isBlob? 6 : 5)));
      String nameStr = UTF8.decode(buffer.sublist(
          entryStart + (isBlob ? 7: 6), idx++));
      nameStr = Uri.decodeComponent(HTML_ESCAPE.convert(nameStr));
      TreeEntry entry = new TreeEntry(nameStr, buffer.sublist(idx, idx + 20),
          isBlob, permission);
      treeEntries.add(entry);
      idx += 20;
    }
    this.entries = treeEntries;
    // Sort tree entries in ascending order.
    this.entries.sort((TreeEntry a, TreeEntry b) => a.name.compareTo(b.name));
  }
}

/**
 * Represents a git blob object.
 */
class BlobObject extends GitObject {

  BlobObject(String sha, dynamic data) : super(sha, data) {
    this.type = ObjectTypes.BLOB_STR;
  }
}

/**
 * Represents author's / commiter's information in a git commit object.
 */
class Author {

  String name;
  String email;
  int timestamp;
  DateTime date;
}

/**
 * Represents a git commit object.
 */
class CommitObject extends GitObject {

  List<String> parents;
  Author author;
  Author committer;
  String _encoding;
  String message;
  String treeSha;

  // raw commit object. This is needed in building pack files.
  LooseObject rawObj;

  CommitObject(String sha, dynamic data, [LooseObject rawObj]) {
    this.type = ObjectTypes.COMMIT_STR;
    this.sha = sha;
    this.rawObj = rawObj;

    if (data is Uint8List) {
      this.data = UTF8.decode(data);
    } else if (data is String) {
      this.data = data;
    } else {
      // TODO(grv): Clarify this exception.
      throw "Data is in incompatible format.";
    }
    _parseData();
  }

  // Parses the byte stream and constructs the commit object.
  void _parseData() {
    List<String> lines = data.split("\n");
    this.treeSha = lines[0].split(" ")[1];

    int i = 1;
    parents = [];
    while (lines[i].substring(0,6) == "parent") {
      parents.add(lines[i].split(" ")[1]);
      i++;
    }

    String authorLine = lines[i].replaceFirst("author ", "");
    author = _parseAuthor(authorLine);

    String committerLine = lines[i + 1].replaceFirst("committer ", "");
    committer = _parseAuthor(committerLine);

    if (lines[i + 2].split(" ")[0] == "encoding") {
      _encoding = lines[i + 2].split(" ")[1];
    }

    lines.removeRange(0, i +2);

    message = lines.join("\n");
  }

  Author _parseAuthor(String input) {

    // Regex " AuthorName <Email>  timestamp timeOffset"
    final RegExp pattern = new RegExp(r'(.*) <(.*)> (\d+) (\+|\-)\d\d\d\d');
    List<Match> match = pattern.allMatches(input).toList();

    Author author = new Author();
    author.name = match[0].group(1);
    author.email = match[0].group(2);
    author.timestamp = (int.parse(match[0].group(3))) * 1000;
    author.date = new DateTime.fromMillisecondsSinceEpoch(
        author.timestamp, isUtc:true);
    return author;
  }

  String toString() {
    String str = "commit " + sha + "\n";
    str += "Author: " + author.name + " <" + author.email + ">\n";
    str += "Date:  " + author.date.toString() + "\n\n";
    str += message;
    return str;
  }

  /**
   * Returns the commit object as a map for easy advanced formatting instead
   * of toString().
   */
  Map<String, String> toMap() {
    return {
            "commit": sha,
            "author_name": author.name,
            "author_email": author.email,
            "date": author.date.toString(),
            "message": message
           };
  }
}

/**
 * Represents a git tag object.
 */
class TagObject extends GitObject {
  TagObject(String sha, String data) : super(sha, data) {
    this.type = ObjectTypes.TAG_STR;
  }
}

/**
 * A loose git object.
 */
class LooseObject extends GitObject {
  int size;

  LooseObject(dynamic buf) {
    _parse(buf);
  }

  // Parses and constructs a loose git object.
  void _parse(dynamic buf) {
    String header;
    int i;
    if (buf is List<int>) {
      List<String> headChars = [];
      for (i = 0; i < buf.length; ++i) {
        if (buf[i] != 0)
          headChars.add(UTF8.decode([buf[i]]));
        else
          break;
      }
      header = headChars.join();

      this.data = buf.sublist(i + 1, buf.length);
    } else {
      i = buf.indexOf(new String.fromCharCode(0));
      header = buf.substring(0, i);
      // move past null terminator but keep zlib header
      this.data = buf.substring(i + 1, buf.length);
    }
    List<String> parts = header.split(' ');
    this.type = parts[0];
    this.size = int.parse(parts[1]);
  }
}

/**
 * Encapsulates a git pack object.
 */
class PackedObject extends GitObject {
  List<int> shaBytes;
  String baseSha;
  int crc;
  int offset;
  int desiredOffset;
}
