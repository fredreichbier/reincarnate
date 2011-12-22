import reincarnate/Version

compare: func (a, b: String) {
    result := a  compareVersions(b )
    sign := match result {
        case -1 => "<"
        case 0 => "="
        case 1 => ">"
    }
    "%s %s %s" format(a, sign, b) println()
}
main: func {
    compare("0.1", "0.2")
    compare("0.1a", "0.1")
    compare("7000", "0.8000")
    compare(".1a", ".2a")
    compare("0.4alpha", "0.4beta")
    compare("0.4dev", "0.4")
}
