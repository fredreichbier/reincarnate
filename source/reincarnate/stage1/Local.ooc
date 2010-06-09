import io/[File, FileReader]
import structs/ArrayList

import reincarnate/[FileSystem, Usefile, Version]
import reincarnate/stage1/Stage1

LocalS1: class extends Stage1 {
    init: super func

    getUsefile: func (location, ver, variant: String) -> Usefile {
        reader := FileReader new(location)
        /* TODO: version check */
        usefile := Usefile new(reader)
        /* get the slug. TODO: please check */
        slug := File new(location) name()
        app fileSystem splitExt(slug, slug&, null)
        usefile put("_Slug", slug)
        reader close()
        return usefile
    }
}
