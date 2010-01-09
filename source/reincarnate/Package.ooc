import io/File
import structs/ArrayList

import deadlogger/Log

import reincarnate/[App, Checksums, Usefile]

logger := Log getLogger("reincarnate.Package")

Package: abstract class {
    app: App
    usefile: Usefile

    init: func (=app, =usefile) {}

    guessLibDir: func -> File {
        usefile get("_LibDir") println()
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
            checksums_sig := app net downloadString(usefile get("_ChecksumsSignatureURL"))
            checksums_text := app net downloadString(usefile get("_ChecksumsURL"))
            if(!checksums_text trim() isEmpty()) {
                /* TODO: check signature */
                checksums := Checksums new(null)
                checksums readUsefile(checksums_text) /* TODO: workaround for #60, I think */
                if(!checksums check(fname))
                    Exception new(This, "The package at %s could not be verified." format(fname)) throw()
                else
                    logger info("The package %s was verified." format(fname))
            } else {
                logger warn("The package at %s does not have any checksums." format(fname))
            }
        }
    }
}
