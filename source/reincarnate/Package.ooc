import io/File
import structs/ArrayList

import reincarnate/[App, Usefile]

Package: abstract class {
    app: App
    usefile: Usefile

    init: func (=app, =usefile) {}

    install: abstract func (oocLibsDir: File)
    install: func ~fromConfig {
        install(File new(app config get("Paths.oocLibs", String)))
    }

    update: abstract func (libDir: File)
    update: func ~guess {
        /* look for the usefile in the subdir of the oocLibs directory. */
        usefileName := "%s.use" format(usefile get("Name"))
        oocLibs := File new(app config get("Paths.oocLibs", String))
        for(child: File in oocLibs getChildren()) {
            if(child getChild(usefileName) exists()) {
                /* ffffound! */
                update(child)
                return
            }
        }
        /* not found :( */
        Exception new(This, "Couldn't find the package '%s'. Sure it's installed?" format(usefileName)) throw()
    }
}
