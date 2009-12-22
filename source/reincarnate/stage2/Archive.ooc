import io/File

import deadlogger/Log

import reincarnate/[App, Usefile, Package]
import reincarnate/stage2/Stage2

logger := Log getLogger("reincarnate.stage2.Archive")

ArchivePackage: class extends Package {
    init: func ~usefile (=app, =usefile) {}

    install: func (oocLibsDir: File) -> File {
        logger debug("Installing '%s' to '%s'" format(usefile get("_Slug"), oocLibsDir path))
        /* first, download the archive to the yard. */
        url := usefile get("Origin")
        fname := app fileSystem getPackageFilename(app net getBaseName(url))
        logger debug("Downloading '%s' to '%s'" format(url, fname))
        app net downloadFile(url, fname)
        /* then, extract to $OOC_LIBS. */
        libDir := oocLibsDir getChild(getLibDirName())
        app fileSystem extractPackage(fname, libDir path)
        /* we're done :) */
        libDir
    }
    
    /** we take it easy: updating is removing plus reinstallation */
    update: func (libDir: File, usefile: Usefile) {
        dir := libDir parent()
        if(this usefile get("_Keep") == null) {
            /* only remove the old stuff if the user doesn't want to "keep" the old version. */
            remove(libDir)
            /* remove the old usefile. */
            app removeUsefile(this usefile)
        }
        app install(app doStage2(usefile))
    }

    /** just - remove - the - folder. :( */
    remove: func (libDir: File) {
        app fileSystem remove(libDir)
    }
}

ArchiveS2: class extends Stage2 {
    init: func (=app) {}

    getPackage: func (usefile: Usefile) -> Package {
        return ArchivePackage new(app, usefile)        
    }
}
