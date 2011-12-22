import io/[File, FileReader]
import structs/ArrayList

use deadlogger
import deadlogger/Log

import reincarnate/[App, Dependencies, Package, Usefile, Variant, Version]

logger := Log getLogger("reincarnate.Yard")

Yard: class {
    app: App
    yardPath: File

    init: func (=app) {
        this yardPath = app config get("Paths.Yard", File) /* FIXME: interestingly, without `this` it does not compile */
    }

    _getYardPath: func ~usefile (usefile: Usefile) -> File {
        return _getYardPath~slug(usefile get("_Slug"), usefile get("Version") , usefile get("Variant") )
    }

    _getYardPath: func ~slug (slug: String, ver, variant: String) -> File {
        if (!variant)
            variant = app config get("Nirvana.DefaultVariant", String)
        
        return yardPath getChild("%s-%s-%s.use" format(slug, ver, variant))
    }

    _getYardPath: func ~latest (slug: String) -> File {
        ver := null 
        variant := null 
        if(slug contains?('/')) {
            variant = Variant fromLocation(slug)
            slug = slug substring(0, slug lastIndexOf('/'))
        }
        if(slug contains?('=')) {
            ver = Version fromLocation(slug)
            slug = slug substring(0, slug indexOf('='))
        }        
        if(ver == null)
            ver = getLatestInstalledVersion(slug)
        if(variant == null)
            variant = getAnyVariant(slug, ver)
        return _getYardPath(slug, ver, variant)
    }

    getInstalledVersions: func (slug: String) -> ArrayList<String> {
        versions := ArrayList<String> new()
        slugLength := slug length()
        for(child: File in yardPath getChildren()) {
            if(child name() startsWith?(slug + "-")) {
                name := child name()
                lastHyphen := name lastIndexOf('-')
                versions add(name substring(slugLength + 1, lastHyphen) ) /* - ".use" - variant */
            }
        }
        return versions
    }

    getInstalledVariants: func (slug, ver: String) -> ArrayList<Variant> {
        variants := ArrayList<String> new()
        start := "%s-%s-" format(slug, ver)
        startLength := start length()
        for(child: File in yardPath getChildren()) {
            if(child name() startsWith?(start)) {
                name := child name()
                variants add(name substring(startLength, name length() - 4) ) /* - ".use" */
            }
        }
        return variants
    }

    getLatestInstalledVersion: func (slug: String) -> String {
        getLatestVersionOf(getInstalledVersions(slug))
    }

    getAnyVariant: func (slug, ver: String) -> Variant {
        return getInstalledVariants(slug, ver) get(0) /* TODO: get the default variant first? */
    }

    getLatestVersionOf: static func (versions: ArrayList<String>) -> String {
        latest := null 
        for(ver: String in versions) {
            if(latest == null || Version isGreater(ver, latest))
                latest = ver
        }
        return latest
    }

    /** find a version of `requirement slug` (in the "nirvana" stage1.) that 
      * meets `requirement` and return the greatest. If there is none, return null. 
      */
    findVersion: func (requirement: Requirement) -> String {
        versions := app nirvana getVersions(requirement slug)
        meeting := ArrayList<String> new()
        if(versions != null) {
            for(ver: String in versions) {
                if(requirement meets(ver)) {
                    meeting add(ver)
                }
            }
            return getLatestVersionOf(meeting)
        }
        return null 
    }

    /** return a list of installed packages. **/
    getPackages: func -> ArrayList<Package> {
        ret := ArrayList<Package> new()
        for(name: String in yardPath getChildrenNames()) {
            if(name endsWith?(".use")) {
                reader := FileReader new(yardPath getChild(name))
                usefile := Usefile new(reader)
                ret add(app doStage2(usefile))
                reader close()
            }
        }
        return ret
    }

    /** return a list of package locations. **/
    getPackageLocations: func -> ArrayList<String> {
        ret := ArrayList<String> new()
        for(package: Package in getPackages()) {
            ret add(package getLocation())
        }
        return ret
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
}
