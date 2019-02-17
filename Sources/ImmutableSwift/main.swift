#!/usr/bin/swift

import Foundation
import Utility

let supportedFileExtensions: [String] = ["value"]
let swiftFileExtension = "swift"

func generate(source: String) -> String? {
    let scanner = Scanner(fromSource: source)
    let tokenizer = Tokenizer(withScanner: scanner)

    if let dataModel = Parser().parse(tokenizer) {
        return Generator.Generate(dataModel)
    }

    return nil
}

func processFile(path: String) {
    do {
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        if let output = generate(source: contents) {
            if let outputFileURL = FileUtils.buildURLWithNewExtension(path: path, extensionString: swiftFileExtension) {
                do {
                    try output.write(to: outputFileURL, atomically: false, encoding: .utf8)
                    print("generated:", path)
                } catch {
                    print("failed to generate for:", path)
                    print(error.localizedDescription)
                }
            }
        }
    } catch {
        print("failed to generate for:", path)
        print(error.localizedDescription)
    }
}

let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
let d: ArrayParsingStrategy = ArrayParsingStrategy.upToNextOption

let parser = ArgumentParser(usage: "pathToFilesOrDirectory", overview: "Generate Immutable DataModel in Swift")
let pathToFilesOrDirectory: PositionalArgument<[String]> = parser.add(positional: "pathToFilesOrDirectory", kind: [String].self, optional: false, strategy: ArrayParsingStrategy.remaining, usage: "input files, or directory of input files", completion: nil)

do {
    let parsedArguments = try parser.parse(arguments)
    let filesOrDirectory: [String] = parsedArguments.get(pathToFilesOrDirectory)!
    if filesOrDirectory.count == 1 {
        // single arg, could be directory or file
        let fileExistsAtPathResult = FileUtils.fileExistsAtPath(path: filesOrDirectory.first!)
        if fileExistsAtPathResult.fileExist, fileExistsAtPathResult.isDirectory {
            let filesToGenerate = FileUtils.getAllFilesRecursivelyInDirectory(pathToDirectory: filesOrDirectory.first!).filter { supportedFileExtensions.contains(FileUtils.fileNameAndExtensionForfile(path: $0).fileExtension) }
            for fileToGenerate in filesToGenerate {
                processFile(path: fileToGenerate)
            }
        } else if fileExistsAtPathResult.fileExist {
            processFile(path: filesOrDirectory.first!)
        }
    } else {
        // multiple args, only process files
        for filePath in filesOrDirectory {
            let fileExistsAtPathResult = FileUtils.fileExistsAtPath(path: filePath)
            if fileExistsAtPathResult.fileExist,
                !fileExistsAtPathResult.isDirectory,
                supportedFileExtensions.contains(FileUtils.fileNameAndExtensionForfile(path: filePath).fileExtension) {
                processFile(path: filePath)
            }
        }
    }
} catch let error as ArgumentParserError {
    print(error.description)
} catch {
    print(error.localizedDescription)
}
