use gifnooc

import io/File
import os/Env
import structs/ArrayList
import text/[Buffer, StringTokenizer]

import gifnooc/[Entity, Serialize]
import gifnooc/entities/[INI, Fixed]

import reincarnate/[App, Mirrors]

ExtList: class extends ArrayList<String> {
    init: func {
        T = String
        super()
    }

    init: func ~withCapacity (.capacity) {
        T = String
        super(capacity)
    }

    init: func ~withData (data: String*, .size) {
        T = String
        super(data, size)
    }
}

Registrar addEntry(ExtList,
    func (value: ExtList) -> String {
        buf := Buffer new()
        first := true
        for(mirror: String in value) {
            if(!first)
                buf append(", ")
            else
                first = false
            buf append(mirror)
        }
        buf toString()
    },
    func (value: String) -> ExtList {
        l := ExtList new()
        for(ext in value split(",")) {
            l add(ext trim())
        }
        l
    },
    func (value: ExtList) -> Bool { true },
    func (value: String) -> Bool { true }
)

Config: class {
    userFileName: static func -> String {
        version(linux) {
            return "%s/.reincarnate/config" format(Env get("HOME"))
        }
        return "reincarnate/config" // TODO: Do this the right way
    }

    systemFileName: static func -> String {
        version(linux) {
            return "/etc/reincarnate.conf"
        }
        return "C://reincarnate.conf" // TODO: Do this the right way
    }

    entity: Entity
    app: App

    init: func (=app) {
        /* create defaults. */
        defaults := FixedEntity new(null)
        _mirrors: MirrorList = MirrorList new()
        _mirrors add("http://meatshop.ooc-lang.org/meat/")
        _exts: ExtList = ExtList new()
        _exts add("tar.xz") .add("tar.gz") .add("tar.bz2")
        defaults addValue("Nirvana.APITemplate", "http://nirvana.ooc-lang.org/api%s") \
                .addValue("Nirvana.UsefileTemplate", "http://nirvana.ooc-lang.org%s") \
                .addValue("Nirvana.User", "") \
                .addValue("Nirvana.Token", "") \
                .addValue("Nirvana.DefaultVariant", "src") \
                .addValue("Meatshop.Mirrors", _mirrors) \
                .addValue("Meatshop.SuperMirror", "http://meatshop.ooc-lang.org") \
                .addValue("Meatshop.RelativeFilenameScheme", "/{{ package }}/{{ version }}/{{ variant }}/{{ package }}-{{ version }}-{{ variant }}.{{ type }}") \
                .addValue("Meatshop.SuperMirrorSubmit", "%s/submit") \
                .addValue("Meatshop.FileTypes", _exts) \
                .addValue("GPG.Keyring", File new("%s/.reincarnate/trusted.gpg" format(Env get("HOME")))) \
                .addValue("GPG.Executable", File new("/usr/bin/gpg")) \
                .addValue("Reincarnate.AutoBuild", true)
        if(Env get("OOC_LIBS")) {
            defaults addValue("Paths.oocLibs", File new(Env get("OOC_LIBS")))
        } else {
            version(linux) {
                defaults addValue("Paths.oocLibs", File new("/usr/lib/ooc"))
            }
        }
        version(linux) {
            defaults addValue("Paths.Temp", File new("/var/tmp/ooc")) \
                    .addValue("Paths.Yard", File new("%s/.yard" format(defaults getValue("Paths.oocLibs", String)))) \
                    .addValue("Paths.Binaries", File new("/usr/bin"))
        }
        top := defaults as Entity
        /* system-wide configuration? */
        if(File new(systemFileName()) exists()) {
            top = INIEntity new(top, systemFileName())
        }
        /* user-wide configuration? */
        if(File new(userFileName()) exists()) {
            top = INIEntity new(top, userFileName())
        }
        /* and set it. */
        entity = top
        /* create directories. now. */
        createDirectories()
    }

    /** create all directories mentioned in the configuration if they don't already exist. */
    createDirectories: func {
        file := null as File
        paths := ["Paths.oocLibs", "Paths.Yard", "Paths.Temp"] as ArrayList<String>
        for(path in paths) {
            file = get(path, File)
            if(!file exists())
                file mkdirs()
        }
        get("GPG.Keyring", File) parent() mkdirs() /* TODO. error check? */
    }

    get: func <T> (path: String, T: Class) -> T {
        entity getOption(path, T)
    }
}
