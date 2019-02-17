import Foundation

class FileUtils {
    static func fileExistsAtPath(path: String) -> (fileExist: Bool, isDirectory: Bool) {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                return (true, true)
            } else {
                // file exists and is not a directory
                return (true, false)
            }
        } else {
            // file does not exist
            return (false, false)
        }
    }

    static func getAllFilesRecursivelyInDirectory(pathToDirectory: String) -> [String] {
        var result: [String] = []
        let fileManager = FileManager.default
        do {
            let filesAtPath = try fileManager.contentsOfDirectory(atPath: pathToDirectory)
            for file in filesAtPath {
                if let builtFilePath = buildURLByAppending(path: pathToDirectory, name: file) {
                    let fileExistsAtPathResult = fileExistsAtPath(path: builtFilePath)
                    if fileExistsAtPathResult.fileExist, fileExistsAtPathResult.isDirectory {
                        result = result + getAllFilesRecursivelyInDirectory(pathToDirectory: builtFilePath)
                    } else if fileExistsAtPathResult.fileExist {
                        result.append(builtFilePath)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return result
    }

    static func fileNameAndExtensionForfile(path: String) -> (fileName: String, fileExtension: String) {
        let url = NSURL(fileURLWithPath: path)
        let fileExtension = url.pathExtension ?? ""
        let fileName = url.deletingPathExtension?.lastPathComponent ?? ""

        return (fileName, fileExtension)
    }

    static func buildURLWithNewExtension(path: String, extensionString: String) -> URL? {
        let url = NSURL(fileURLWithPath: path)
        return url.deletingPathExtension?.appendingPathExtension(extensionString)
    }

    static func buildURLByAppending(path: String, name: String) -> String? {
        let url = NSURL(fileURLWithPath: path)
        return url.appendingPathComponent(name)?.relativeString
    }
}
