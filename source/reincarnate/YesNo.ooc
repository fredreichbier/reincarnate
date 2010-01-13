getchar: extern func -> Char

YesNo: class {
    ask: static func (question: String, def: Bool) -> Bool {
        y := def ? 'Y' : 'n'
        n := (!def) ? 'N' : 'n'
        line := "%s [%c/%c]: " format(question, y, n)
        while(true) {
            line println()
            /* TODO: get without the need to hit RETURN */
            answer := getchar()
            if(answer == 'y' || answer == 'n') {
                return answer == 'y'
            } else if(answer == 0) {
                return def
            } else {
                "Please type either y or n." println()
            }
        }
    }
}
