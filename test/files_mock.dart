// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * A library to mock out a DOM file system.
 */
library spark.files_mock;

import 'dart:async';

import 'package:dart_git/src/file_io.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as path;

/**
 * A mutable, memory resident file system.
 */
class MockFileSystem implements FileSystem {
  final String name;
  _MockDirectory _root;

  MockFileSystem([this.name]) {
    _root = new _RootDirectory(this, 'root');
  }

  Directory get root => _root;

  // Utility methods.

  File createFile(String filePath, {String contents}) {
    if (filePath.startsWith('/')) {
      filePath = filePath.substring(1);
    }

    String dirPath = path.dirname(filePath);
    String fileName = path.basename(filePath);

    if (dirPath == '.') {
      return _root._createFile(filePath, contents: contents);
    } else {
      _MockDirectory dir = createDirectory(dirPath);
      return dir._createFile(fileName, contents: contents);
    }
  }

  void removeFile(String filePath) {
    if (filePath.startsWith('/')) {
      filePath = filePath.substring(1);
    }

    String dirPath = path.dirname(filePath);
    String fileName = path.basename(filePath);

    if (dirPath == '.') {
      _root._removeFile(filePath);
    } else {
      _MockDirectory dir = getEntry(dirPath);
      if (dir is! Directory) {
        return;
      }
      dir._removeFile(fileName);
    }
  }

  Directory createDirectory(String filePath) {
    if (filePath.startsWith('/')) {
      filePath = filePath.substring(1);
    }

    String dirPath = path.dirname(filePath);
    String fileName = path.basename(filePath);

    if (dirPath == '.') {
      return _root._createDirectory(filePath);
    } else {
      _MockDirectory dir = createDirectory(dirPath);
      return dir._createDirectory(fileName);
    }
  }

  Entry getEntry(String path) {
    _MockEntry entry = _root;

    for (String name in path.split('/')) {
      entry = entry._getChild(name);

      if (entry == null) return null;
    }

    return entry;
  }

  void touchFile(String path) {
    _MockEntry entry = getEntry(path);
    assert(entry != null);
    entry._modificationTime = new DateTime.fromMillisecondsSinceEpoch(
        entry._modificationTime.millisecondsSinceEpoch + 1);
  }
}

/**
 * Create a simple sample directory.
 */
Directory createSampleDirectory1(String name) {
  MockFileSystem fs = new MockFileSystem();
  Directory directory = fs.createDirectory(name);
  fs.createFile('${name}/bar.txt', contents: '123');
  fs.createFile('${name}/web/index.html',
      contents:
          '<html><body><script type="application/dart" src="sample.dart"></script></body></html>');
  fs.createFile('${name}/web/sample.dart',
      contents: 'void main() {\n  print("hello");\n}\n');
  fs.createFile('${name}/web/sample.css', contents: 'body { }');
  return directory;
}

/**
 * Create a sample directory, with one Dart file referencing another.
 */
Directory createSampleDirectory2(String name) {
  MockFileSystem fs = new MockFileSystem();
  Directory directory = fs.createDirectory(name);
  fs.createFile('${name}/web/index.html',
      contents:
          '<html><body><script type="application/dart" src="sample.dart"></script></body></html>');
  fs.createFile('${name}/web/sample.dart',
      contents:
          'import "foo.dart";\n\nvoid main() {\n  print("hello \${foo()}");\n}\n');
  fs.createFile('${name}/web/foo.dart', contents: 'String foo() => "there";\n');
  fs.createFile('${name}/web/sample.css', contents: 'body { }');
  return directory;
}

/**
 * Create a sample directory with a package reference.
 */
Directory createSampleDirectory3(String name) {
  MockFileSystem fs = new MockFileSystem();
  Directory directory = fs.createDirectory(name);
  fs.createFile('${name}/pubspec.yaml', contents: 'name: ${name}\n');
  fs.createFile('${name}/web/index.html',
      contents:
          '<html><body><script type="application/dart" src="sample.dart"></script></body></html>');
  fs.createFile('${name}/web/sample.dart',
      contents:
          'import "package:foo/foo.dart";\n\nvoid main() {\n  print("hello \${foo()}");\n}\n');
  fs.createFile('${name}/packages/foo/foo.dart',
      contents: 'String foo() => "there";\n');
  fs.createFile('${name}/web/sample.css', contents: 'body { }');
  return directory;
}

