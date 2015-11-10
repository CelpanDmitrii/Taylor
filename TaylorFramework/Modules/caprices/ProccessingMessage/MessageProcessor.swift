//
//  MessageProcessor.swift
//  Caprices
//
//  Created by Dmitrii Celpan on 8/26/15.
//  Copyright © 2015 yopeso.dmitriicelpan. All rights reserved.
//

import Cocoa

let DefaultExtensionType = "swift"
let DefaultExcludesFile = "/excludes.yml"

let HelpOptionKey = "help"
private let HelpOptionValueKey = "help requested"

let errorPrinter = Printer(verbosityLevel: .Error)

/* 
If you change this class don't forget to fix his mock for actual right tests (if is case)
*/
class MessageProcessor {
    
    let HelpFileName = "Help"
    let HelpFileExtension = "txt"
    let optionsProcessor = OptionsProcessor()
    
    func processArguments(arguments:[String]) -> Options {
        guard arguments.count > 1 else { return defaultResultDictionary() }
        
        return processMultipleArguments(arguments)
    }
    
    
    func defaultResultDictionary() -> Options {
        var defaultDictionary = defaultDictionaryWithPathAndType()
        setDefaultExcludesIfExistsToDictionary(&defaultDictionary)
        
        return defaultDictionary
    }
    
    
    func processMultipleArguments(arguments:[String]) -> Options {
        if arguments.count.isOdd {
            return optionsProcessor.processOptions(arguments)
        } else if arguments.count.isEven && arguments.second == HelpOptionKey {
            return helpRequestedResultDictionary()
        }
        errorPrinter.printError("\nInvalid options was indicated")
        
        return Options()
    }
    
    
    private func helpRequestedResultDictionary() -> Options {
        do {
            try printHelp()
        } catch {
            errorPrinter.printError("\nCan't find help file")
            return Options()
        }
        return [HelpOptionKey : [HelpOptionValueKey]]
    }
    
    
    func printHelp() throws {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let helpFile = bundle.pathForResource(HelpFileName, ofType: HelpFileExtension) else {
            throw CommandLineError.CannotReadFromHelpFile
        }
        do {
            let helpMessage = try String(contentsOfFile: helpFile)
            let printer = Printer(verbosityLevel: .Info)
            printer.printInfo(helpMessage)
        } catch {
            throw CommandLineError.CannotReadFromHelpFile
        }
    }
    
    
    func getReporters() -> [OutputReporter] {
        return optionsProcessor.factory.reporterTypes
    }
    
    
    func getRuleThresholds() -> CustomizationRule {
        return optionsProcessor.factory.customizationRules
    }
    
    
    func getVerbosityLevel() -> VerbosityLevel {
        return optionsProcessor.factory.verbosityLevel
    }
    

    func setDefaultExcludesIfExistsToDictionary(inout dictionary: Options) {
        do {
            let defaultExcludesFilePath = defaultExcludesFilePathForDictionary(dictionary)
            let excludePaths = try ExcludesFileReader().absolutePathsFromExcludesFile(defaultExcludesFilePath,
                                    forAnalyzePath: dictionary[ResultDictionaryPathKey]![0])
            if !excludePaths.isEmpty {
                dictionary[ResultDictionaryExcludesKey] = excludePaths
            }
        } catch {
            return
        }
    }
    

    func defaultExcludesFilePathForDictionary(dictionary: Options) -> String {
        guard let resultPathKey = dictionary[ResultDictionaryPathKey] where !resultPathKey.isEmpty else {
            return ""
        }
        return dictionary[ResultDictionaryPathKey]!.first! + DefaultExcludesFile
    }
    
    
    func defaultDictionaryWithPathAndType() -> Options {
        return [ResultDictionaryPathKey : [NSFileManager.defaultManager().currentDirectoryPath],
                ResultDictionaryTypeKey : [DefaultExtensionType]]
    }
    
}
