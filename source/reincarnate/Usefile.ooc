import structs/HashMap
import io/Reader
import text/[StringTokenizer]
 
UsefileParseError: class extends Exception {
    init: super func
}
 
Usefile: class extends HashMap<String, String> {
    init: func () {
        this K = String /* TODO: ugly :( */
        this V = String
        super()
    }

    init: func ~fromString (str: String) {
        init()
        readUsefile(str)
    }
 
    init: func ~fromReader (reader: Reader) {
        init()
        readUsefile(reader)
    }
 
    _splitLine: func (line: String, key, value: String*) {
        idx := line indexOf(':')
        if(idx == -1) {
            UsefileParseError new(This, "Invalid line: '%s'" format(line)) throw()
        }
        key@ = line substring(0, idx) trim()
        value@ = line substring(idx + 1, line length()) trim('\n') trim('\r') trim() /* TODO: Mr Memory is sad. */
    }
 
    readUsefile: func ~fromString (str: String) {
        key, value: String
        for(line: String in str split('\n')) {
            if(line length() > 0 && !line startsWith?("#")) { /* ignore empty lines and comments */
                _splitLine(line, key&, value&)
                this[key] = value
            }
        }
    }
 
    /* TODO: implement that nicer */
    readUsefile: func ~fromReader (reader: Reader) {
        BUFFER_SIZE := const 10
        tinyBuffer := Buffer new(BUFFER_SIZE)
        buffer := Buffer new()
        while(true) {
            bytesRead := reader read(tinyBuffer)
            if(bytesRead < BUFFER_SIZE) {
                break
            }
        }
        readUsefile(buffer toString())
    }

    dump: func -> String {
        buffer := Buffer new()
        for(key: String in this getKeys()) {
            buffer append("%s: %s\n" format(key, this[key] as String)) /* TODO: I wanna use the [] operator without the cast. :( */
        }
        buffer toString()
    }
}
 
