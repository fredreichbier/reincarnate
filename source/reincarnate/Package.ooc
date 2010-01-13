import io/File
import structs/ArrayList
import text/Shlex
import os/Process

import deadlogger/Log

import reincarnate/[App, Checksums, Usefile, YesNo]

logger := Log getLogger("reincarnate.Package")

Package: abstract class {
    app: App
    usefile: Usefile

    init: func (=app, =usefile) {}

    guessLibDir: func -> File {
        return File new(usefile get("_LibDir"))
    }

    getLibDirName: func -> String {
        return "%s-%s-%s" format(usefile get("_Slug"), usefile get("Version"), usefile get("Variant"))
    }

    install: abstract func (oocLibsDir: File) -> File
    install: func ~fromConfig -> File {
        install(File new(app config get("Paths.oocLibs", String)))
    }

    update: abstract func (libDir: File, usefile: Usefile)
    update: func ~guess (usefile: Usefile) {
        update(guessLibDir(), usefile)
    }

    remove: abstract func (libDir: File)
    remove: func ~guess {
        remove(guessLibDir())
    }

    getLocation: func -> String {
        "%s=%s" format(usefile get("_Slug"), usefile get("Version"))
    }

    check: func (fname: String) {
        if(usefile contains("_ChecksumsURL")) {
            checksumsText := app net downloadString(usefile get("_ChecksumsURL"))
            if(!checksumsText trim() isEmpty()) {
                checksumsSig := app fileSystem getTempFilename("sig")
                app net downloadFile(usefile get("_ChecksumsSignatureURL"), checksumsSig) /* TODO: "sig"? */
                if(!app gpg verify(checksumsText, File new(checksumsSig)))
                    Exception new(This, "The checksums of %s could not be verified." format(fname)) throw()
                else
                    logger info("The checksums of %s were verified." format(fname))
                checksums := Checksums new(null)
                checksums readUsefile(checksumsText) /* TODO: workaround for #60, I think */
                if(!checksums check(fname))
                    Exception new(This, "The package at %s could not be verified." format(fname)) throw()
                else
                    logger info("The package %s was verified." format(fname))
            } else {
                logger warn("The package at %s does not have any checksums." format(fname))
            }
        }
    }

    getBinaryNames: func -> ArrayList<String> {
        result := ArrayList<String> new()
        if(usefile contains("Binaries")) {
            for(binary: String in usefile get("Binaries") split(',')) {
                result add(binary trim())
            }
        }
        return result
    }

    /** Copy binaries. This package has to be installed already. */
    copyBinaries: func {
        libDir := guessLibDir()
        binDir := app config get("Paths.Binaries", File)
        if(!binDir exists())
            binDir mkdirs()
        for(name: String in getBinaryNames()) {
            srcChild := libDir getChild(name)
            if(!srcChild exists()) {
                logger critical("Binary file does not exist: %s" format(srcChild path))
            } else {
                destChild := binDir getChild(name)
                if(destChild exists()) {
                    logger critical("Binary file destination already exists: %s" format(destChild path))
                } else {
                    logger info("Installing %s to %s" format(srcChild path, destChild path))
                    srcChild copyTo(destChild)
                }
            }
        }
    }

    removeBinaries: func {
        binDir := app config get("Paths.Binaries", File)
        for(name: String in getBinaryNames()) {
            child := binDir getChild(name)
            if(!child exists()) {
                logger critical("Binary file does not exist: %s" format(child path))
            } else {
                logger info("Removing %s" format(child path))
                child remove()
            }
        }
    }

    /** If the usefile has a "Build" entry, ask the user if he'd like to invoke it. */
    build: func {
        if(usefile contains("Build")) {
            cmd := usefile get("Build")
            /* ask the user. */
            libDirPath := guessLibDir() path
            want := YesNo ask("Do you want to invoke `%s`? You can inspect the package contents at %s." format(cmd, libDirPath), true)
            if(want) {
                logger info("Invoking %s ..." format(cmd))
                splitted := Shlex split(cmd)
                proc := Process new(splitted)
                proc setCwd(libDirPath)
                ret := proc execute()
                if(ret != 0) {
                    logger warn("Build failed. Return code: %d" format(ret))
                } else {
                    logger info("Build succeeded.")
                }
            } else {
                logger info("Build not invoked.")
            }
        } else {
            logger info("No build info found.")
        }
    }
}
