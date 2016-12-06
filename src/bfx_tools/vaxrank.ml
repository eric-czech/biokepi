open Biokepi_run_environment
open Common


module Configuration = struct
  type t = {
    name: string;
    (* vaxrank-specific ones *)
    vaccine_peptide_length: int;
    padding_around_mutation: int;
    max_vaccine_peptides_per_mutation: int;
    max_mutations_in_report: int;
    (* isovar-like ones *)
    min_mapping_quality: int;
    min_variant_sequence_coverage: int;
    min_alt_rna_reads: int;
    use_duplicate_reads: bool;
    drop_secondary_alignments: bool;
    (* topiary-like ones *)
    mhc_epitope_lengths: int list;
    (* reporting *)
    reviewers: string list;
    final_reviewer: string;
    xlsx_report: bool;
    pdf_report: bool;
    ascii_report: bool;
    (* the rest *)
    parameters: (string * string) list;
  }
  let to_json {
    name;
    vaccine_peptide_length;
    padding_around_mutation;
    max_vaccine_peptides_per_mutation;
    max_mutations_in_report;
    min_mapping_quality;
    min_variant_sequence_coverage;
    min_alt_rna_reads;
    use_duplicate_reads;
    drop_secondary_alignments;
    mhc_epitope_lengths;
    reviewers;
    final_reviewer;
    xlsx_report;
    pdf_report;
    ascii_report;
    parameters}: Yojson.Basic.json
    =
    `Assoc ([
      "name", `String name;
      "vaccine_peptide_length", `Int vaccine_peptide_length;
      "padding_around_mutation", `Int padding_around_mutation;
      "max_vaccine_peptides_per_mutation", `Int max_vaccine_peptides_per_mutation;
      "max_mutations_in_report", `Int max_mutations_in_report;
      "min_mapping_quality", `Int min_mapping_quality;
      "min_reads_supporting_variant_sequence",
        `Int min_variant_sequence_coverage;
      "min_alt_rna_reads", `Int min_alt_rna_reads;
      "use_duplicate_reads", `Bool use_duplicate_reads;
      "drop_secondary_alignments", `Bool drop_secondary_alignments;
      "mhc_epitope_lengths",
        `List (List.map mhc_epitope_lengths ~f:(fun i -> `Int i));
      "reviewers", `List (List.map ~f:(fun r -> `String r) reviewers);
      "final_reviewer", `String final_reviewer;
      "ascii_report", `Bool ascii_report;
      "pdf_report", `Bool pdf_report;
      "xlsx_report", `Bool xlsx_report;
      "parameters",
        `Assoc (List.map parameters ~f:(fun (a, b) -> a, `String b));
      ])

  let render {
    name;
    vaccine_peptide_length;
    padding_around_mutation;
    max_vaccine_peptides_per_mutation;
    max_mutations_in_report;
    min_mapping_quality;
    min_variant_sequence_coverage;
    min_alt_rna_reads;
    use_duplicate_reads;
    drop_secondary_alignments;
    mhc_epitope_lengths;
    reviewers;
    final_reviewer;
    xlsx_report;
    pdf_report;
    ascii_report;
    parameters}
    =
    let soi = string_of_int in
    ["--vaccine-peptide-length"; soi vaccine_peptide_length] @
    ["--padding-around-mutation"; soi padding_around_mutation] @
    ["--max-vaccine-peptides-per-mutation";
      soi max_vaccine_peptides_per_mutation] @
    ["--max-mutations-in-report"; soi max_mutations_in_report] @
    ["--min-mapping-quality"; soi min_mapping_quality] @
    ["--min-variant-sequence-coverage";
     soi min_variant_sequence_coverage] @
    ["--min-alt-rna-reads"; soi min_alt_rna_reads] @
    (if use_duplicate_reads
      then ["--use-duplicate-reads"] else [""]) @
    (if drop_secondary_alignments
      then ["--drop_secondary_alignments"] else [""]) @
    ["--mhc-epitope-lengths";
      (mhc_epitope_lengths
        |> List.map ~f:string_of_int
        |> String.concat ~sep:",")] @
    (List.concat_map parameters ~f:(fun (a,b) -> [a; b]))
    |> List.filter ~f:(fun s -> not (String.is_empty s))

  let default =
    {name = "default";
     vaccine_peptide_length = 25;
     padding_around_mutation = 0;
     max_vaccine_peptides_per_mutation = 1;
     max_mutations_in_report = 10;
     min_mapping_quality = 1;
     min_variant_sequence_coverage = 1;
     min_alt_rna_reads = 3;
     use_duplicate_reads = false;
     drop_secondary_alignments = false;
     mhc_epitope_lengths = [8; 9; 10; 11];
     reviewers = [];
     final_reviewer = "Reviewer";
     xlsx_report = false;
     pdf_report = false;
     ascii_report = true;
     parameters = []}
  let name t = t.name
end

type product = <
  is_done : Ketrew_pure.Target.Condition.t option ;
  ascii_report_path : string option;
  xlsx_report_path: string option;
  pdf_report_path: string option;
  output_folder_path: string >

let run ~(run_with: Machine.t)
    ~configuration
    ~reference_build
    ~vcfs
    ~bam
    ~predictor
    ~alleles_file
    ~output_folder
  =
  let open KEDSL in
  let host = Machine.(as_host run_with) in
  let vaxrank =
    Machine.get_tool run_with Machine.Tool.Definition.(create "vaxrank")
  in
  let sorted_bam =
    Samtools.sort_bam_if_necessary ~run_with ~by:`Coordinate bam in
  let predictor_tool = Topiary.(predictor_to_tool ~run_with predictor) in
  let (predictor_edges, predictor_init) =
    match predictor_tool with
    | Some (e, i) -> ([depends_on e;], i)
    | None -> ([], Program.(sh "echo 'No external prediction tool required'"))
  in
  let vcfs_arg = List.concat_map vcfs ~f:(fun v -> ["--vcf"; v#product#path]) in
  let bam_arg = ["--bam"; sorted_bam#product#path] in
  let predictor_arg =
    ["--mhc-predictor"; (Topiary.predictor_to_string predictor)] in
  let allele_arg = ["--mhc-alleles-file"; alleles_file#product#path] in
  let output_prefix = output_folder // "vaxrank-result" in
  let output_of switch suffix k  =
    let path = output_prefix ^ suffix in
    let arg = if switch
      then [sprintf "--output-%s-report" k; path] else [] in
    let prod = if switch
      then Some (KEDSL.single_file ~host path) else None in
    arg, prod
  in
  let ascii_arg, ascii_product =
    output_of configuration.Configuration.ascii_report "ascii" "text" in
  let xlsx_arg, xlsx_product =
    output_of configuration.Configuration.xlsx_report "xlsx" "xlsx" in
  let pdf_arg, pdf_product =
    output_of configuration.Configuration.pdf_report "pdf" "pdf" in
  let () =
    match ascii_product, xlsx_product, pdf_product with
    | None, None, None ->
      failwith "Vaxrank requires one or more of pdf_report, \
                xlsx_report, or ascii_report."
    | _, _, _ -> () in
  let arguments =
    vcfs_arg @ bam_arg @ predictor_arg @ allele_arg (* input *)
    @ xlsx_arg @ pdf_arg @ ascii_arg
    @ Configuration.render configuration (* other config *)
  in
  let name = "Vaxrank run" in
  let product =
    let path_of f = Option.map f ~f:(fun f -> f#path) in
    object
      method is_done =
        Some (`And
                (List.filter_map ~f:(fun f ->
                     let open Option in
                     f >>= fun f -> f#is_done)
                   [ascii_product; xlsx_product; pdf_product]))
      method ascii_report_path = path_of ascii_product
      method xlsx_report_path = path_of xlsx_product
      method pdf_report_path = path_of pdf_product
      method output_folder_path = output_folder
    end
  in
  workflow_node
    product
    ~name
    ~edges:([
        depends_on (Samtools.index_to_bai ~run_with sorted_bam);
        depends_on Machine.Tool.(ensure vaxrank);
        depends_on (Pyensembl.cache_genome ~run_with ~reference_build);
        depends_on sorted_bam;
        depends_on alleles_file;
      ] @ (List.map ~f:depends_on vcfs)
        @ predictor_edges)
    ~make:(
      Machine.run_program run_with ~name
        Program.(
          Machine.Tool.(init vaxrank)
          && predictor_init
          && Pyensembl.(set_cache_dir_command ~run_with)
          && shf "mkdir -p %s" (Filename.quote output_folder)
          && exec (["vaxrank"] @ arguments)
        )
    )
