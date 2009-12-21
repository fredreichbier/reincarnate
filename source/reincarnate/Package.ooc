import io/File
import structs/ArrayList

import reincarnate/[App, Usefile]

Package: abstract class {
    app: App
    usefile: Usefile

    init: func (=app, =usefile) {}

    guessLibDir: func -> File {
        /* look for the usefile in the subdir of the oocLibs directory. */
        usefileName := "%s.use" format(usefile get("_Slug"))
        oocLibs := File new(app config get("Paths.oocLibs", String))
        for(child: File in oocLibs getChildren()) {
            if(child getChild(usefileName) exists()) {
                /* ffffound! */
                return child
            }
        }
        /* not found :( */
        Exception new(This, "Couldn't find the package '%s'. Sure it's installed?" format(usefile get("_Slug"))) throw()   
        return null
    }

    install: abstract func (oocLibsDir: File) -> File
    install: func ~fromConfig -> File {
        install(File new(app config get("Paths.oocLibs", String)))
    }

    update: abstract func (libDir: File)
    update: func ~guess {
        update(guessLibDir())
    }

    remove: abstract func (libDir: File)
    remove: func ~guess {
        update(guessLibDir())
    }
}
