import io/File
import os/[Pipe, PipeReader, Process]
import structs/ArrayList
import text/StringTokenizer
 
import reincarnate/App

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
        baseName, ext: String
        if(!splitExt(name, baseName&, ext&)) {
            baseName = name
            ext = ""
        }
        temp := File new(app config get("Paths.Temp", String))
        baseBaseName := baseName
        i := 1
        while(temp getChild(baseName + ext) exists()) {
            baseName = "%s%d" format(baseBaseName, i)
            i += 1
        }
        return temp getChild(baseName + ext) path
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

    /** extract a .tar.gz archive (package) to the directory `directory`, but check for evil stuff before.
        The archive is required to contain exactly one directory with the package stuff inside.
        This directory should be at `destination` after this operation.
    */
    /* TODO: windows/whatever. */
    extractPackage: func (filename, destination: String) {
        /* test the contents. */
        output: String
        result := _executeWithOutput(["tar", "-tf", filename] as ArrayList<String>, output&)
        if(result != 0) {
            Exception new(This, "`tar` ended unexpectedly (%d)." format(result)) throw()
        }
        /* test for evilness */
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
        proc := Process new(["tar", "-xvf", filename, "-C", temp path] as ArrayList<String>)
        proc setStdout(null)
        result = proc execute()
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
        "yo" println()
        outp := Process new(["sha512sum", path] as ArrayList<String>) getOutput()
        outp split(" ") iterator() as Iterator<String> next()
    }
}
 
