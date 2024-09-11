#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path

from bs4 import BeautifulSoup


def parse_xml(xml_path):
    with open(xml_path) as xmlfile:
        data = xmlfile.read()
        parsed_data = BeautifulSoup(data, "xml")
        test_metadata = parsed_data.find("test-metadata")
        category = test_metadata.find("category").string
        test_number = test_metadata.find("test-number")
        vulnerability = test_metadata.find("vulnerability").string
        cwe = test_metadata.find("cwe").string
        return test_number, vulnerability, cwe, category


def lines_number(file_path):
    command = "wc -l %s" % file_path
    res = int(subprocess.check_output(args=command, shell=True).split()[0])
    return res


def convert(owasp_root_path_str, name, markup_path_str):
    sarif_data_out = {
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",  # noqa: B950
        "version": "2.1.0",
        "runs": [{"tool": {"driver": {"name": name}}}],
    }
    results = []
    owasp_root_path = Path(owasp_root_path_str)
    xml_parent_path = owasp_root_path / "src/main/java/org/owasp/benchmark/testcode"
    xml_parent_path_str = xml_parent_path.absolute().as_posix()
    files = [f for f in os.listdir(xml_parent_path_str) if f.endswith(".xml")]
    for f in files:
        f_path = xml_parent_path / f
        f_path = f_path.absolute().resolve()
        f_path_str = f_path.as_posix()
        f_name = f_path.stem
        java_name = f_name + ".java"
        java_file_path = xml_parent_path / java_name
        _, vulnerability, cwe, category = parse_xml(f_path_str)
        result = {}
        if vulnerability == "true":
            result["kind"] = "fail"
        else:
            result["kind"] = "pass"
        result["message"] = {}
        result["message"]["text"] = str(category)
        result["ruleId"] = "CWE-" + str(cwe)
        location = {
            "physicalLocation": {
                "artifactLocation": {
                    "uri": java_file_path.relative_to(owasp_root_path_str).as_posix()
                },
            }
        }
        result["locations"] = []
        result["locations"].append(location)
        results.append(result)
    sarif_data_out["runs"][0]["results"] = results
    out_file = open(markup_path_str + "/truth.sarif", "w")
    json.dump(sarif_data_out, out_file, indent=2)


def main():
    benchmark_path = Path(sys.argv[1]).absolute().resolve().as_posix()
    markup_path = Path("markup/" + sys.argv[1]).absolute().resolve().as_posix()
    benchmark_name = sys.argv[2]
    convert(benchmark_path, benchmark_name, markup_path)


if __name__ == "__main__":
    main()
