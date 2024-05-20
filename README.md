# vulnomicon

Vulnomicon is a meta-repository for different SAST tool benchmarks.

Usually, benchmark datasets for SAST tools are either synthetic or real-world-based only.
Vulnomicon contains both synthetic and real-world benchmarks.

Synthetic benchmarks are generated using mutational fuzzing.
Existing benchmarks are used as initial seeds for the fuzzer. The fuzzer uses handwritten
templates to mutate seeds while preserving the compilability of the resulting test cases.
The objective of the fuzzer is to generate tests on which different tools behave differently.
Thus, the generated benchmark allows us to exhibit the weaknesses of different SAST tools relative to each other.

Real-world benchmarks are generated semi-automatically from the [CVE database](https://cve.mitre.org/).
First, the information about available real-world vulnerabilities is parsed,
the corresponding projects are downloaded, and the ground truth markup is generated.
Then, the generated benchmark is audited by hand to rule out cases where the CVE
information is inaccurate or incomplete. Since CVE is actively updated, the real-world vulnerability benchmark can constantly grow with actual code written with modern technologies and tools.

The goal of this repository is to assemble a benchmark suite for SAST tools
that is best suited to exhibiting differences in different SAST tools' analyses.

The benchmark suite uses a benchmarking utility called `bentoo` to run SAST tools on benchmarks
and evaluate the results.
The format for ground truth markup is a subset of the SARIF format called `bentoo-sarif`.
Vulnerabilities described in the ground truth are classified according to the [CWE classification](https://cwe.mitre.org/).
For more info on `bentoo` and `bentoo-sarif`, please visit the [`bentoo` repository](https://github.com/flawgarden/bentoo).

As of today, it contains three submodules:
1. `BenchmarkJava` - a clone of the OWASP Java Benchmark (used for reference).
2. `BenchmarkJavaMutated` - a synthetic Java benchmark generated using mutational fuzzing on the OWASP benchmark.
3. `reality-check` - a collection of real-world vulnerabilities (and their fixes) for Java based on the CVE database.

To set up all of the benchmarks locally, run `./bootstrap.sh`.

The bootstrap script will:
* Download, compile and provide ground truth files for `BenchmarkJava` and `BencmarkJava-mutated`.
* Bootstrap `reality-check`:
  - Download the projects that the `reality-check` benchmark consists of.
  - Provide them with ground truth files.
* Download the `bentoo` SAST benchmarking tool.
* Download a set of tool runner scripts that are used by `bentoo` to run tools on benchmarks.

For reference, the runner scripts downloaded will use dockerized versions of popular tools (`CodeQL`, `Semgrep`, etc.).

After the bootstrapping is complete, you can run reference tools on the benchmarks by executing the following scripts:
* `scripts/runBenchmarkJava.sh` - to run the tools on `BenchmarkJava`
* `scripts/runBenchmarkJavaMutated.sh` - to run the tools on `BenchmarkJava-mutated`
* `scripts/runRealityCheck.sh` - to run the tools on `reality-check` (might take ~24 hours on an average machine)

The run results will accordingly appear in the `BenchmarkJava-output`, `BenchmarkJava-mutated-output` and `reality-check-output` directories.

If you want to tinker with what tools run on what benchmarks (e.g., to run your tool on a subset of `reality-check`),
please consult the [`bentoo` documentation](https://github.com/flawgarden/bentoo).

## Roadmap
For now, vulnomicon contains benchmarks only for Java. We plan to add benchmarks for C#, Go, and Python.
For each language, the planned pipeline is as follows:
1. Adapt some of the existing benchmarks for the language to `bentoo-sarif` to be later used for reference.
2. Make a synthetic benchmark that covers all language features and exhibits differences in tools' analyses using mutational fuzzing as described above. Reference benchmarks will be used as initial seeds for the fuzzer.
3. Use the CVE database entries for the given language to gather cases of the real-world benchmark and then audit it by hand to compile the real-world benchmark.
