#!/usr/bin/env python3
import markup_benchmark_java as markup
from pathlib import Path


def main():
    parent = Path(__file__).resolve().parents[1]
    markup.convert((parent / "BenchmarkJava-mutated/").absolute().resolve().as_posix(),
            "flawgarden-BenchmarkJava-mutated-demo")


if __name__ == "__main__":
    main()
