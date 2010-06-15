use yajl
import yajl/Yajl

use curl
import curl/Highlevel

import structs/[ArrayList, HashMap]
 
import reincarnate/[App, Checksums, Net, Usefile, Variant, Version]
 
APIException: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}
 
Nirvana: class {
    app: App
    usefileTemplate, apiTemplate, user, apiToken: String
 
    init: func (=app, =apiTemplate, =usefileTemplate) {}
    init: func ~fromConfig (=app) {
        apiTemplate = app config get("Nirvana.APITemplate", String) as String
        usefileTemplate = app config get("Nirvana.UsefileTemplate", String) as String
        user = app config get("Nirvana.User", String) as String
        apiToken = app config get("Nirvana.Token", String) as String
    }
 
    _getUrl: func (path: String) -> String {
        apiTemplate format(path)
    }
 
    _downloadUrl: func (path: String, post: HashMap<String, String>) -> String {
        request := HTTPRequest new(_getUrl(path))
        if(post) {
            request setFormData(FormData new(post))
        }
        Net _performRequest(request)
        return request getString()
    }

    _downloadUrl: func ~noPost (path: String) -> String { _downloadUrl(path, null) }
 
    _interpreteUrl: func (path: String, post: HashMap<String, String>) -> ValueMap {
        content := _downloadUrl(path, post)
        parser := SimpleParser new()
        parser parseAll(content)
        value := parser getValue(ValueMap) as ValueMap /* TODO: what if we don't get a ValueMap? */
        // did we get an error?
        s := value get("__result", String)
        if(s equals("error")) {
            APIException new(This, "Error when reading `%s`: %s" format(path, value get("__text", String))) throw()
        }
        value remove("__result")
        value
    }
    _interpreteUrl: func ~noPost (path: String) -> ValueMap { _interpreteUrl(path, null) }
 
    getCategories: func -> ArrayList<String> {
        map := _interpreteUrl("/categories/")
        return map keys
    }
 
    getPackages: func (category: String) -> ArrayList<String> {
        map := _interpreteUrl("/category/%s/" format(category))
        return map keys
    }
 
    getVersions: func (package: String) -> ArrayList<Version> {
        map := _interpreteUrl("/packages/%s/" format(package))
        return map keys as ArrayList<Version>
    }

    getVariants: func (package, ver: String) -> ArrayList<Variant> {
        map := _interpreteUrl("/packages/%s/%s/" format(package, ver))
        return map keys as ArrayList<Variant>
    }
 
    getUsefilePath: func (package, ver, variant: String) -> String {
        map := _interpreteUrl("/packages/%s/%s/%s/" format(package, ver, variant))
        return map get("usefile", String)
    }

    getChecksumsPath: func (package, ver, variant: String) -> String {
        map := _interpreteUrl("/packages/%s/%s/%s/" format(package, ver, variant))
        return map get("checksums", String)
    }

    getChecksumsURL: func (package, ver, variant: String) -> String {
        usefileTemplate format(getChecksumsPath(package, ver, variant))
    }

    getChecksumsSignaturePath: func (package, ver, variant: String) -> String {
        map := _interpreteUrl("/packages/%s/%s/%s/" format(package, ver, variant))
        return map get("checksums_signature", String)
    }

    getChecksumsSignatureURL: func (package, ver, variant: String) -> String {
        usefileTemplate format(getChecksumsSignaturePath(package, ver, variant))
    }

    getUsefile: func (package, ver, variant: String) -> String {
        return Net downloadString(usefileTemplate format(getUsefilePath(package, ver, variant)))
    }
 
    getLatestUsefile: func (package, variant: String) -> String {
        getUsefile(package, "latest", variant)
    }

    getDefaultUsefile: func (package: String) -> String {
        getLatestUsefile(package, app config get("Nirvana.DefaultVariant", String))
    }

    submitUsefile: func (user, apiToken, slug, ver, variantName: String, usefile: Usefile, checksums: Checksums) -> String {
        post := HashMap<String, String> new()
        post put("usefile", usefile dump()) \
            .put("user", user) \
            .put("token", apiToken) \
            .put("name", variantName) \
            .put("slug", slug) \
            .put("version", ver)
        if(checksums != null)
            post put("checksums", checksums dump())
        map := _interpreteUrl("/submit/", post)
        /* errors were checked. */
        return _getUrl(map get("path", String))
    }

    submitUsefile: func ~fromConfig (slug, variantName: String, usefile: Usefile, checksums: Checksums) -> String {
        if(user == "" || apiToken == "")
            APIException new(This, "No username and/or api key given in the config.") throw()
        return submitUsefile(user, apiToken, slug, usefile get("Version"), variantName, usefile, checksums)
    }
}
 
