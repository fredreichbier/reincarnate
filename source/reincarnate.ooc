import reincarnate/App

import reincarnate/frontends/File

main: func {
    app = App new()
    app addFrontend(FileFrontend new())
    app installLatestVersion("ooc-yajl")
}
