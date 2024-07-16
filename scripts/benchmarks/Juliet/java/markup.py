#!/usr/bin/env python3

import json
import os
import re

from enum import IntEnum

GOOD_TEST_REGEX = "(g|helperG)ood(\d+|G2B\d*|B2G\d*)?(Source|Sink)?"
BAD_TEST_REGEX = "(b|helperB)ad(Source|Sink)?"


def matchWithRegex(regex, string):
    return bool(re.match(regex, string))


def isPartBegin(part_regex, string):
    # checking within method and class names
    return matchWithRegex(".*(public|private).*\s" + part_regex + "\(.*", string) \
        or matchWithRegex(".*class.*_" + part_regex + ".*", string)


def isGoodPartBegin(string):
    return isPartBegin(GOOD_TEST_REGEX, string)


def isBadPartBegin(string):
    return isPartBegin(BAD_TEST_REGEX, string)


class State(IntEnum):
    Waiting = 1
    InScope = 3


class Event(IntEnum):
    Empty = 0
    GoodPartBegan = 1 << 1
    BadPartBegan = 1 << 2
    ScopeBegan = 1 << 3
    ScopeEnded = 1 << 4


def determineEvent(line):
    openBrackets = line.count("{")
    closeBracekts = line.count("}")
    bracketNum = openBrackets + closeBracekts
    if bracketNum > 1 and openBrackets != closeBracekts:
        print("Too many unmatched brackets met in a single line!!!")
        print("   " + line + " !!!")
        exit(10)

    event = Event.Empty

    if isGoodPartBegin(line):
        event = event | Event.GoodPartBegan
    if isBadPartBegin(line):
        event = event | Event.BadPartBegan
    if openBrackets == 1:
        event = event | Event.ScopeBegan
    if closeBracekts == 1:
        event = event | Event.ScopeEnded

    return event


def isEventPresent(event, eventMask):
    return bool(int(event) & int(eventMask))


eventCheckOrder = [
    Event.GoodPartBegan,
    Event.BadPartBegan,
    Event.ScopeBegan,
    Event.ScopeEnded,
]


class PartsCollectorAutomaton:

    def __init__(self, name):
        self.begin = None
        self.isGood = None
        self.lineId = 0
        self.scopeBalance = None
        self.bads = []
        self.goods = []
        self.state = State.Waiting
        self.name = name


    def saveCurrentPart(self):
        newPart = (self.begin, self.lineId)
        if self.isGood:
            self.goods.append(newPart)
        else:
            self.bads.append(newPart)


    def parseNextLine(self, line):
        self.lineId = self.lineId + 1
        event = determineEvent(line)

        for e in eventCheckOrder:
            if isEventPresent(event, e):
                PartsCollectorAutomaton.transitionTable[self.state][e](self)


    def doNothing(self):
        pass


    def recordPartBeginning(self, isGood):
        self.begin = self.lineId
        self.isGood = isGood
        self.scopeBalance = 0
        self.state = State.InScope


    def recordScopeEnter(self):
        self.scopeBalance = self.scopeBalance + 1


    def recordScopeExit(self):
        self.scopeBalance = self.scopeBalance - 1
        if self.scopeBalance < 0:
            self.printErrorAndExit("scope balance went below zero!", 3)
        if self.scopeBalance == 0:
            self.saveCurrentPart()
            self.begin = None
            self.isGood = None
            self.scopeBalance = None
            self.state = State.Waiting


    def printErrorAndExit(self, message, exitCode):
        print("Error occured in [" + self.name + "] on line " + str(self.lineId))
        print(" !! " + message + "\n")

        exit(exitCode)


    transitionTable = {
        State.Waiting: {
            Event.Empty: doNothing,
            Event.GoodPartBegan:
                lambda s: PartsCollectorAutomaton.recordPartBeginning(s, True),
            Event.BadPartBegan:
                lambda s: PartsCollectorAutomaton.recordPartBeginning(s, False),
            Event.ScopeBegan: doNothing,
            Event.ScopeEnded: doNothing,
        },
        State.InScope: {
            Event.Empty: doNothing,
            Event.GoodPartBegan:
                lambda s: PartsCollectorAutomaton.doNothing if s.isGood
                    else PartsCollectorAutomaton.printErrorAndExit(
                            s, "good part began, but we're already in bad one at " + str(s.begin) + "!", 1),
            Event.BadPartBegan:
                lambda s: PartsCollectorAutomaton.doNothing if not s.isGood
                    else PartsCollectorAutomaton.printErrorAndExit(
                            s, "bad part began, but we're already in good one at " + str(s.begin) + "!", 2),
            Event.ScopeBegan: recordScopeEnter,
            Event.ScopeEnded: recordScopeExit,
        }
    }


