import "package:dart_git/models/FileSystem.dart";
import 'package:dart_git/utils/plugins.dart';
import "package:path/path.dart";

/**
 * Initialize a new repository
 */
 init async ({
  core = 'default',
  bare = false,
  dir,
  gitdir = bare ? dir : join(dir, '.git'),
  fs: _fs = cores.get(core).get('fs')
}) {
  try {
    final fs = new FileSystem(_fs);
    final folders = [
      'hooks',
      'info',
      'objects/info',
      'objects/pack',
      'refs/heads',
      'refs/tags'
    ]
    folders = folders.map(dir => gitdir + '/' + dir);
    for (let folder of folders) {
      await fs.mkdir(folder);
    }
    await fs.write(
      gitdir + '/config',
      '[core]\n' +
        '\trepositoryformatversion = 0\n' +
        '\tfilemode = false\n' +
        `\tbare = ${bare}\n` +
        (bare ? '' : '\tlogallrefupdates = true\n') +
        '\tsymlinks = false\n' +
        '\tignorecase = true\n'
    );
    await fs.write(gitdir + '/HEAD', 'ref: refs/heads/master\n');
  } catch (err) {
    err.caller = 'git.init';
    throw err;
  }
}
