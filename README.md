# vulnomicon

**vulnomicon** is a meta-repository for different SAST tool benchmarks.

Usually, benchmark datasets for SAST tools are either synthetic or real-world-based only.
**vulnomicon** contains both synthetic and real-world benchmarks.

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

To set up all of the benchmarks locally, install Python requirements (Python 3.10+ is supposed to be used):

```sh
pip install -r requirements.txt
```

And then run `./bootstrap.sh`.

The bootstrap script will:
* Download, compile and provide ground truth files for all the benchmarks.
* Download the `bentoo` SAST benchmarking tool.

After the bootstrapping is complete, you can run reference tools on the benchmarks by executing the following scripts:
* `scripts/benchmarks/*benchmark-name*/run.sh` - to run the tools on the benchmark with the name `benchmark-name`
* `scripts/benchmarks/*benchmark-name*/run-mutated.sh` - to run the tools on the mutated version of the benchmark with the name `benchmark-name`

The run results will accordingly appear in the `benchmark-name-output` or `benchmark-name-mutated-output` directories.

If you want to tinker with what tools run on what benchmarks (e.g., to run your tool on a subset of `reality-check`),
please consult the [`bentoo` documentation](https://github.com/flawgarden/bentoo).

For now, **vulnomicon** contains benchmarks for Java, C#, Go, and Python.

Almost all the benchmarks have the [workflows](https://github.com/flawgarden/vulnomicon/tree/main/.github/workflows) to run them on CI.
