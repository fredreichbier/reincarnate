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
        packageDir := app fileSystem extractPackage(fname, oocLibsDir path)
        /* we're done :) */
        File new(packageDir)
    }
    
    /** we take it easy: updating is removing plus reinstallation */
    update: func (libDir: File) {
        dir := libDir parent()
        remove()
        install(dir)
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