/**
 * Create a directory with a dart file with given name and contents.
 */
Directory createDirectoryWithDartFile(String name, String contents) {
  MockFileSystem fs = new MockFileSystem();
  Directory directory = fs.createDirectory(name);
  fs.createFile('${name}/web/sample.dart', contents: contents);
  return directory;
}

Future<workspace.Project> linkSampleProject(Directory dir,
    [workspace.Workspace ws]) {
  if (ws == null) ws = new workspace.Workspace();
  return ws.link(createWsRoot(dir));
}

MockWorkspaceRoot createWsRoot(FileSystemEntity entry) =>
    new MockWorkspaceRoot(entry);

class MockWorkspaceRoot extends workspace.WorkspaceRoot {
  MockWorkspaceRoot(FileSystemEntity entry) {
    this.entry = entry;
  }

  workspace.Resource createResource(workspace.Workspace ws) {
    if (entry is File) {
      return new workspace.LooseFile(ws, this);
    } else {
      return new workspace.Project(ws, this);
    }
  }

  String get id => entry.name;

  Map persistState() => {};

  Future restore() => new Future.value();

  String retainEntry(FileSystemEntity entry) => entry.name;
  Future<FileSystemEntity> restoreEntry(String id) => new Future.value(entry);
}

abstract class _MockEntry implements FileSystemEntity {
  String name;

  _MockDirectoryEntry _parent;
  DateTime _modificationTime = new DateTime.now();

  _MockEntry(this._parent, this.name);

  FileSystem get filesystem => _parent.filesystem;

  String get fullPath => _isRoot ? '/${name}' : '${_parent.fullPath}/${name}';

  // TODO:
  Future<FileSystemEntity> copyTo(Directory parent, {String name}) {
    throw new UnimplementedError('Entry.copyTo()');
  }

  _MockEntry clone() {
    throw new UnimplementedError('Entry.clone()');
  }

  Future<Metadata> getMetadata() => new Future.value(new _MockMetadata(this));

  Future<FileSystemEntity> getParent() =>
      new Future.value(_isRoot ? this : _parent);

  // TODO:
  Future<FileSystemEntity> moveTo(Directory parent, {String name}) {
    remove();
    if (parent == null) {
      parent = (filesystem as MockFileSystem)._root;
    }
    assert(this is _MockFile || this is _MockDirectory);
    _MockEntry result = null;
    String resultEntryName = name != null ? name : this.name;
    result = this.clone();
    result.name = resultEntryName;
    result._parent = parent;
    (parent as _MockDirectory)._children.add(result);
    (parent as _MockDirectory)._touch();
    return new Future.value(result);
  }

  String toUrl() => 'mock:/${fullPath}';

  bool get _isRoot => filesystem.root == this;

  Entry _getChild(String name);

  _touch() => _modificationTime = new DateTime.now();

  String get _path => _parent == null ? '/${name}' : '${_parent._path}/${name}';

  int get _size;
}

class _MockFile extends _MockEntry implements File {
  String _contents;
  List<int> _byteContents;

  _MockFileEntry(Directory parent, String name) : super(parent, name);

  bool get isDirectory => false;
  bool get isFile => true;

  _MockEntry clone() => new _MockFileEntry(null, name);

  Future remove() => _parent._remove(this);

  // TODO:
  Future<FileWriter> createWriter() {
    throw new UnimplementedError('FileEntry.createWriter()');
  }

  Future<File> file() => new Future.value(new _MockFile(this));

  // ChromeFileEntry specific methods

  Future<ArrayBuffer> readBytes() {
    if (_byteContents != null) {
      return new Future.value(new ArrayBuffer.fromBytes(_byteContents));
    } else if (_contents != null) {
      return new Future.value(new ArrayBuffer.fromString(_contents));
    } else {
      return new Future.value(new ArrayBuffer());
    }
  }

  Future<String> readText() {
    if (_contents != null) {
      return new Future.value(_contents);
    } else if (_byteContents != null) {
      return new Future.value(new String.fromCharCodes(_byteContents));
    } else {
      return new Future.value('');
    }
  }

