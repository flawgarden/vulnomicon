#!/usr/bin/env python3
import markup_benchmark_java as markup
from pathlib import Path


def main():
    parent = Path(__file__).resolve().parents[1]
    markup.convert((parent / "BenchmarkJava/").absolute().resolve().as_posix(),
            "OWASP-BenchmarkJava-v1.2")


if __name__ == "__main__":
    main()
