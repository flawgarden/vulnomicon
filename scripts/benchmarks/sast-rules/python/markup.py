#!/usr/bin/env python3
import os
import sys
from dataclasses import dataclass
from pathlib import Path
import itertools

import yaml
import json


@dataclass
class Cwe:
    cwe: str
    category: str


def parse_yaml(yaml_path) -> Cwe:
    with open(yaml_path, "r") as yamlfile:
        parsed_data = yaml.safe_load(yamlfile)

        rules = parsed_data["rules"]
        assert len(rules) == 1
        rule = rules[0]
        cwe = rule["metadata"]["cwe"]
        category = rule["metadata"]["category"]

        return Cwe(cwe, category)


class Fail:
    pass


class Pass:
    pass


@dataclass
class Rule:
    kind: Pass | Fail
    indentation: int


@dataclass
class SuspiciousLocations:
    path: str
    locations: list[tuple[int, int, Pass | Fail]]


fail_patterns = ["ruleid", "rule id"]
pass_patterns = [
    "correct",
    "also correct",
    "ok",
    "no issue should be found",
    "rule ok",
    "okay",
    "negative test",
]


def parse_rule(line) -> Rule | None:
    subparts = line.split("#")

    if len(subparts) != 2:
        return None

    prefix, rule = subparts[0], subparts[1].strip().lower()

    result = None
    if any([rule.startswith(pattern) for pattern in pass_patterns]):
        result = Pass()
    if any([rule.startswith(pattern) for pattern in fail_patterns]):
        result = Fail()

    if result is None:
        return result

    assert len(prefix) == 0 or prefix.isspace()
    return Rule(result, len(prefix))


def report_suspicious_location(location: SuspiciousLocations) -> None:
    print(f"{location.path}:{len(location.locations)}")
    for start, end, kind in location.locations:
        print((start, end), end="")
        match kind:
            case Pass():
                print(":pass")
            case Fail():
                print(":fail")


def process_rule(
    rule: Rule,
    start_location,
    end_location,
    pass_locations,
    fail_locations,
    on_suspicious,
) -> None:
    if end_location - start_location < 2:
        assert False
    if end_location - start_location > 2:
        on_suspicious()
        return

    match rule.kind:
        case Pass():
            pass_locations.append(start_location + 1)
        case Fail():
            fail_locations.append(start_location + 1)
        case _:
            assert False


def get_indentation(line):
    return sum(1 for _ in itertools.takewhile(str.isspace, line))


def find_locations(path):
    cur_rule = None

    line_number = 1
    pass_locations = []
    fail_locations = []
    susp_locations = []

    def _add_susp_loc(start, end, kind):
        return lambda: susp_locations.append((start, end, kind))

    with open(path, "r") as f:
        for line in f:
            match parse_rule(line), cur_rule:
                case None, None:
                    pass
                case None, (rule, start_location):
                    if (
                        start_location + 1 < line_number
                        and get_indentation(line.rstrip()) <= rule.indentation
                    ):
                        process_rule(
                            rule=rule,
                            start_location=start_location,
                            end_location=line_number,
                            pass_locations=pass_locations,
                            fail_locations=fail_locations,
                            on_suspicious=_add_susp_loc(
                                start_location, line_number - 1, rule.kind
                            ),
                        )
                        cur_rule = None
                case Rule(_) as new_rule, rule:
                    if rule is not None:
                        process_rule(
                            *rule,
                            end_location=line_number,
                            pass_locations=pass_locations,
                            fail_locations=fail_locations,
                            on_suspicious=_add_susp_loc(
                                start_location, line_number - 1, rule[0].kind
                            ),
                        )
                    cur_rule = (new_rule, line_number)

            line_number = line_number + 1

        if cur_rule is not None:
            process_rule(
                *cur_rule,
                end_location=line_number,
                pass_locations=pass_locations,
                fail_locations=fail_locations,
                on_suspicious=_add_susp_loc(
                    start_location, line_number - 1, cur_rule[0].kind
                ),
            )

        susp_locations = (
            SuspiciousLocations(path, susp_locations)
            if len(susp_locations) > 0
            else None
        )
        return fail_locations, pass_locations, susp_locations


def add_result(kind, cwe, path, start, results):
    result = {
        "kind": kind,
        "message": {"text": cwe.category},
        "ruleId": cwe.cwe,
        "locations": [
            {
                "physicalLocation": {
                    "artifactLocation": {"uri": path},
                    "region": {"startLine": start},
                }
            }
        ],
    }

    results.append(result)


def markup(bench_path, results):
    subbenches = [Path(f.path) for f in os.scandir(bench_path) if f.is_dir()]

    for subbench in subbenches:

        bench_files = [
            f.name[:-4]
            for f in os.scandir(subbench)
            if f.is_file() and f.name.endswith(".yml")
        ]

        for bench_name in bench_files:
            bench_rule_str = (
                (subbench / (bench_name + ".yml")).absolute().resolve().as_posix()
            )
            bench_file_path = subbench / (bench_name + ".py")
            bench_file_str = bench_file_path.absolute().resolve().as_posix()

            rule = parse_yaml(bench_rule_str)
            #  TODO: check suspicious locations for new ones not presented in manual markup
            fail_locations, pass_locations, suspicious_locations = find_locations(
                bench_file_str
            )

            relative_bench_file_str = bench_file_path.relative_to(bench_path).as_posix()
            for pass_location in pass_locations:
                add_result(
                    "pass", rule, relative_bench_file_str, pass_location, results
                )
            for fail_location in fail_locations:
                add_result(
                    "fail", rule, relative_bench_file_str, fail_location, results
                )


def main():
    manual_markup_path = Path(__file__).resolve().parents[0] / "manual.sarif"
    sast_rules_path = Path(sys.argv[1])

    with open(manual_markup_path, "r") as manual_markup_f:
        manual_markup = json.load(manual_markup_f)

    markup(sast_rules_path.absolute().as_posix(), manual_markup["runs"][0]["results"])
    with open(sast_rules_path / "truth.sarif", "w") as truth_f:
        json.dump(manual_markup, truth_f, indent=2)


if __name__ == "__main__":
    main()
