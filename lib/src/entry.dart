/// Temp stub for out-dated chrome.Entry
///
class Entry {
  //final FileSystem filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  Entry(this.fullPath, this.isDirectory, this.isFile, this.name);

  Future<Metadata> getMetadata() => Metadata(null, null);

  // void _copyTo(DirectoryEntry parent,
  //     [String name,
  //     _EntryCallback successCallback,
  //     _ErrorCallback errorCallback]) native;

  // Future<Entry> copyTo(DirectoryEntry parent, {String name}) {
  //   var completer = new Completer<Entry>();
  //   _copyTo(parent, name, (value) {
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void _getMetadata(MetadataCallback successCallback,
  //     [_ErrorCallback errorCallback]) native;

  // Future<Metadata> getMetadata() {
  //   var completer = new Completer<Metadata>();
  //   _getMetadata((value) {
  //     applyExtension('Metadata', value);
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void _getParent(
  //     [_EntryCallback successCallback, _ErrorCallback errorCallback]) native;

  // Future<Entry> getParent() {
  //   var completer = new Completer<Entry>();
  //   _getParent((value) {
  //     applyExtension('Entry', value);
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void _moveTo(DirectoryEntry parent,
  //     [String name,
  //     _EntryCallback successCallback,
  //     _ErrorCallback errorCallback]) native;

  // Future<Entry> moveTo(DirectoryEntry parent, {String name}) {
  //   var completer = new Completer<Entry>();
  //   _moveTo(parent, name, (value) {
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void _remove(VoidCallback successCallback, [_ErrorCallback errorCallback])
  //     native;

  // Future remove() {
  //   var completer = new Completer();
  //   _remove(() {
  //     completer.complete();
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  String toUrl() => "";
}

class ChromeFileEntry extends Entry {
  ChromeFileEntry(String fullPath, bool isDirectory, bool isFile, String name)
      : super(fullPath, isDirectory, isFile, name);
}

class FileEntry extends Entry {
  FileEntry(String fullPath, bool isDirectory, bool isFile, String name)
      : super(fullPath, isDirectory, isFile, name);
  // void _createWriter(_FileWriterCallback successCallback,
  //     [_ErrorCallback errorCallback]) native;

  // Future<FileWriter> createWriter() {
  //   var completer = new Completer<FileWriter>();
  //   _createWriter((value) {
  //     applyExtension('FileWriter', value);
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void _file(_FileCallback successCallback, [_ErrorCallback errorCallback])
  //     native;

  // Future<File> file() {
  //   var completer = new Completer<File>();
  //   _file((value) {
  //     applyExtension('File', value);
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }
}

class DirectoryEntry extends Entry {
  DirectoryEntry(String fullPath, bool isDirectory, bool isFile, String name)
      : super(fullPath, isDirectory, isFile, name);
  /**
   * Create a new directory with the specified `path`. If `exclusive` is true,
   * the returned Future will complete with an error if a directory already
   * exists with the specified `path`.
   */
  // Future<Entry> createDirectory(String path, {bool exclusive: false}) {
  //   return _getDirectory(path,
  //       options: {'create': true, 'exclusive': exclusive});
  // }

  // DirectoryReader createReader() {
  //   DirectoryReader reader = _createReader();
  //   applyExtension('DirectoryReader', reader);
  //   return reader;
  // }

  // /**
  //  * Retrieve an already existing directory entry. The returned future will
  //  * result in an error if a directory at `path` does not exist or if the item
  //  * at `path` is not a directory.
  //  */
  // Future<Entry> getDirectory(String path) {
  //   return _getDirectory(path);
  // }

  // /**
  //  * Create a new file with the specified `path`. If `exclusive` is true,
  //  * the returned Future will complete with an error if a file already
  //  * exists at the specified `path`.
  //  */
  // Future<Entry> createFile(String path, {bool exclusive: false}) {
  //   return _getFile(path, options: {'create': true, 'exclusive': exclusive});
  // }

  // /**
  //  * Retrieve an already existing file entry. The returned future will
  //  * result in an error if a file at `path` does not exist or if the item at
  //  * `path` is not a file.
  //  */
  // Future<Entry> getFile(String path) {
  //   return _getFile(path);
  // }

  // // To suppress missing implicit constructor warnings.
  // factory DirectoryEntry._() {
  //   throw new UnsupportedError("Not supported");
  // }

  // @JSName('createReader')
  // DirectoryReader _createReader() native;

  // void __getDirectory(String path,
  //     [Map options,
  //     _EntryCallback successCallback,
  //     _ErrorCallback errorCallback]) {
  //   if (errorCallback != null) {
  //     var options_1 = convertDartToNative_Dictionary(options);
  //     __getDirectory_1(path, options_1, successCallback, errorCallback);
  //     return;
  //   }
  //   if (successCallback != null) {
  //     var options_1 = convertDartToNative_Dictionary(options);
  //     __getDirectory_2(path, options_1, successCallback);
  //     return;
  //   }
  //   if (options != null) {
  //     var options_1 = convertDartToNative_Dictionary(options);
  //     __getDirectory_3(path, options_1);
  //     return;
  //   }
  //   __getDirectory_4(path);
  //   return;
  // }

  // @JSName('getDirectory')
  // void __getDirectory_1(path, options, _EntryCallback successCallback,
  //     _ErrorCallback errorCallback) native;
  // @JSName('getDirectory')
  // void __getDirectory_2(path, options, _EntryCallback successCallback) native;
  // @JSName('getDirectory')
  // void __getDirectory_3(path, options) native;
  // @JSName('getDirectory')
  // void __getDirectory_4(path) native;

  // @JSName('getDirectory')
  // Future<Entry> _getDirectory(String path, {Map options}) {
  //   var completer = new Completer<Entry>();
  //   __getDirectory(path, options, (value) {
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void __getFile(String path,
  //     [Map options,
  //     _EntryCallback successCallback,
  //     _ErrorCallback errorCallback]) {
  //   if (errorCallback != null) {
  //     var options_1 = convertDartToNative_Dictionary(options);
  //     __getFile_1(path, options_1, successCallback, errorCallback);
  //     return;
  //   }
  //   if (successCallback != null) {
  //     var options_1 = convertDartToNative_Dictionary(options);
  //     __getFile_2(path, options_1, successCallback);
  //     return;
  //   }
  //   if (options != null) {
  //     var options_1 = convertDartToNative_Dictionary(options);
  //     __getFile_3(path, options_1);
  //     return;
  //   }
  //   __getFile_4(path);
  //   return;
  // }

  // @JSName('getFile')
  // void __getFile_1(path, options, _EntryCallback successCallback,
  //     _ErrorCallback errorCallback) native;
  // @JSName('getFile')
  // void __getFile_2(path, options, _EntryCallback successCallback) native;
  // @JSName('getFile')
  // void __getFile_3(path, options) native;
  // @JSName('getFile')
  // void __getFile_4(path) native;

  // Future<Entry> _getFile(String path, {Map options}) {
  //   var completer = new Completer<Entry>();
  //   __getFile(path, options, (value) {
  //     applyExtension('FileEntry', value);
  //     completer.complete(value);
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }

  // void _removeRecursively(VoidCallback successCallback,
  //     [_ErrorCallback errorCallback]) native;

  // Future removeRecursively() {
  //   var completer = new Completer();
  //   _removeRecursively(() {
  //     completer.complete();
  //   }, (error) {
  //     completer.completeError(error);
  //   });
  //   return completer.future;
  // }
}

class Metadata {
  Metadata(this._get_modificationTime, this.size);

  DateTime get modificationTime => this._get_modificationTime;

  final dynamic _get_modificationTime;

  final int size;
}
