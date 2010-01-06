import io/File

import deadlogger/Log

import reincarnate/[App, Usefile, Package]
import reincarnate/stage2/Stage2

logger := Log getLogger("reincarnate.stage2.Meatshop")

MeatshopPackage: class extends Package {
    init: func ~usefile (=app, =usefile) {}

    install: func (oocLibsDir: File) -> File {
        /* get the local filename ... */
        filename := app net getBaseName(usefile get("Origin"))
        logger debug("Installing '%s' to '%s'" format(usefile get("_Slug"), oocLibsDir path))
        /* first, download the archive to the yard. */
        fname := app fileSystem getPackageFilename(filename)
        /* construct url. */
        url := app mirrors getUrl(usefile get("_Slug"), usefile get("Version"), filename)
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
        app remove(this)
        app install(app doStage2(usefile))
    }

    /** just - remove - the - folder. :( */
    remove: func (libDir: File) {
        app fileSystem remove(libDir)
    }
}

MeatshopS2: class extends Stage2 {
    init: func (=app) {}

    getPackage: func (usefile: Usefile) -> Package {
        return MeatshopPackage new(app, usefile)        
    }
}