  Future writeBytes(ArrayBuffer data) {
    _byteContents = data.getBytes();
    _contents = null;
    _touch();
    return new Future.value();
  }

  Future writeText(String text) {
    _contents = text;
    _byteContents = null;
    _touch();
    return new Future.value();
  }

  FileSystemEntity _getChild(String name) => null;

  int get _size {
    if (_contents != null) return _contents.length;
    if (_byteContents != null) return _byteContents.length;
    return 0;
  }

  dynamic get jsProxy => null;
  dynamic toJs() => null;

  // Added to satisfy the analyzer.
  JsObject blink_jsObject;
}

class _MockDirectory extends _MockEntry implements Directory {
  List<FileSystemEntity> _children = [];

  _MockDirectory(Directory parent, String name) : super(parent, name);

  _MockDirectory clone() {
    _MockDirectory result = new _MockDirectory(null, name);
    for (_MockEntry child in _children) {
      result._children.add(child);
      child._parent = result;
    }
    return result;
  }

  bool get isDirectory => true;
  bool get isFile => false;

  Future remove() {
    if (_isRoot && _children.isEmpty) {
      return new Future.error('illegal state');
    } else {
      return _parent._remove(this);
    }
  }

  Future _remove(FileSystemEntity e) {
    _children.remove(e);
    _touch();
    return new Future.value();
  }

  Future<FileSystemEntity> createDirectory(String path,
      {bool exclusive: false}) {
    if (_getChild(path) != null && exclusive) {
      return new Future.error('directory already exists');
    } else {
      return new Future.value(_createDirectory(path));
    }
  }

  Future<FileSystemEntity> createFile(String path, {bool exclusive: false}) {
    if (_getChild(path) != null && exclusive) {
      return new Future.error('file already exists');
    } else {
      return new Future.value(_createFile(path));
    }
  }

  DirectoryReader createReader() => new _MockDirectoryReader(this);

  Future<Entry> getDirectory(String path) {
    FileSystemEntity entry = _getChild(path);

    if (entry is! Directory) {
      return new Future.error("directory doesn't exist");
    } else {
      return new Future.value(_createDirectory(path));
    }
  }

  Future<FileSystemEntity> getFile(String path) {
    List<String> pathParts = path.split('/');
    FileSystemEntity entry = _getChild(pathParts[0]);
    int i = 1;

    while (entry != null && entry.isDirectory && i < pathParts.length) {
      entry = (entry as _MockDirectory)._getChild(pathParts[i++]);
    }

    if (entry is! File) {
      return new Future.error("file doesn't exist");
    } else {
      return new Future.value(entry);
    }
  }

  Future removeRecursively() => _parent._remove(this);

  File _createFile(String name, {String contents}) {
    _MockFile entry = _getChild(name);
    if (entry != null) return entry;

    _touch();

    entry = new _MockFile(this, name);
    _children.add(entry);
    if (contents != null) {
      entry._contents = contents;
    }
    return entry;
  }

  Directory _createDirectory(String name) {
    _MockDirectory entry = _getChild(name);
    if (entry != null) return entry;

    _touch();

    entry = new _MockDirectory(this, name);
    _children.add(entry);
    return entry;
  }

  Future<FileSystemEntity> _removeFile(String name) {
    _MockFile entry = _getChild(name);
    if (entry == null) {
      return new Future.value();
    }

    return _remove(entry);
  }

  FileSystemEntity _getChild(String name) {
    for (FileSystemEntity entry in _children) {
      if (entry.name == name) return entry;
    }

    return null;
  }

  int get _size => 0;
}

class _RootDirectory extends _MockDirectory {
  final FileSystem filesystem;

  _RootDirectory(this.filesystem, String name) : super(null, name);
}

class _MockDirectoryReader implements DirectoryReader {
  _MockDirectory dir;

  _MockDirectoryReader(this.dir);

  Future<List<FileSystemEntity>> readEntries() =>
      new Future.value(dir._children);
}

class _MockMetadata implements Metadata {
  final _MockEntry entry;

  _MockMetadata(this.entry);

  DateTime get modificationTime => entry._modificationTime;

  int get size => entry._size;
}
