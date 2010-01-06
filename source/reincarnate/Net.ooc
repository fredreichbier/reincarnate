use curl
use uriparser
 
import io/FileWriter
import structs/HashMap
import text/StringBuffer
 
import curl/Curl
import uriparser/UriParser

import reincarnate/App
 
NetError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}
 
Net: class {
    _packPost: static func (curl: Curl, data: HashMap<String>) -> HTTPPost {
        post: HTTPPost = null
        last: HTTPPost = null
        for(key: String in data keys) {
            if(key startsWith('@'))
                formAdd(post&, last&, CurlForm copyName, key substring(1), CurlForm file, data[key], CurlForm end)
            else
                formAdd(post&, last&, CurlForm copyName, key, CurlForm copyContents, data[key], CurlForm end)
        }
        post
    }

    downloadString: static func (url: String, post: HashMap<String>) -> String {
        buffer := StringBuffer new()
        handle := Curl new()
        handle setOpt(CurlOpt url, url)
        if(post != null) {
            form := _packPost(handle, post)
            handle setOpt(CurlOpt httpPost, form)
        }
        handle setOpt(CurlOpt writeData, buffer)
        handle setOpt(CurlOpt writeFunction,
            func (data: Pointer, size: SizeT, nmemb: SizeT, buffer: Pointer) -> SizeT {
                buffer as StringBuffer append(data, size * nmemb)
                return size * nmemb
            })
        ret := handle perform()
        if(ret != 0) {
            NetError new(This, "CURL error: %d" format(ret)) throw()
        }
        return buffer toString()
    }
    downloadString: static func ~noPost (url: String) -> String { downloadString(url, null) }
 
    downloadFile: static func (url, destination: String) {
        fw := FileWriter new(destination)
     
        handle := Curl new()
        handle setOpt(CurlOpt url, url)
        handle setOpt(CurlOpt writeData, fw)
        handle setOpt(CurlOpt writeFunction, func (buffer: Pointer, size: SizeT, nmemb: SizeT, fw: FileWriter) {
            fw write(buffer as String, nmemb)
        })
     
        ret := handle perform()
        if(ret != 0) {
            NetError new(This, "CURL error: %d" format(ret)) throw()
        }
        fw close()
    }
 
    getBaseName: static func (url: String) -> String {
        state := ParserState new()
        uri := Uri new()
        state@ uri = uri
        errorCode := state parse(url)
        if(!errorCode success()) {
            NetError new(This, "Error parsing URI '%s': %d" format(url, errorCode)) throw()
        }
        if(uri@ pathTail) {
           return uri@ pathTail@ text copy()
        } else {
            return uri@ hostText copy()
        }
    }

    getScheme: static func (url: String) -> String {
        state := ParserState new()
        uri := Uri new()
        state@ uri = uri
        errorCode := state parse(url)
        if(!errorCode success()) {
            NetError new(This, "Error parsing URI '%s': %d" format(url, errorCode)) throw()
        }
        return uri@ scheme copy()
    }

    app: App

    init: func (=app) {
    
    }
}
