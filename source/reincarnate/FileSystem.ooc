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
            after@ = name substring(idx, name length())
        return true
    }

    getPackageFilename: func (name: String) -> String {
        baseName, ext: String
        if(!splitExt(name, baseName&, ext&)) {
            baseName = name
            ext = ""
        }
        yard := File new(app config get("Paths.Yard", String))
        if(!yard exists()) {
            yard mkdir()
        }
        baseBaseName := baseName
        i := 1
        while(yard getChild(baseName + ext) exists()) {
            baseName = "%s%d" format(baseBaseName, i)
            i += 1
        }
        return yard getChild(baseName + ext) path
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
        Return the name of the directory.
    */
    /* TODO: windows/whatever. */
    extractPackage: func (filename, destination: String) -> String {
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
        /* extract. */
        if(!File new(destination) exists()) {
           File new(destination) mkdir()
        }
        proc := Process new(["tar", "-xvf", filename, "-C", destination] as ArrayList<String>)
        proc setStdout(null)
        result = proc execute()
        if(result != 0) {
            Exception new(This, "`tar` ended unexpectedly (%d)." format(result)) throw()
        }
        return File new(destination) getChild(dir) path
    }

    remove: func (path: File) {
        Process new(["rm", "-rf", path path] as ArrayList<String>) execute()
    }
}
 
