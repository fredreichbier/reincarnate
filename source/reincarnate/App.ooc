use deadlogger

import io/[File, FileReader, FileWriter]
import structs/[ArrayList, HashMap]
import text/StringTokenizer

import deadlogger/[Log, Handler, Formatter]

import reincarnate/[Checksums, Config, Dependencies, FileSystem, GPG, Mirrors, Net, Nirvana, Usefile, Package, Variant, Version, Yard]
import reincarnate/stage1/[Stage1, Local, Nirvana, URL]
import reincarnate/stage2/[Stage2, Archive, Meatshop, Git]

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
    mirrors: Mirrors
    nirvana: Nirvana
    fileSystem: FileSystem
    stages1: HashMap<String, Stage1>
    stages2: HashMap<String, Stage2>
    yard: Yard
    gpg: GPG

    init: func {
        /* initialize attributes. */
        config = Config new(this)
        net = Net new(this)
        fileSystem = FileSystem new(this)
        mirrors = Mirrors new(this)
        stages1 = HashMap<String, Stage1> new()
        stages2 = HashMap<String, Stage2> new()
        nirvana = Nirvana new(this)
        yard = Yard new(this)
        gpg = GPG new(this)
        /* fill stages. */
        /* stage 1 */
        addStage1("local", LocalS1 new(this))
        addStage1("nirvana", NirvanaS1 new(this))
        addStage1("url", URLS1 new(this))
        /* stage 2 */
        addStage2("archive", ArchiveS2 new(this))
        addStage2("git", GitS2 new(this))
        addStage2("meatshop", MeatshopS2 new(this))
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
        ver := null as Version
        variant := null as Variant
        if(location contains('/')) {
            variant = Variant fromLocation(location)
            location = location substring(0, location lastIndexOf('/'))
        } else {
            variant = config get("Nirvana.DefaultVariant", String) as Variant
        }
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
        logger debug("Doing stage 1 nickname '%s' on '%s', version '%s', variant '%s'." format(nickname, location, ver, variant))
        usefile := stages1[nickname] getUsefile(location, ver, variant)
        usefile put("_Stage1", nickname) .put("_Location", location)
        usefile
    }

    /** create a `Package` object using the usefile `usefile` somehow. */
    doStage2: func (usefile: Usefile) -> Package {
        /* get the `Origin` option which describes the location of the sourcecode. */
        origin := usefile get("Origin")
        usefile dump() println()
        if(origin == null) {
            Exception new(This, "`Origin` of '%s' is null. Can't do stage 2." format(usefile get("_Slug"))) throw()
        }
        scheme := Net getScheme(origin)
        nickname := "archive"
        if(scheme == "git") {
            /* git repo! */
            nickname = "git"
        } else if(scheme == "meatshop") {
            /* meatshop! */
            nickname = "meatshop"
        }
        logger debug("Doing stage 2 nickname '%s' on '%s'." format(nickname, usefile get("_Slug")))
        usefile put("_Stage2", nickname)
        stages2[nickname] getPackage(usefile)
    }

    /** store this usefile in the yaaaaaaaaaard. */
    dumpUsefile: func (usefile: Usefile) {
        path := yard _getYardPath(usefile) path
        logger debug("Storing usefile in the yard at '%s'." format(path))
        writer := FileWriter new(path)
        writer write(usefile dump())
        writer close()
    }

    keep: func (name: String) {
        logger info("Keeping package '%s'" format(name))
        usefile := yard getUsefile(name)
        usefile put("_Keep", "yes")
        dumpUsefile(usefile)
    }

    unkeep: func (name: String) {
        logger info("Unkeeping package '%s'" format(name))
        usefile := yard getUsefile(name)
        usefile remove("_Keep")
        dumpUsefile(usefile)
    }
    
    installedPackages: func -> ArrayList<ArrayList<String>> {
        list := ArrayList<ArrayList<String>> new()
        for(child in yard yardPath getChildren()) {
            name := child name()
            
            if (name endsWith(".use"))
              list add(name[0..-5] split('-') toArrayList())
        }
        list
    }
       
    /** install the package described by `location`: do stage 1, do stage 2, install. */
    install: func ~usefile (location: String) {
        logger info("Installing package '%s'" format(location))
        usefile := doStage1(location)
        package := doStage2(usefile)
        install(package)
    }

    install: func ~package (package: Package) {
        /* resolve dependencies. */
        resolveDependencies(package)
        libDir := package install()
        package usefile put("_LibDir", libDir getAbsolutePath())
        dumpUsefile(package usefile)
        /* build. */
        if(config get("Reincarnate.AutoBuild", Bool))
            package build()
        /* install binaries. TODO: here? */
        package copyBinaries()
        logger info("Installation of '%s' done." format(package usefile get("Name")))
    }

    resolveDependencies: func (package: Package) {
        if(package usefile get("Requires") != null) {
            /* has requirements. */
            reqs := Requirements new(this)
            reqs parseString(package usefile get("Requires"))
            logger debug("Resolving dependencies ...")
            for(loc: String in reqs getDependencyLocations()) {
                if (yard _getYardPath(loc) exists()) {
                    logger info("Updating %s as dependency." format(loc))
                    this update(loc)
                } else {
                    logger info("Installing %s as dependency." format(loc))
                    this install(loc)
                }
            }
        }
    }

    /** remove the package described by `name`: get the usefile from the yard, stage 2 and ready. */
    remove: func (name: String) {
        /* look for the usefile in the subdir of the oocLibs directory. */
        logger info("Removing package '%s'" format(name))
        usefile := yard getUsefile(name)
        package := doStage2(usefile)
        remove(package)
    }

    remove: func ~package (package: Package) {
        if(package usefile get("_Keep") != null) {
            logger warn("Version %s has the keepflag set." format(package usefile get("Version")))
            return
        }
        libDir := File new(package usefile get("_LibDir"))
        package remove(libDir)
        /* remove binaries. TODO: here? */
        package removeBinaries()
        yard removeUsefile(package usefile)
        logger info("Removal of '%s' done." format(package usefile get("_Slug")))
    }

    /** update the package described by `name`: get the usefile, do stage 2 and call `update` */
    /* TODO: do it cooler. */
    update: func (name: String) {
        /* look for the usefile in the subdir of the oocLibs directory. */
        logger info("Updating package '%s'" format(name))
        usefile := yard getUsefile(name)
        stage1 := stages1[usefile get("_Stage1")]
        hasUpdates := stage1 hasUpdates(usefile get("_Location"), usefile) /* stupid workaround. TODO. */
        if(hasUpdates) {
            logger info("Updates for '%s'!" format(name))
            /* has updates! update me, baby! */
            package := doStage2(usefile)
            libDir := File new(usefile get("_LibDir"))
            /* get the new usefile. */
            newUsefile := stage1 getUsefile(usefile get("_Location"), null, usefile get("Variant"))
            package update(libDir, newUsefile)
        } else {
            logger info("Couldn't find updates for '%s'" format(name))
        }
    }
    
    updateAll: func {
      for (package: ArrayList<String> in installedPackages()) {
        update(package[0])
      }
    }

    /** submit the usefile to nirvana */
    submit: func ~withString (path, archiveFile: String) {
        reader := FileReader new(path)
        usefile := Usefile new(reader)
        reader close()
        slug: String
        fileSystem splitExt(File new(path) name(), slug&, null)
        submit(slug, usefile, archiveFile)
    }

    /** add the gpg public key to the keyring */
    addKey: func (filename: String) {
        gpg addKey(filename)
    }

    createChecksums: func (archiveFile: String) -> Checksums {
        checksums := Checksums new(null) as Checksums
        checksums fill(archiveFile)
        checksums
    }

    submit: func ~withUsefile (slug: String, usefile: Usefile, archiveFile: String) {
        /* TODO: check if archiveFile exists. */
        checksums := null as Checksums
        if(archiveFile != null)
            checksums = createChecksums(archiveFile)
        nirvana submitUsefile(slug, "" /* TODO */, usefile, checksums)
        /* do we have an archive? if yes, submit it, too */
        if(archiveFile != null)
            mirrors submitPackage(slug, usefile get("Version"), usefile get("Variant"), archiveFile)
    }

    build: func (loc: String) {
        logger info("Building %s ..." format(loc))
        usefile := yard getUsefile(loc)
        package := doStage2(usefile)
        package build()
    }
}

