use curl
use uriparser

import text/StringBuffer
import io/FileWriter

import curl/Curl
import uriparser/UriParser

import reincarnate/App

NetError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}

Net: cover {
    downloadString: static func (url: String) -> String {
        buffer := StringBuffer new()
        handle := Curl new()
        handle setOpt(CurlOpt url, url)
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

    resolveLocation: static func (location: String) -> String {
        /* TODO: implement $SERVER */
        return location
    }

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

    _parseUri: static func (url: String) -> Uri {
        state := ParserState new()
        uri := Uri new()
        state@ uri = uri
        errorCode := state parse(url)
        if(!errorCode success()) {
            NetError new(This, "Error parsing URI '%s': %d" format(url, errorCode)) throw()
        }
        return uri    
    }

    _getBaseName: static func (url: String) -> String {
        uri := _parseUri(url)
        if(uri@ pathTail) {
           return uri@ pathTail@ text copy()
        } else {
            return uri@ hostText copy()
        }
    }

    getScheme: static func (url: String) -> String {
        uri := _parseUri(url)
        return uri@ scheme copy()
    }

    downloadPackage: static func (url: String) -> String {
        destination := app fileSystem getPackageFilename(_getBaseName(url))
        downloadFile(url, destination)
        return destination
    }
}
