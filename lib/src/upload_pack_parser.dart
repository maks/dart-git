// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git.upload_pack_parser;

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:html';
import 'dart:typed_data';

import 'file_operations.dart';
import 'object.dart';
import 'objectstore.dart';
import 'pack.dart';
import 'utils.dart';

class PktLine {
  final int offset;
  final int length;

  PktLine(this.offset, this.length);
}

class PackParseResult {
  final List<PackedObject> objects;
  final String shallow;
  final List<String> common;
  final List<int> data;

  PackParseResult(this.objects,  this.data, this.shallow, this.common);
}

class UploadPackParser {

  int _offset = 0;
  List<PackedObject> objects = null;
  List<int> data;
  Cancel _cancel;

  UploadPackParser([this._cancel]);

  /**
   * Parses a git http smart protcol request result.
   */
  Future parse(ByteBuffer buffer, ObjectStore store, progress) {
    data = new Uint8List.view(buffer);

    DateTime startTime = new DateTime.now();
    PktLine pktLine = _nextPktLine();
    String remoteLine = "";
    bool gotAckorNak = false;
    List<String> common = [];

    String pktLineStr = _getPktLine(pktLine);
    String shallow;
    while (pktLineStr.length > 6 && (pktLineStr.substring(0,7) == "shallow")) {
      pktLine = _nextPktLine(true);
      shallow = pktLineStr.substring(8);
      pktLineStr = _getPktLine(pktLine);
    }

    while (pktLineStr == "NAK\n" || (pktLineStr.length > 3
        && pktLineStr.substring(0,3) == "ACK")) {
      RegExp ackRegex = new RegExp(r"ACK ([0-9a-fA-F]{40}) common");
      Iterable<Match> matches = ackRegex.allMatches(pktLineStr);
      if (matches.isNotEmpty) {
        common.add(matches.first.group(1));
      }
      pktLine = _nextPktLine();
      pktLineStr = _getPktLine(pktLine);
      gotAckorNak = true;
    }

    if (!gotAckorNak) {
      // TODO throw custom exception.
      throw "got neither ACk nor NAK in upload pack response.";
    }

    List<Uint8List> packDataLines = [];
    while (pktLine != null) {
      int pktLineType = data[pktLine.offset];
      // sideband format. "2" indicates progress messages, "1" pack data
      switch (pktLineType) {
        case 1:
          packDataLines.add(data.sublist(pktLine.offset + 1,
              pktLine.offset + pktLine.length));
          break;
        case 2:
          break;
        default:
          throw "fatal error in packet line.";
      }
      pktLine = _nextPktLine();
    }

    // create a blob for the packData lines.
    Blob packDataBlob = new Blob(packDataLines);

    return FileOps.readBlob(packDataBlob, "ArrayBuffer").then((data) {
      Pack pack = new Pack(data, store, _cancel);
      return pack.parseAll(progress).then((_) {
        objects = pack.objects;
        return new PackParseResult(pack.objects, pack.data, shallow, common);
      });
    });
  }

  // a pkt-line is defined in http://git-scm.com/gitserver.txt
  PktLine _nextPktLine([bool isShallow=false]) {
    PktLine pktLine = null;
    int length;
    length = int.parse(UTF8.decode(_peek(4)), radix:16);
    _advance(4);
    if (length == 0) {
      if (isShallow) {
        return _nextPktLine();
      }
    } else {
      pktLine = new PktLine(_offset, length - 4);
      _advance(length - 4);
    }
    return pktLine;
  }

  String _getPktLine(PktLine pktLine) {
    String pktString =UTF8.decode(data.sublist(pktLine.offset,
        pktLine.offset + pktLine.length));
    return pktString;
  }

  List<int> _peek(int length) => data.sublist(_offset, _offset + length);

  int _advance(int length) => _offset += length;
}
