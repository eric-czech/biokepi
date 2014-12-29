Biokepi: Bioinformatics Ketrew Pipelines
========================================

This project provides a library allowing to construct many “Ketrew Targets” to
build bioinformatics pipelines. 

The library can download most of the tools by itself (through more Ketrew
targets).

The library also contains an experimental module called `Biokepi_pipeline` which
uses a GADT to express concise and well-typed analysis pipelines.

There is also a *demo* command line application.

This should be considered *“alpha / preview”* software.

Build
-----

To install through `opam`:

    opam pin add biokepi .
    [opam install biokepi]


To build locally:

    make configure
    make

Using The Demo Application
--------------------------

The application is meant to show how to program with the library, especially
building pipelines with `Biokepi_pipeline`.

For now the demo pipeline looks like a somatic variant calling pipeline (hence
the used of the words “tumor,” “normal,” etc) but they have not been debugged
enough to be used.

It is configured with environment variables, it will run the pipelines on a
given machine accessed through SSH (and within the demo one cannot specify a
scheduler interface).

You need first a “client” configuration file for Ketrew:

```
debug-level = 2
[client]
  connection = "https://some.server.where.ketrew.runs:8443"
  token = "netok"
```

If it is not in the default location you may force it with:
`export KETREW_CONFIGURATION=client-config-file.toml`.

Variables to set:

- `BIOKEPI_DATASET_NAME`: just a name for the dataset used as a namespace for
file-naming.
- `BIOKEPI_NORMAL_R1`, `BIOKEPI_NORMAL_R2`, `BIOKEPI_TUMOR_R1`, and
`BIOKEPI_TUMOR_R2`: the input files, for now each variable may contain a
comma-separated list of `fastq.gz` (absolute) paths on the running machine.
- `BIOKEPI_SSH_BOX_URI`: an URI describing the machine to run on; for example
`ssh://SshName//home/user/biokepi-test/metaplay` where:
    - `SshName` would be an entry in the `.ssh/config` of the server running
    Ketrew,
    - `/home/user/biokepi-test/metaplay` is the top-level directory where every
    generated file will go.
- `BIOKEPI_MUTECT_JAR_SCP` or `BIOKEPI_MUTECT_JAR_WGET`: if you use Mutect
(which the default pipeline does) you need to provide a way to download the
JAR file (`biokepi` would violate its non-free license by doing it
itself). So use something like:
`BIOKEPI_MUTECT_JAR_SCP=MyServer:/path/to/mutect.jar`.
- `BIOKEPI_CYCLEDASH_URL`: if you are using
[Cycledash](https://github.com/hammerlab/cycledash) (i.e. the option `-P`) then 
you need to provide the base URL (Biokepi will append `/runs` and `/upload` to
that URL).

Then you can run:

    ./biokepi run -N dumb [-P]
    
(for now `dumb` is the only available pipeline).
This should submit a pretty big pipeline to stress-test your Ketrew server
(about 1300 targets, creating about 1 TB of data).
