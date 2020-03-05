// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git_pack_index_test;

import 'package:test/test.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:dart_git/src/entry.dart';

import '../lib/src/object.dart';
import '../lib/src/pack.dart';
import '../lib/src/pack_index.dart';

final String PACK_FILE_PATH = 'test/data/pack_test.pack';
final String PACK_INDEX_FILE_PATH = 'test/data/pack_index_test.idx';

Future<Pack> initPack() {
  return getPackageDirectoryEntry().then((DirectoryEntry dir) {
    return dir.getFile(PACK_FILE_PATH);
  }).then((ChromeFileEntry entry) {
    return entry.readBytes();
  }).then((ArrayBuffer binaryData) {
    Uint8List data = new Uint8List.fromList(binaryData.getBytes());
    Pack pack = new Pack(data);
    return pack.parseAll().then((_) => pack);
  });
}

Future<PackIndex> initPackIndex() {
  return getPackageDirectoryEntry().then((DirectoryEntry dir) {
    return dir.getFile(PACK_INDEX_FILE_PATH);
  }).then((ChromeFileEntry entry) {
    return entry.readBytes();
  }).then((ArrayBuffer binaryData) {
    return new PackIndex(binaryData.getBytes());
  });
}

defineTests() {
  group('git.packIndex', () {
    test('packIndexParse', () {
      Pack pack;
      return initPack().then((Pack _pack) {
        print('got pack');
        pack = _pack;
        return initPackIndex();
      }).then((PackIndex packIdx) {
        print('got packIdx');
        pack.objects.forEach((PackedObject obj) {
          // asserts the object found by index has correct offset.
          expect(obj.offset, packIdx.getObjectOffset(obj.shaBytes));
        });
      });
    });
  });
}
