import structs/[ArrayList,HashMap]
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
        fileSystem = FileSystem new("/tmp", "/var/tmp") /* TODO: nicer baseDir ;) */
    }

    installUsefile: func (location: String) {
        usefile := Usefile new(Net downloadString(Net resolveLocation(location)))
        backend installPackage(usefile)
    }
}

app: App
