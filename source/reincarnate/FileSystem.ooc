import io/File
import os/Process
import structs/ArrayList

FileSystem: class {
    baseDir, packageDir, libDir: File
    
    init: func (=baseDir, =packageDir, =libDir) {
        if(!baseDir exists()) {
            baseDir mkdir()
        }
        if(!packageDir exists()) {
            packageDir mkdir()
        }
        if(!libDir exists()) {
            libDir mkdir()
        }
    }

    init: func ~withString (baseDir, packageDir, libDir: String) {
        this(File new(baseDir), File new(packageDir), File new(libDir))
    }

    splitExt: static func (name: String, before, after: String*) -> Bool {
        idx := name indexOf('.')
        if(idx == -1) {
            return false
        }
        before@ = name substring(0, idx)
        after@ = name substring(idx, name length())
        return true
    }

    getPackageFilename: func (name: String) -> String {
        baseName, ext: String
        if(!splitExt(name, baseName&, ext&)) {
            baseName = name
            ext = ""
        }
        while(packageDir getChild(baseName + ext) exists()) {
            baseName = baseName + '_'
        }
        return packageDir getChild(baseName + ext) path
    }

    extract: static func (filename, destination: String) {
        args := ["tar", "-xvf", filename, "-C", destination] as ArrayList<String>
        process := SubProcess new(args)
        ret := process execute()
        "RET: %d" format(ret) println()
    }

    extractToLibdir: func (filename: String) {
        extract(filename, libDir path)
    }
}
