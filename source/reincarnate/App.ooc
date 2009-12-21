use deadlogger

import io/[File, FileReader, FileWriter]
import structs/HashMap

import deadlogger/[Log, Handler, Formatter]

import reincarnate/[Config, FileSystem, Net, Nirvana, Usefile, Package, Version]
import reincarnate/stage1/[Stage1, Local, Nirvana, URL]
import reincarnate/stage2/[Stage2, Archive, Git]

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
        addStage2("git", GitS2 new(this))
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
        usefile := stages1[nickname] getUsefile(location, ver)
        usefile put("_Stage1", nickname) .put("_Location", location)
        usefile
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
        if(scheme == "git") {
            /* git repo! */
            nickname = "git"
        }
        logger debug("Doing stage 2 nickname '%s' on '%s'." format(nickname, usefile get("_Slug")))
        usefile put("_Stage2", nickname)
        stages2[nickname] getPackage(usefile)
    }

    _getYardPath: func ~usefile (usefile: Usefile) -> File {
        return _getYardPath(usefile get("_Slug"))
    }

    _getYardPath: func ~slug (slug: String) -> File {
        yard := config get("Paths.Yard", File)
        return yard getChild("%s.use" format(slug))
    }

    /** store this usefile in the yaaaaaaaaaard. */
    dumpUsefile: func (usefile: Usefile) {
        path := _getYardPath(usefile) path
        logger debug("Storing usefile in the yard at '%s'." format(path))
        writer := FileWriter new(path)
        writer write(usefile dump())
        writer close()
    }

    /* get the usefile from the yard. */
    getUsefile: func (slug: String) -> Usefile {
        reader := FileReader new(_getYardPath(slug))
        usefile := Usefile new(reader)
        reader close()
        usefile
    }

    /** remove the usefile from the yard. */
    removeUsefile: func (usefile: Usefile) {
        path := _getYardPath(usefile)
        if(path remove() == 0) {
            logger debug("Removed usefile from the yard at '%s'." format(path path))
        } else {
            logger warn("Couldn't remove the usefile at '%s'." format(path path))
        }
    }
    
    /** install the package described by `location`: do stage 1, do stage 2, install. */
    install: func (location: String) {
        logger info("Installing package '%s'" format(location))
        usefile := doStage1(location)
        package := doStage2(usefile)
        libDir := package install()
        usefile put("_LibDir", libDir getAbsolutePath())
        dumpUsefile(usefile)
        logger info("Installation of '%s' done." format(location))
    }

    /** remove the package described by `name`: get the usefile from the yard, stage 2 and ready. */
    remove: func (name: String) {
        /* look for the usefile in the subdir of the oocLibs directory. */
        logger info("Removing package '%s'" format(name))
        usefile := getUsefile(name)
        package := doStage2(usefile)
        libDir := File new(usefile get("_LibDir"))
        package remove(libDir)
        removeUsefile(usefile)
        logger info("Removal of '%s' done." format(name))
    }

    /** update the package described by `name`: get the usefile, do stage 2 and call `update` */
    /* TODO: do it cooler. */
    update: func (name: String) {
        /* look for the usefile in the subdir of the oocLibs directory. */
        logger info("Updating package '%s'" format(name))
        usefile := getUsefile(name)
        stage1 := stages1[usefile get("_Stage1")]
        hasUpdates := stage1 hasUpdates(usefile get("_Location"), usefile) /* stupid workaround. TODO. */
        if(hasUpdates) {
            /* has updates! update me, baby! */
            stage2 := doStage2(usefile)
            libDir := File new(usefile get("_LibDir"))
            stage2 update(libDir)
        } else {
            logger info("Couldn't find updates for '%s'" format(name))
        }
    }
}

