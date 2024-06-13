#!/usr/bin/env python3

import json
import os
import re

BAD_PART_BEGIN = "#if +\\(!OMITBAD\\)"
PART_END = "#endif"
GOOD_PART_BEGIN = "#if +\\(!OMITGOOD\\)"


def matchWithRegex(regex, string):
    return bool(re.match(regex, string))


def getGoodAndBadParts(testPath):
    bads = []
    goods = []
    begin = None
    with open(testPath) as file:
        i = 0
        isGood = None
        while line := file.readline():
            i += 1

            if not line:
                continue

            if matchWithRegex(BAD_PART_BEGIN, line):
                begin = i
                isGood = False
            elif matchWithRegex(GOOD_PART_BEGIN, line):
                begin = i
                isGood = True
            elif matchWithRegex(PART_END, line):
                newPart = (begin, i)
                if isGood:
                    goods.append(newPart)
                else:
                    bads.append(newPart)
                begin = None
                isGood = None

    return (goods, bads)


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
        "runs": [{"tool": {"driver": {"name": "JulietCSharp-1.3"}}}],
    }
    results = []
    for testFile, cwe in testFilesWithCWE:
        # removing the first directory as .sarif is already inside it
        testRelativePath = testFile.path[len("./JulietCSharp/"):]
        (goods, bads) = getGoodAndBadParts(testFile.path)
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
                if extension == ".cs" and fileEntry.name[0:3] == "CWE":
                    if cwe is None:
                        print(
                            ".cs file found [" + fileEntry.name + "] before the CWE was set!")
                        exit(1)
                    testFilesWithCWE.append((fileEntry, cwe))
    return testFilesWithCWE


def main():
    julietDirectory = None
    with os.scandir(".") as iter:
        for entry in iter:
            if entry.is_dir() and entry.name == "JulietCSharp":
                julietDirectory = entry

    CWEFiles = collectCWEsInDirectory(julietDirectory)
    generateSarif(julietDirectory.path, CWEFiles)


if __name__ == "__main__":
    main()
