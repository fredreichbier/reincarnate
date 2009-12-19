use gifnooc

import io/File
import os/Env

import gifnooc/Entity
import gifnooc/entities/[INI, Fixed]

import reincarnate/App

Config: class {
    userFileName: static func -> String {
        version(linux) {
            return "/home/%s/.reincarnaterc" format(Env get("USER"))
        }
    }

    systemFileName: static func -> String {
        version(linux) {
            return "/etc/reincarnate.conf"
        }
    }

    entity: Entity
    app: App

    init: func (=app) {
        /* create defaults. */
        defaults := FixedEntity new(null)
        defaults addValue("Nirvana.APITemplate", "http://nirvana.ooc-lang.org/api%s") \
                .addValue("Nirvana.UsefileTemplate", "http://nirvana.ooc-lang.org%s")
        top := defaults
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
    }

    get: func <T> (path: String, T: Class) -> T {
        entity getOption(path, T)
    }
}
