#!/usr/bin/env python3

import json
import sys
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.io as pio

pio.kaleido.scope.mathjax = None


def draw_benchmark_metrics(data, name, filename, tablename):
    df = pd.DataFrame(data, columns=[name, "Metric", "rate, unit interval"])
    df.to_csv(tablename, index=False)

    fig = px.bar(
        df,
        x=name,
        y="rate, unit interval",
        text_auto=True,
        color="Metric",
        barmode="group",
        height=400,
    )
    fig.update_traces(
        textfont_size=12, textangle=0, textposition="outside", cliponaxis=False
    )

    fig.write_image(filename)


def draw_benchmark_time(data, name, filename, tablename):
    df = pd.DataFrame(data, columns=[name, "Time, s"])
    df.to_csv(tablename, index=False)

    fig = px.bar(df, x=name, y="Time, s", text_auto=True, color="Time, s", height=400)
    fig.update_traces(
        textfont_size=12, textangle=0, textposition="outside", cliponaxis=False
    )

    fig.write_image(filename)


def draw_benchmark_time_leafs(data, name, filename, tablename):
    df = pd.DataFrame(data, columns=[name, "Time, s", "Project Number"])
    df.to_csv(tablename, index=False)

    fig = px.bar(
        df,
        x="Project Number",
        y="Time, s",
        text_auto=True,
        color=name,
        facet_row=name,
        height=1800,
        width=4000,
    )
    fig.update_traces(
        textfont_size=12, textangle=0, textposition="outside", cliponaxis=False
    )

    fig.write_image(filename)


def draw_benchmark_dist_metrics(data, name, filename, tablename):
    df_benchmark_reality_check = pd.DataFrame(
        data, columns=[name, "Tool", "True Positive Count"]
    )

    fig_benchmark_reality_check = px.bar(
        df_benchmark_reality_check,
        x=name,
        y="True Positive Count",
        color="Tool",
        height=400,
    )
    fig_benchmark_reality_check.update_traces(
        textfont_size=12, textangle=0, textposition="outside", cliponaxis=False
    )

    fig_benchmark_reality_check.write_image(filename)
    df_benchmark_reality_check.to_csv(tablename, index=False)


def parse_summary(output_path):
    summary_filename = output_path + "/summary.json"
    cwe_data = []
    cwe_1000_data = []
    cwe_region_data = []
    cwe_1000_region_data = []
    time_data = []
    with open(summary_filename, "r") as file:
        summary = json.load(file)
        for tool_summary in summary["summaries"]:
            tool_name = (
                tool_summary["tool"]["script"] + "/" + tool_summary["tool"]["config"]
            )
            tool_time = tool_summary["total_time"]["secs"]
            runs_summary = tool_summary["runs_summary"]
            at_least_one_file_with_cwe_match = runs_summary[
                "at_least_one_file_with_cwe_match"
            ]
            at_least_one_region_with_cwe_match = runs_summary[
                "at_least_one_region_with_cwe_match"
            ]
            cwe_false_positive_rate = at_least_one_file_with_cwe_match[
                "false_positive_rate"
            ]
            cwe_region_false_positive_rate = at_least_one_region_with_cwe_match[
                "false_positive_rate"
            ]
            cwe_recall = at_least_one_file_with_cwe_match["recall"]
            cwe_precision = at_least_one_file_with_cwe_match["precision"]
            if cwe_precision is None:
                cwe_precision = 0
            cwe_f1_score = at_least_one_file_with_cwe_match["f1_score"]
            cwe_region_recall = at_least_one_region_with_cwe_match["recall"]
            cwe_region_precision = at_least_one_region_with_cwe_match["precision"]
            if cwe_region_precision is None:
                cwe_region_precision = 0
            cwe_region_f1_score = at_least_one_region_with_cwe_match["f1_score"]
            at_least_one_file_with_cwe_1000_match = runs_summary[
                "at_least_one_file_with_cwe_1000_match"
            ]
            cwe_1000_false_positive_rate = at_least_one_file_with_cwe_1000_match[
                "false_positive_rate"
            ]
            cwe_1000_recall = at_least_one_file_with_cwe_1000_match["recall"]
            cwe_1000_precision = at_least_one_file_with_cwe_1000_match["precision"]
            if cwe_1000_precision is None:
                cwe_1000_precision = 0
            cwe_1000_f1_score = at_least_one_file_with_cwe_1000_match["f1_score"]
            at_least_one_region_with_cwe_1000_match = runs_summary[
                "at_least_one_region_with_cwe_1000_match"
            ]
            cwe_1000_region_false_positive_rate = (
                at_least_one_region_with_cwe_1000_match["false_positive_rate"]
            )
            cwe_1000_region_recall = at_least_one_region_with_cwe_1000_match["recall"]
            cwe_1000_region_precision = at_least_one_region_with_cwe_1000_match[
                "precision"
            ]
            if cwe_1000_region_precision is None:
                cwe_1000_region_precision = 0
            cwe_1000_region_f1_score = at_least_one_region_with_cwe_1000_match[
                "f1_score"
            ]
            tpr_name = "Recall (TPR)"
            fpr_name = "False alarm (FPR)"
            ppv_name = "Precision (PPV)"
            f1_name = "F1-score"
            cwe_data.append([tool_name, tpr_name, cwe_recall])
            cwe_data.append([tool_name, fpr_name, cwe_false_positive_rate])
            cwe_data.append([tool_name, ppv_name, cwe_precision])
            cwe_data.append([tool_name, f1_name, cwe_f1_score])
            cwe_region_data.append([tool_name, tpr_name, cwe_region_recall])
            cwe_region_data.append(
                [tool_name, fpr_name, cwe_region_false_positive_rate]
            )
            cwe_region_data.append([tool_name, ppv_name, cwe_region_precision])
            cwe_region_data.append([tool_name, f1_name, cwe_region_f1_score])
            cwe_1000_data.append([tool_name, tpr_name, cwe_1000_recall])
            cwe_1000_data.append([tool_name, fpr_name, cwe_1000_false_positive_rate])
            cwe_1000_data.append([tool_name, ppv_name, cwe_1000_precision])
            cwe_1000_data.append([tool_name, f1_name, cwe_1000_f1_score])
            cwe_1000_region_data.append([tool_name, tpr_name, cwe_1000_region_recall])
            cwe_1000_region_data.append(
                [tool_name, fpr_name, cwe_1000_region_false_positive_rate]
            )
            cwe_1000_region_data.append(
                [tool_name, ppv_name, cwe_1000_region_precision]
            )
            cwe_1000_region_data.append([tool_name, f1_name, cwe_1000_region_f1_score])
            time_data.append([tool_name, tool_time])
    return cwe_data, cwe_1000_data, cwe_region_data, cwe_1000_region_data, time_data


