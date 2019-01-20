// import pify from 'pify'
// import { E, GitError } from '../models/GitError.js'
// import { compareStrings } from '../utils/compareStrings.js'
// import { dirname } from '../utils/dirname.js'
// import { sleep } from '../utils/sleep.js'

import 'package:dart_git/utils/logging.dart';

final delayedReleases = new Map();
/**
 * This is just a collection of helper functions really. At least that's how it started.
 */
class FileSystem {

  final _logger = Logger();

  FileSystem(fs) {
    // This is not actually the most logical place to put this, but in practice
    // putting the check here should work great.
    if (fs == null) {
      throw new GitError(E.PluginUndefined, { plugin: 'fs' });
    }
    if (typeof fs._readFile !== 'undefined') return fs;
    this._readFile = pify(fs.readFile.bind(fs));
    this._writeFile = pify(fs.writeFile.bind(fs));
    this._mkdir = pify(fs.mkdir.bind(fs));
    this._rmdir = pify(fs.rmdir.bind(fs));
    this._unlink = pify(fs.unlink.bind(fs));
    this._stat = pify(fs.stat.bind(fs));
    this._lstat = pify(fs.lstat.bind(fs));
    this._readdir = pify(fs.readdir.bind(fs));
    this._readlink = pify(fs.readlink.bind(fs));
    this._symlink = pify(fs.symlink.bind(fs));
  }
  /**
   * Return true if a file exists, false if it doesn't exist.
   * Rethrows errors that aren't related to file existance.
   */
  exists({filepath, options = {}}) async {
    try {
      await this._stat(filepath);
      return true;
    } catch (err) {
      if (err.code == 'ENOENT' || err.code == 'ENOTDIR') {
        return false;
      } else {
        _logger.error('Unhandled error in "FileSystem.exists()" function', err);
        throw err;
      }
    }
  }
  /**
   * Return the contents of a file if it exists, otherwise returns null.
   */
  read (filepath, options = {}) async {
    try {
      var buffer = await this._readFile(filepath, options);
      // Convert plain ArrayBuffers to Buffers
      if (typeof buffer !== 'string') {
        buffer = Buffer.from(buffer);
      }
      return buffer;
    } catch (err) {
      return null;
    }
  }
  /**
   * Write a file (creating missing directories if need be) without throwing errors.
   */
  write ({filepath, contents, options = {}}) async {
    try {
      await this._writeFile(filepath, contents, options);
      return;
    } catch (err) {
      // Hmm. Let's try mkdirp and try again.
      await this.mkdir(dirname(filepath));
      await this._writeFile(filepath, contents, options);
    }
  }
  /**
   * Make a directory (or series of nested directories) without throwing an error if it already exists.
   */
  mkdir ({filepath, _selfCall = false}) async {
    try {
      await this._mkdir(filepath);
      return;
    } catch (err) {
      // If err is null then operation succeeded!
      if (err === null) return;
      // If the directory already exists, that's OK!
      if (err.code === 'EEXIST') return;
      // Avoid infinite loops of failure
      if (_selfCall) throw err;
      // If we got a "no such file or directory error" backup and try again.
      if (err.code === 'ENOENT') {
        var parent = dirname(filepath);
        // Check to see if we've gone too far
        if (parent === '.' || parent === '/' || parent === filepath) throw err;
        // Infinite recursion, what could go wrong?
        await this.mkdir(parent);
        await this.mkdir(filepath, true);
      }
    }
  }
  /**
   * Delete a file without throwing an error if it is already deleted.
   */
  rm (filepath) async {
    try {
      await this._unlink(filepath);
    } catch (err) {
      if (err.code !== 'ENOENT') throw err;
    }
  }
  /**
   * Read a directory without throwing an error is the directory doesn't exist
   */
  readdir (filepath) async {
    try {
      let names = await this._readdir(filepath);
      // Ordering is not guaranteed, and system specific (Windows vs Unix)
      // so we must sort them ourselves.
      names.sort(compareStrings);
      return names;
    } catch (err) {
      if (err.code == 'ENOTDIR') return null;
      return [];
    }
  }
  /**
   * Return a flast list of all the files nested inside a directory
   *
   * Based on an elegant concurrent recursive solution from SO
   * https://stackoverflow.com/a/45130990/2168416
   */
  readdirDeep (dir) async {
    final subdirs = await this._readdir(dir);
    final files = await Promise.all(
      subdirs.map(async subdir => {
        final res = dir + '/' + subdir;
        return (await this._stat(res)).isDirectory()
          ? this.readdirDeep(res)
          : res;
      })
    )
    return files.reduce((a, f) => a.concat(f), [])
  }
  /**
   * Return the Stats of a file/symlink if it exists, otherwise returns null.
   * Rethrows errors that aren't related to file existance.
   */
  lstat (filename) async {
    try {
      var stats = await this._lstat(filename);
      return stats;
    } catch (err) {
      if (err.code == 'ENOENT') {
        return null;
      }
      throw err;
    }
  }
  /**
   * Reads the contents of a symlink if it exists, otherwise returns null.
   * Rethrows errors that aren't related to file existance.
   */
  readlink ({filename, opts = { encoding: 'buffer' }}) async {
    // Note: FileSystem.readlink returns a buffer by default
    // so we can dump it into GitObject.write just like any other file.
    try {
      return this._readlink(filename, opts);
    } catch (err) {
      if (err.code == 'ENOENT') {
        return null;
      }
      throw err;
    }
  }
  /**
   * Write the contents of buffer to a symlink.
   */
  writelink (filename, buffer) async {
    return this._symlink(buffer.toString('utf8'), filename);
  }

  lock (filename, triesLeft = 3) async {
    // check to see if we still have it
    if (delayedReleases.has(filename)) {
      clearTimeout(delayedReleases.get(filename));
      delayedReleases.delete(filename);
      return;
    }
    if (triesLeft === 0) {
      throw new GitError(E.AcquireLockFileFail, { filename });
    }
    try {
      await this._mkdir(`${filename}.lock`);
    } catch (err) {
      if (err.code === 'EEXIST') {
        await sleep(100);
        await this.lock(filename, triesLeft - 1);
      }
    }
  }

  unlock (filename, delayRelease = 50) async {
    if (delayedReleases.has(filename)) {
      throw new GitError(E.DoubleReleaseLockFileFail, { filename });
    }
    // Basically, we lie and say it was deleted ASAP.
    // But really we wait a bit to see if you want to acquire it again.
    delayedReleases.set(
      filename,
      setTimeout(() async => {
        delayedReleases.delete(filename);
        await this._rmdir(`${filename}.lock`);
      }, delayRelease)
    )
  }
}