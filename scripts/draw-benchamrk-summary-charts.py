#!/usr/bin/env python3

import json
import sys
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.io as pio

pio.kaleido.scope.mathjax = None


def draw_benchmark_metrics(data, name, filename, tablename):
    df = pd.DataFrame(data, columns=[name, "Metric", "rate, %"])
    df.to_csv(tablename, index=False)

    fig = px.histogram(
        df,
        x=name,
        y="rate, %",
        text_auto=True,
        color="Metric",
        barmode="group",
        height=400,
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
    with open(summary_filename, "r") as file:
        summary = json.load(file)
        for tool_summary in summary["summaries"]:
            tool_name = tool_summary["tool"]["script"]
            runs_summary = tool_summary["runs_summary"]
            at_least_one_file_with_cwe_match = runs_summary[
                "at_least_one_file_with_cwe_match"
            ]
            cwe_true_positive_rate = at_least_one_file_with_cwe_match[
                "true_positive_rate"
            ]
            cwe_false_positive_rate = at_least_one_file_with_cwe_match[
                "false_positive_rate"
            ]
            cwe_recall = at_least_one_file_with_cwe_match["recall"]
            cwe_precision = at_least_one_file_with_cwe_match["precision"]
            cwe_f1_score = at_least_one_file_with_cwe_match["f1_score"]
            at_least_one_file_with_cwe_1000_match = runs_summary[
                "at_least_one_file_with_cwe_1000_match"
            ]
            cwe_1000_true_positive_rate = at_least_one_file_with_cwe_1000_match[
                "true_positive_rate"
            ]
            cwe_1000_false_positive_rate = at_least_one_file_with_cwe_1000_match[
                "false_positive_rate"
            ]
            cwe_1000_recall = at_least_one_file_with_cwe_1000_match["recall"]
            cwe_1000_precision = at_least_one_file_with_cwe_1000_match["precision"]
            cwe_1000_f1_score = at_least_one_file_with_cwe_1000_match["f1_score"]
            cwe_data.append([tool_name, "TPR", cwe_true_positive_rate])
            cwe_data.append([tool_name, "FPR", cwe_false_positive_rate])
            cwe_data.append([tool_name, "Recall", cwe_recall])
            cwe_data.append([tool_name, "Precision", cwe_precision])
            cwe_data.append([tool_name, "F1-score", cwe_f1_score])
            cwe_1000_data.append([tool_name, "TPR", cwe_1000_true_positive_rate])
            cwe_1000_data.append([tool_name, "FPR", cwe_1000_false_positive_rate])
            cwe_1000_data.append([tool_name, "Recall", cwe_1000_recall])
            cwe_1000_data.append([tool_name, "Precision", cwe_1000_precision])
            cwe_1000_data.append([tool_name, "F1-score", cwe_1000_f1_score])
    return cwe_data, cwe_1000_data


def main():
    benchmark_output_path = Path(sys.argv[1]).absolute().resolve().as_posix()
    benchmark_title = sys.argv[2]
    fig_name = sys.argv[3]
    cwe_data, cwe_1000_data = parse_summary(benchmark_output_path)
    fig_path = benchmark_output_path + "/" + fig_name

    draw_benchmark_metrics(
        cwe_data, benchmark_title, fig_path + "_cwe.pdf", fig_path + "_cwe.csv"
    )

    draw_benchmark_metrics(
        cwe_1000_data,
        benchmark_title,
        fig_path + "_cwe_1000.pdf",
        fig_path + "_cwe_1000.csv",
    )


if __name__ == "__main__":
    main()