def parse_leaf_summaries(root_path):
    cwe_data = []
    cwe_1000_data = []
    time_data = []
    leaf_count = 0
    index = 1
    for truth_path in Path(root_path).rglob("truth.sarif"):
        output_path = truth_path.parent
        (
            project_cwe_data,
            project_cwe_1000_data,
            project_cwe_region_data,
            project_cwe_1000_region_data,
            project_time_data,
        ) = parse_summary(output_path.as_posix())
        for data in project_cwe_data:
            data.append(str(index))
        for data in project_cwe_1000_data:
            data.append(str(index))
        for data in project_time_data:
            data.append(str(index))
        cwe_data.extend(project_cwe_data)
        cwe_1000_data.extend(project_cwe_1000_data)
        time_data.extend(project_time_data)
        leaf_count += 1
        index += 1

    return cwe_data, cwe_1000_data, time_data, leaf_count


def main():
    benchmark_output_path = Path(sys.argv[1]).absolute().resolve().as_posix()
    benchmark_title = sys.argv[2]
    fig_name = sys.argv[3]
    cwe_data, cwe_1000_data, cwe_region_data, cwe_1000_region_data, time_data = (
        parse_summary(benchmark_output_path)
    )
    leaf_cwe_data, leaf_cwe_1000_data, leaf_time_data, leaf_count = (
        parse_leaf_summaries(benchmark_output_path)
    )
    fig_path = benchmark_output_path + "/" + fig_name

    draw_benchmark_metrics(
        cwe_data, benchmark_title + " CWE", fig_path + "_cwe.pdf", fig_path + "_cwe.csv"
    )

    draw_benchmark_metrics(
        cwe_region_data,
        benchmark_title + " CWE region",
        fig_path + "_cwe_region.pdf",
        fig_path + "_cwe_region.csv",
    )

    draw_benchmark_metrics(
        cwe_1000_data,
        benchmark_title + " CWE 1000",
        fig_path + "_cwe_1000.pdf",
        fig_path + "_cwe_1000.csv",
    )

    draw_benchmark_metrics(
        cwe_1000_region_data,
        benchmark_title + " CWE 1000 region",
        fig_path + "_cwe_1000_region.pdf",
        fig_path + "_cwe_1000_region.csv",
    )

    draw_benchmark_time(
        time_data,
        benchmark_title + " Time",
        fig_path + "_time.pdf",
        fig_path + "_time.csv",
    )

    if leaf_count > 1:
        draw_benchmark_time_leafs(
            leaf_time_data,
            benchmark_title + " Time",
            fig_path + "_time_per_project.pdf",
            fig_path + "_time_per_project.csv",
        )


if __name__ == "__main__":
    main()
