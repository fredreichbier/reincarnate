import io/File
import structs/ArrayList

import reincarnate/[App, Usefile]

Package: abstract class {
    app: App
    usefile: Usefile

    init: func (=app, =usefile) {}

    guessLibDir: func -> File {
        usefile get("_LibDir") println()
        return File new(usefile get("_LibDir"))
    }

    getLibDirName: func -> String {
        return "%s-%s" format(usefile get("_Slug"), usefile get("Version"))
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
}
