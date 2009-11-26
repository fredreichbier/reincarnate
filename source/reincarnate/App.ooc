import structs/[ArrayList,HashMap]
import os/Env
import io/FileReader

import reincarnate/[Config, Backend, Usefile, Nirvana, Net, FileSystem]
import reincarnate/backends/Simple

App: class {
    config: Config
    backend: Backend
    nirvana: Nirvana
    fileSystem: FileSystem

    init: func {
//        config = Config new("reincarnate.json")
        backend = SimpleBackend new()
//        nirvana = ...
        oocLibs := Env get("OOC_LIBS")
        if(!oocLibs) {
            oocLibs = "/var/lib/ooc" /* TODO */
        }
        fileSystem = FileSystem new("/tmp", "/var/tmp", oocLibs) /* TODO: nicer baseDir ;) */
    }

    installUsefile: func (location: String) {
        usefile := Usefile new(Net downloadString(Net resolveLocation(location)))
        backend installPackage(usefile)
    }
}

app: App
