#!/usr/bin/env python3
import argparse
import glob
import json
import os
from dataclasses import dataclass
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "filepath", type=str, help="path to skf-labs benchmark python directory"
    )
    parser.add_argument(
        "-s",
        "--sparse",
        dest="is_sparse",
        action="store_true",
        help="make individual markup for every benchmark project",
    )
    parser.add_argument(
        "--show-sarif",
        dest="is_show",
        action="store_true",
        help="print all truth.sarif file paths and exit",
    )
    return parser.parse_args()


@dataclass
class RuleInfo:
    title: str
    cwe: list[str]


def load_cwe_mappings() -> dict:
    mappings_path = (
        Path(__file__).resolve().parents[0]
        / "metadata"
        / "bentoo"
        / "taxonomies"
        / "sonarqube_rule_mapping.json"
    )
    with open(mappings_path.absolute().resolve(), "r") as mappings_f:
        mappings = json.load(mappings_f)
    return mappings["rule_mapping"]


def get_rule_info(mappings: dict, sq_id: str) -> RuleInfo | None:
    if sq_id.find("xss") != -1:
        return RuleInfo("", ["CWE-79"])
    if sq_id == "S5998":
        return RuleInfo("", ["CWE-400", "CWE-1333"])

    match mappings.get(sq_id):
        case None:
            return None
        case rule_info:
            title, cwe = rule_info["title"], rule_info["cwe"]
            return RuleInfo(title, list(map(lambda cwe_id: f"CWE-{cwe_id}", cwe)))


def empty_sarif(name):
    return {
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",  # noqa: B950
        "version": "2.1.0",
        "runs": [{"tool": {"driver": {"name": name}}, "results": []}],
    }


def mk_result(kind: str, title: str, cwes: list[str], path: str, line: int) -> dict:
    cwes_str = ",".join(cwes)
    return {
        "kind": kind,
        "message": {"text": title},
        "ruleId": cwes_str,
        "locations": [
            {
                "physicalLocation": {
                    "artifactLocation": {"uri": path},
                    "region": {"startLine": line},
                }
            }
        ],
    }


def parse_truth_file(
    path: Path, mappings: dict, kind: str, region_keyword: str
) -> list[dict]:
    with open(path.absolute().resolve(), "r") as truth_f:
        truth = json.load(truth_f)

    results = []
    for sq_id, regions in truth[region_keyword].items():
        prefix, sq_id = sq_id.split(":")

        if not prefix.startswith("python"):
            continue

        rule_info = get_rule_info(mappings, sq_id)
        if rule_info is None:
            print(f"{path} {sq_id}: not presented")
            continue
        if len(rule_info.cwe) == 0:
            print(f"{sq_id}: empty mapping")
            continue
        for region in regions:
            file_name = region["fileId"].split(":")[1]
            for line in region["lines"]:
                results.append(
                    mk_result(kind, rule_info.title, rule_info.cwe, file_name, line)
                )

    return results


@dataclass
class Markup:
    name: str
    results: list[dict]

    def to_pair(self) -> tuple[str, list[dict]]:
        return self.name, self.results


def convert_markup(rule_mappings: dict) -> list[Markup]:
    ground_truth_path = (
        Path(__file__).resolve().parents[0]
        / "metadata"
        / "sonar-benchmarks-scores"
        / "python"
        / "skf-labs-python"
    )
    subbenches_ground_truth_paths = [
        (Path(f.path), f.name) for f in os.scandir(ground_truth_path) if f.is_dir()
    ]
    markups = []
    for path, name in subbenches_ground_truth_paths:
        ground_truth = path / "ground-truth.json"
        ignored_findings = path / "ignored-findings.json"

        results = []
        if ground_truth.is_file():
            results += parse_truth_file(
                ground_truth, rule_mappings, "fail", "expectedIssues"
            )
        if ignored_findings.is_file():
            results += parse_truth_file(
                ignored_findings, rule_mappings, "pass", "ignoredIssues"
            )

        subbench_name = name.split("skf-labs-python-")[1]
        markups.append(Markup(subbench_name, results))

    return markups


def write_sarif(benchmark_path: Path, results: list[tuple[str, dict]]) -> None:
    os.makedirs(benchmark_path, exist_ok=True)
    truth_sarif = empty_sarif("skf-labs-python")
    updated_results = truth_sarif["runs"][0]["results"]
    for subbench, result in results:
        artifact_location = result["locations"][0]["physicalLocation"][
            "artifactLocation"
        ]
        correct_uri = f'{subbench}/{artifact_location["uri"]}'
        artifact_location["uri"] = correct_uri
        updated_results.append(result)

    truth_sarif_path = benchmark_path / "truth.sarif"
    with open(truth_sarif_path.absolute().resolve(), "w") as truth_sarif_f:
        json.dump(truth_sarif, truth_sarif_f, indent=2)


def write_sparse_sarif(benchmark_path: Path, markups: list[Markup]) -> None:
    for markup in markups:
        truth_sarif = empty_sarif(f"skf-labs-python-{markup.name}")
        truth_sarif["runs"][0]["results"] = markup.results
        truth_sarif_path = benchmark_path / markup.name / "truth.sarif"
        with open(truth_sarif_path.absolute().resolve(), "w") as truth_sarif_f:
            json.dump(truth_sarif, truth_sarif_f, indent=2)


def print_sarif(benchmark_path: Path) -> None:
    truth_sarif_pattern = (benchmark_path / "**/truth.sarif").absolute().as_posix()
    truth_sarif_files = glob.glob(truth_sarif_pattern, recursive=True)
    for truth_sarif_file in truth_sarif_files:
        print(truth_sarif_file)


def main():
    args = parse_args()
    if args.is_show:
        print_sarif(Path(args.filepath))
        exit(0)

    mappings = load_cwe_mappings()
    markups = convert_markup(mappings)

    if args.is_sparse:
        write_sparse_sarif(Path(args.filepath), markups)
    else:
        merged_results = []
        for markup in markups:
            merged_results.extend([(markup.name, result) for result in markup.results])

        markup_path = "markup" / Path(args.filepath)
        write_sarif(markup_path, merged_results)


if __name__ == "__main__":
    main()
