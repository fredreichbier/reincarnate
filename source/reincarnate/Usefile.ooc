import structs/HashMap
import io/Reader
import text/[StringTokenizer,StringBuffer]

ParseError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}

Usefile: class extends HashMap<String> {
    init: func ~fromString (str: String) {
        T = String /* TODO: ugly :( */
        super()
        readUsefile(str)
    }

    init: func ~fromReader (reader: Reader) {
        T = String /* TODO: ugly :( */
        super()
        readUsefile(reader)
    }

    _splitLine: func (line: String, key, value: String*) {
        idx := line indexOf(':')
        if(idx == -1) {
            ParseError new(This, "Invalid line: '%s'" format(line)) throw()
        }
        key@ = line substring(0, idx) trim()
        value@ = line substring(idx + 1, line length()) trim() trim('\n') trim('\r') /* TODO: Mr Memory is sad. */
    }

    readUsefile: func ~fromString (str: String) {
        key, value: String
        str println()
        for(line: String in str split('\n')) {
            if(line length() > 0 && !line startsWith("#")) { /* ignore empty lines and comments */
                _splitLine(line, key&, value&)
                this put(key, value)
            }
        }
    }

    /* TODO: implement that nicer */
    readUsefile: func ~fromReader (reader: Reader) {
        BUFFER_SIZE := const 10
        tinyBuffer := String new(BUFFER_SIZE)
        buffer := StringBuffer new()
        while(true) {
            bytesRead := reader read(tinyBuffer, 0, BUFFER_SIZE)
            buffer append(tinyBuffer, bytesRead)
            if(bytesRead < BUFFER_SIZE) {
                break
            }
        }
        readUsefile(buffer toString())
    }
}
