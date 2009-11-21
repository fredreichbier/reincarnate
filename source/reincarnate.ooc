import reincarnate/Nirvana

main: func {
    nirvana := Nirvana new("http://nirvana.ooc-lang.org/api%s")
    for(category: String in nirvana getCategories()) {
        category println()
    }
}
