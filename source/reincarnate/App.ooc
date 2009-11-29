import structs/[ArrayList,HashMap]
import os/Env
import io/FileReader

import reincarnate/[Config, Frontend, Backend, Usefile, Nirvana, Net, FileSystem]
import reincarnate/backends/Simple

App: class {
    config: Config
    frontends: ArrayList<Frontend>
    backend: Backend
    nirvana: Nirvana
    fileSystem: FileSystem

    init: func {
//        config = Config new("reincarnate.json")
        backend = SimpleBackend new()
        frontends = ArrayList<Frontend> new()
        nirvana = Nirvana new("http://nirvana.ooc-lang.org/api%s", "http://nirvana.ooc-lang.org%s")
        oocLibs := Env get("OOC_LIBS")
        if(!oocLibs) {
            oocLibs = "/var/lib/ooc" /* TODO */
        }
        fileSystem = FileSystem new("/tmp", "/var/tmp", oocLibs) /* TODO: nicer baseDir ;) */
    }

    addFrontend: func (frontend: Frontend) {
        frontends add(frontend)
    }

    installUsefile: func (location: String) {
        usefile := Usefile new(Net downloadString(Net resolveLocation(location)))
        backend installPackage(usefile)
    }

    installLatestVersion: func (package: String) {
        backend installPackage(Usefile new(nirvana getLatestUsefile(package)))
    }

    downloadPackage: func (usefile: Usefile) -> String {
        dir := fileSystem getPackageDirectory(usefile get("Name"))
        for(frontend: Frontend in frontends) {
            if(frontend accept(usefile)) {
                frontend downloadTo(usefile, dir)
                return dir
            }
        }
        FrontendError new(This, "No matching frontend found: %s" format(usefile get("Name"))) throw()
        return null
    }
}

app: App
