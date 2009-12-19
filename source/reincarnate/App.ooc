use deadlogger

import structs/HashMap

import deadlogger/[Log, Handler, Formatter]

import reincarnate/[Config, Net, Nirvana, Usefile, Version]
import reincarnate/stage1/[Stage1, Local, Nirvana, URL]

_setupLogger: func {
    console := StdoutHandler new()
    console setFormatter(ColoredFormatter new(NiceFormatter new()))
    Log root attachHandler(console)
}

_setupLogger()

logger := Log getLogger("reincarnate.App")

App: class {
    config: Config
    net: Net
    nirvana: Nirvana
    stages1: HashMap<Stage1>

    init: func {
        /* initialize attributes. */
        config = Config new(this)
        net = Net new(this)
        stages1 = HashMap<Stage1> new()
        nirvana = Nirvana new(this)
        /* fill stages. */
        /* stage 1 */
        addStage1("local", LocalS1 new(this))
        addStage1("nirvana", NirvanaS1 new(this))
        addStage1("url", URLS1 new(this))
    }

    addStage1: func (nickname: String, stage: Stage1) {
        stages1[nickname] = stage
    }

    /** try to get the usefile described by `location` somehow. */
    doStage1: func (location: String) -> Usefile {
        /* does `location` contain a version? */
        ver := null
        if(location contains('=')) {
            ver = Version fromLocation(location)
            location = location substring(0, location indexOf('='))
        }
        nickname := "nirvana"
        /* i KNOW it's dirty! */
        if(location contains("://")) {
            /* remote stage 1 */
            nickname = "url"
        } else if(location contains(".use")) {
            /* local stage 1 */
            nickname = "local"
        }
        logger info("Doing stage 1 nickname '%s' on '%s', version '%s'" format(nickname, location, ver))
        stages1[nickname] getUsefile(location, ver)
    }
}
