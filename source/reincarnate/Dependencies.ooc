import structs/ArrayList
import text/[StringBuffer, StringTokenizer]

import deadlogger/Log

import reincarnate/[App, Package, Version]

logger := Log getLogger("reincarnate.Dependencies")

Requirement: class {
    slug, op: String
    ver: Version

    init: func ~all (=slug, =op, =ver) {}
    init: func ~noOp (=slug) {
        op = null
        ver = null
    }

    /** does `pVer` meet the requirement? */
    meets: func (pVer: Version) -> Bool {
        if(op == null)
            /* no version given, so any version matches. */
            return true
        cmp := ver compareVersions(pVer)
        return match op {
            case "=" => cmp == 0
            case "<" => cmp == 1
            case ">" => cmp == -1
            case "<=" => cmp == 1 || cmp == 0
            case ">=" => cmp == -1 || cmp == 0
            case => false /* TODO: what to do for unknown operators? */
        }
    }

    toString: func -> String {
        if(op != null)
            return "%s%s%s" format(slug, op, ver)
        else
            return slug
    }

    fromString: func (s: String) {
        if(s contains('=') || s contains('>') || s contains('<')) {
            /* contains a version. */
            SLUG := 1
            OP := 2
            VER := 3
            buffer := StringBuffer new()
            state := SLUG
            for(i: SizeT in 0..s length()) {
                chr := s[i]
                match state {
                    case SLUG => {
                        if(chr == '=' || chr == '<' || chr == '>') {
                            /* OP follows. */
                            this slug = buffer toString() trim()
                            buffer = StringBuffer new()
                            buffer append(chr)
                            state = OP
                        } else {
                            /* still slug. */
                            buffer append(chr)
                        }
                    }
                    case OP => {
                        if(chr != '=' || chr != '<' || chr != '>') {
                            /* VER follows. */
                            this op = buffer toString() trim()
                            buffer = StringBuffer new()
                            buffer append(chr)
                            state = VER
                        } else {
                            /* op. */
                            buffer append(chr)
                        }
                    }
                }
            }
            if(state != VER) {
                Exception new(This, "Malformed requirement string: %s" format(s)) throw()
            }
            this ver = buffer toString() trim()
        } else {
            /* contains no version. */
            this slug = s trim()
        }
    }
}

Requirements: class extends ArrayList<Requirement> {
    app: App

    init: func ~withApp (=app) {
        T = Requirement
    }

    /** get a list of all locations that should be installed in order to meet the
      * requirements described by `this`. If the requirements can't be met,
      * throw an Exception.
      */
    getDependencyLocations: func -> ArrayList<String> {
        locations := ArrayList<String> new()
        for(requirement: Requirement in this) {
            ver := null as Version
            if(requirement op != null) {
                /* only if there is a comparison requirement given ... */
                ver = app yard findVersion(requirement)
                if(ver == null) {
                    /* impossible :( */
                    Exception new(This, "Requirement can't be met: %s" format(requirement toString()))
                }
            }
            loc := null as String
            if(ver != null)
                loc = "%s=%s" format(requirement slug, ver)
            else
                loc = requirement slug
            add := true
            for(lloc: String in locations) {
                if(lloc equals(loc)) {
                    add = false
                    break
                }
            }
            if(add)
                locations add(loc)
        }
        return locations
    }

    /* parse a string in the format "{req} {req} {req}" where {req} is always "{slug}{op}{ver}" or "{slug}". */
    parseString: func (s: String) {
        for(req: String in s split(' ')) {
            requirement := Requirement new(null)
            requirement fromString(req)
            this add(requirement)
        }
    }
}
