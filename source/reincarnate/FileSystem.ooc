import io/File
import os/[Pipe, PipeReader, Process]
import structs/ArrayList
import text/StringTokenizer
 
import reincarnate/App

// TODO: Part of this is hacky and part of this is Linux-specific.

FileSystem: class {
    app: App

    init: func (=app) {}

    splitExt: static func (name: String, before, after: String*) -> Bool {
        idx := name lastIndexOf('.')
        if(idx == -1) {
            return false
        }
        if(before != null)
            before@ = name substring(0, idx)
        if(after != null)
            after@ = name substring(idx)
        return true
    }

    getPackageFilename: func (name: String) -> String {
        baseName, ext1, ext2: String
        if(!splitExt(name, baseName&, ext1&)) {
            baseName = name
            ext1 = ""
        }
        _baseName := baseName clone()
        /* TODO: that's a dirty workaround for .tar.* */
        if(!splitExt(_baseName, baseName&, ext2&)) {
            baseName = name
            ext2 = ext1
        } else {
            ext2 = ext2 + ext1
        }
        temp := File new(app config get("Paths.Temp", String))
        baseBaseName := baseName
        i := 1
        while(temp getChild(baseName + ext2) exists()) {
            baseName = "%s%d" format(baseBaseName, i)
            i += 1
        }
        return temp getChild(baseName + ext2) path
    }

    getTempFilename: func (name: String) -> String {
        temp := File new(app config get("Paths.Temp", String))
        i := 1
        base := name
        while(temp getChild(name) exists()) {
            name = "%s.%d" format(base, i)
            i += 1
        }
        return temp getChild(name) path
    }

    _executeWithOutput: func (args: ArrayList<String>, output: String*) -> Int {
        proc := Process new(args)
        proc setStdout(Pipe new()) 
        result := proc execute()
        
        output@ = PipeReader new(proc stdOut) toString()
 
        proc stdOut close('r'). close('w')
        proc setStdout(null)
        result
    }

    _getContentsList: func (filename, ext1, ext2: String) -> String {
        output: String
        line := null
        if(ext2 == ".tar.gz" || ext2 == ".tar.bz2") {
            line = ["tar", "-tf", filename] as ArrayList<String>
        } else if(ext2 == ".tar.xz") {
            line = ["tar", "--use-compress-program", "xz", "-tf", filename] as ArrayList<String>
        } else {
            Exception new("Unknown archive format: %s" format(filename)) throw()
        }
        ret := _executeWithOutput(line, output&)
        if(ret != 0) {
            Exception new(This, "`tar` ended unexpectedly (%d)." format(ret)) throw()
        }
        return output
    }

    _getExtractCommand: func (filename, ext1, ext2, dest: String) -> ArrayList<String> {
        if(ext2 == ".tar.gz" || ext2 == ".tar.bz2")
            return ["tar", "-xvf", filename, "-C", dest] as ArrayList<String>
        else if(ext2 == ".tar.xz")
            return ["tar", "-xvf", filename, "--use-compress-program", "xz", "-C", dest] as ArrayList<String>
        
        Exception new("Unknown archive format: %s" format(filename)) throw()
        return null
    }

    /** extract an archive archive (package) to the directory `directory`, but check for evil stuff before.
        The archive is required to contain exactly one directory with the package stuff inside.
        This directory should be at `destination` after this operation.
    */
    /* TODO: windows/whatever. */
    extractPackage: func (filename, destination: String) {
        ext1 := ""
        ext2 := ""
        before := ""
        splitExt(filename, before&, ext1&)
        splitExt(before, null, ext2&)
        ext2 = ext2 + ext1
        /* test for evilness */
        output := _getContentsList(filename, ext1, ext2)
        dir := null as String
        for(line: String in output split('\n')) {
            if(line isEmpty()) {
                continue
            }
            if(dir == null && line contains(File separator)) {
                dir = line substring(0, line indexOf(File separator))
            }
            line println()
            if(!line contains(File separator) \
                || !line startsWith(dir) \
                || line startsWith('/')) {
                Exception new(This, "Malformed package archive. '%s' shouldn't be there." format(line)) throw()
            }
        }
        /* extract, first to a temporary directory. */
        temp := app config get("Paths.Temp", File)
        proc := Process new(_getExtractCommand(filename, ext1, ext2, temp path))
        proc setStdout(null)
        result := proc execute()
        if(result != 0) {
            Exception new(This, "`tar` ended unexpectedly (%d)." format(result)) throw()
        }
        /* move this temporary directory to `destination`. */
        Process new(["mv", temp getChild(dir) path, destination] as ArrayList<String>) execute()
    }

    remove: static func (path: File) {
        Process new(["rm", "-rf", path path] as ArrayList<String>) execute()
    }

    getSha512: static func (path: String) -> String {
        outp := Process new(["sha512sum", path] as ArrayList<String>) getOutput()
        outp split(" ") iterator() as Iterator<String> next()
    }
}
 