def uniteParts(arr):
    if len(arr) == 0:
        return None
    return (min([x[0] for x in arr]), max([x[1] for x in arr]))


def getGoodAndBadParts(testPath):
    collector = PartsCollectorAutomaton(testPath)

    with open(testPath) as file:
        while line := file.readline():
            collector.parseNextLine(line)

    goodSingle = uniteParts(collector.goods)
    badSingle = uniteParts(collector.bads)

    if goodSingle is not None and badSingle is not None:
        if goodSingle[0] <= badSingle[1] and goodSingle[1] >= badSingle[0]:
            print("Good and bad parts overlap for " + testPath + "!\nCould not unite")
            exit(15)

    goodSingle = [] if goodSingle is None else [goodSingle]
    badSingle = [] if badSingle is None else [badSingle]

    return (goodSingle, badSingle)


def generateCWEResult(startLine, endLine, testName, isVulnerable, cwe):
    result = {}
    result["kind"] = "fail" if isVulnerable else "pass"
    result["message"] = {}
    result["message"]["text"] = testName
    result["ruleId"] = "CWE-" + str(cwe)
    location = {
        "physicalLocation": {
            "artifactLocation": {
                "uri": testName
            },
            "region": {
                "startLine": startLine,
                "endLine": endLine
            }
        }
    }
    result["locations"] = []
    result["locations"].append(location)
    return result


def generateSarif(julietRootPath, testFilesWithCWE):
    sarif_data_out = {
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
        "version": "2.1.0",
        "runs": [{"tool": {"driver": {"name": "JulietJava-1.3"}}}],
    }
    results = []
    for testFile, cwe in testFilesWithCWE:
        # removing the first directory as .sarif is already inside it
        testRelativePath = testFile[len("./JulietJava/"):]
        (goods, bads) = getGoodAndBadParts(testFile)
        for good in goods:
            results.append(generateCWEResult(
                good[0], good[1], testRelativePath, False, cwe))
        for bad in bads:
            results.append(generateCWEResult(
                bad[0], bad[1], testRelativePath, True, cwe))
    sarif_data_out["runs"][0]["results"] = results
    out_file = open(julietRootPath + "/truth.sarif", "w")
    json.dump(sarif_data_out, out_file, indent=2)


def collectCWEsInDirectory(curDirectory, cwe=None):
    testFilesWithCWE = []
    if cwe is None and curDirectory.name[0:3] == "CWE":
        # entered a directory containing CWE test entries; retrieving its number for sarif
        cwe = re.findall(r"\d+", curDirectory.name)[0]
    with os.scandir(curDirectory.path) as iter:
        for fileEntry in iter:
            filePath = fileEntry.path
            if fileEntry.is_dir():
                innerCWEs = collectCWEsInDirectory(fileEntry, cwe)
                testFilesWithCWE.extend(innerCWEs)
            elif fileEntry.is_file():
                _, extension = os.path.splitext(filePath)
                if extension == ".java" and fileEntry.name[0:3] == "CWE":
                    if cwe is None:
                        print(
                            ".java file found [" + fileEntry.name + "] before the CWE was set!")
                        exit(1)
                    testFilesWithCWE.append((fileEntry.path, cwe))
    return testFilesWithCWE


def main():
    julietDirectory = None
    with os.scandir(".") as iter:
        for entry in iter:
            if entry.is_dir() and entry.name == "JulietJava":
                julietDirectory = entry

    CWEFiles = collectCWEsInDirectory(julietDirectory)
    generateSarif(julietDirectory.path, CWEFiles)


if __name__ == "__main__":
    main()
