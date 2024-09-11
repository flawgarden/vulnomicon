#!/usr/bin/env python3

import json
import os
import re

import openpyxl

FLOW_REGEX = r"Flow_(\d+)(\s*|_inplace)\.cs"
CSPROJ_EXT = ".csproj"
CWE_REGEX = r"CWE(\d+)"

CONTENTS_TABLE_PATH = r"./scripts/benchmarks/FlowBlot/contentsTable.xlsx"

VULNERABLE_VALUE = "Vulnerable"
TOTAL_FLOW_NUM = 75


def get_lines_num(path):
    with open(path, "r") as file:
        contents = file.read()
    return contents.count("\n")


def generate_flow_result(flow_path, is_vulnerable, total_lines, cwe):
    result = dict()
    result["kind"] = "fail" if is_vulnerable else "pass"
    result["message"] = {}
    result["message"]["text"] = flow_path
    result["ruleId"] = "CWE-" + cwe
    location = {
        "physicalLocation": {
            "artifactLocation": {"uri": flow_path},
            # marking a whole file, as only one vulnerability is expected
            "region": {"startLine": 1, "endLine": total_lines},
        }
    }
    result["locations"] = []
    result["locations"].append(location)
    return result


def load_flow_vulnerabilities():
    ws = openpyxl.load_workbook(CONTENTS_TABLE_PATH)["Sheet1"]
    flow_vuln = [False for _ in range(TOTAL_FLOW_NUM)]
    for i in range(TOTAL_FLOW_NUM):
        cell = ws["C" + str(i + 2)]
        flow_vuln[i] = cell.value == VULNERABLE_VALUE
    # filling up the flows that are not present in the sheet
    flow_vuln.extend([False, False, True, True, True, True])
    return flow_vuln


FLOW_VULNERABILITY = load_flow_vulnerabilities()


def generate_sarif(sarif_path, test_files, cwe):
    sarif_data_out = {
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",  # noqa: B950
        "version": "2.1.0",
        "runs": [{"tool": {"driver": {"name": "FlowBlot.NET at " + sarif_path}}}],
    }
    results = []
    for flow_path in test_files:
        # removing the first directory as .sarif is already inside it
        relative_path = flow_path[len(sarif_path) + 1 :]
        flow_id = int(re.search(FLOW_REGEX, flow_path).group(1)) - 1
        total_lines = get_lines_num(flow_path)

        flow_result = generate_flow_result(
            relative_path, FLOW_VULNERABILITY[flow_id], total_lines, cwe
        )
        results.append(flow_result)
    sarif_data_out["runs"][0]["results"] = results

    os.makedirs("markup/" + sarif_path, exist_ok=True)

    with open("markup/" + sarif_path + "/truth.sarif", "w") as out_file:
        json.dump(sarif_data_out, out_file, indent=2)


def collect_flows(cur_path):
    flows = []
    for entry in os.scandir(cur_path):
        if entry.is_dir():
            inner_flows = collect_flows(entry.path)
            flows.extend(inner_flows)
        elif entry.is_file() and bool(re.match(FLOW_REGEX, entry.name)):
            flows.append(entry.path)
    return flows


def is_csproj_present(path):
    return any(
        map(lambda x: x.is_file() and x.name.endswith(CSPROJ_EXT), os.scandir(path))
    )


def collect_projects(path):
    projects_and_cwes = []

    # collecting all project directories from root
    dirs = filter(lambda x: x.is_dir() and is_csproj_present(x.path), os.scandir(path))
    paths = list(map(lambda x: x.path, dirs))

    # take those with CWE in the name
    for project in paths:
        match = re.search(CWE_REGEX, project)
        if match is not None:
            projects_and_cwes.append((project, match.group(1)))

    return projects_and_cwes


def main():
    projects = collect_projects("./FlowBlot.NET")

    for project_path, cwe in projects:
        flows = collect_flows(project_path)

        generate_sarif(project_path, flows, cwe)


if __name__ == "__main__":
    main()
