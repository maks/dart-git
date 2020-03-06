// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:dart_git/src/file_io.dart';
import 'package:test/test.dart';

import 'dart:typed_data';

import '../lib/src/pack.dart';

final String PACK_FILE_PATH = 'test/data/pack_test.pack';
final String PACK_INDEX_FILE_PATH = 'test/data/pack-_index_test.idx';

defineTests() {
  group('git.pack', () {
    test('parsePack', () {
      return getPackageDirectoryEntry().then((Directory dir) {
        print('got dir');
        return dir.getFile(PACK_FILE_PATH).then((File entry) {
          print('got ${PACK_FILE_PATH}');
          return entry.readBytes().then((ArrayBuffer binaryData) {
            print('got bytes');
            Pack pack = new Pack(new Uint8List.fromList(binaryData.getBytes()));
            return pack.parseAll().then((_) {
              print('got pack.parseAll()');
              // TODO: add more expects for the pack state?
              expect(pack.objects.length, 15);
            });
          });
        });
      });
    });
  });
}
