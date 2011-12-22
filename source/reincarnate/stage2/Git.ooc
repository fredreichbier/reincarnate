import os/Process
import io/File
import structs/ArrayList

import deadlogger/Log

import reincarnate/[App, Usefile, Package]
import reincarnate/stage2/Stage2

logger := Log getLogger("reincarnate.stage2.Git")

GitPackage: class extends Package {
    init: func ~usefile (=app, =usefile) {}

    install: func (oocLibsDir: File) -> File {
        logger debug("Installing '%s' to '%s'" format(usefile get("_Slug"), oocLibsDir path))
        /* so, `Origin` is the address of the git repository. `git clone` it to `oocLibsDir path / getLibDirName()`. */
        /* TODO: check if we're overwriting something. */
        dest := oocLibsDir getChild(getLibDirName())
        if(dest exists?()) {
            logger error("'%s' already exists. Should not happen." format(dest path))
        }
        Process new(["git", "clone", usefile get("Origin"), dest path] as ArrayList<String>) execute()
        /* done. */
        dest
    }
    
    /** do `git pull`. */
    update: func (libDir: File, usefile: Usefile) {
        proc := Process new(["git", "pull"] as ArrayList<String>)
        proc setCwd(libDir path) .execute()
    }

    /** remove the folder. */
    remove: func (libDir: File) {
        app fileSystem remove(libDir)
    }
}

GitS2: class extends Stage2 {
    init: func (=app) {}

    getPackage: func (usefile: Usefile) -> Package {
        return GitPackage new(app, usefile)        
    }
}

