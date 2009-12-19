use deadlogger

import io/[File, FileReader]
import structs/HashMap

import deadlogger/[Log, Handler, Formatter]

import reincarnate/[Config, FileSystem, Net, Nirvana, Usefile, Package, Version]
import reincarnate/stage1/[Stage1, Local, Nirvana, URL]
import reincarnate/stage2/[Stage2, Archive]

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
    fileSystem: FileSystem
    stages1: HashMap<Stage1>
    stages2: HashMap<Stage2>

    init: func {
        /* initialize attributes. */
        config = Config new(this)
        net = Net new(this)
        fileSystem = FileSystem new(this)
        stages1 = HashMap<Stage1> new()
        stages2 = HashMap<Stage2> new()
        nirvana = Nirvana new(this)
        /* fill stages. */
        /* stage 1 */
        addStage1("local", LocalS1 new(this))
        addStage1("nirvana", NirvanaS1 new(this))
        addStage1("url", URLS1 new(this))
        /* stage 2 */
        addStage2("archive", ArchiveS2 new(this))
    }

    addStage1: func (nickname: String, stage: Stage1) {
        stages1[nickname] = stage
    }

    addStage2: func (nickname: String, stage: Stage2) {
        stages2[nickname] = stage
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
        logger debug("Doing stage 1 nickname '%s' on '%s', version '%s'." format(nickname, location, ver))
        stages1[nickname] getUsefile(location, ver)
    }

    /** create a `Package` object using the usefile `usefile` somehow. */
    doStage2: func (usefile: Usefile) -> Package {
        /* get the `Origin` option which describes the location of the sourcecode. */
        origin := usefile get("Origin")
        if(origin == null) {
            Exception new(This, "`Origin` of '%s' is null. Can't do stage 2." format(usefile get("_Slug"))) throw()
        }
        scheme := Net getScheme(origin)
        nickname := "archive"
        logger debug("Doing stage 2 nickname '%s' on '%s'." format(nickname, usefile get("_Slug")))
        stages2[nickname] getPackage(usefile)
    }

    /** install the package described by `location`: do stage 1, do stage 2, install. */
    install: func (location: String) {
        logger info("Installing package '%s'" format(location))
        usefile := doStage1(location)
        package := doStage2(usefile)
        package install()
    }

    /** remove the package described by `name`: get the usefile, stage 2 and ready. */
    remove: func (name: String) {
        /* look for the usefile in the subdir of the oocLibs directory. */
        logger info("Removing package '%s'" format(name))
        usefileName := "%s.use" format(name)
        oocLibs := File new(config get("Paths.oocLibs", String))
        for(child: File in oocLibs getChildren()) {
            if(child getChild(usefileName) exists()) {
                /* ffffound! */
                reader := FileReader new(child getChild(usefileName) path)
                usefile := Usefile new(reader)
                usefile put("_Slug", name)
                reader close()
                package := doStage2(usefile)
                package remove(child)
                return
            }
        }
        /* not found :( */
        Exception new(This, "Couldn't find the package '%s'. Sure it's installed?" format(name)) throw()   
    }

    /** update the package described by `name`: get the usefile, do stage 2 and call `update` */
    /* TODO: do it cooler. */
    update: func (name: String) {
        /* look for the usefile in the subdir of the oocLibs directory. */
        logger info("Updating package '%s'" format(name))
        usefileName := "%s.use" format(name)
        oocLibs := File new(config get("Paths.oocLibs", String))
        for(child: File in oocLibs getChildren()) {
            if(child getChild(usefileName) exists()) {
                /* ffffound! */
                reader := FileReader new(child getChild(usefileName) path)
                usefile := Usefile new(reader)
                usefile put("_Slug", name)
                reader close()
                package := doStage2(usefile)
                package update(child)
                return
            }
        }
        /* not found :( */
        Exception new(This, "Couldn't find the package '%s'. Sure it's installed?" format(name)) throw()   
    }
}

