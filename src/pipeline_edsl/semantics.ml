
module type Lambda_calculus = sig
  type 'a repr  (* representation type *)

  (* lambda abstract *)
  val lambda : ('a repr -> 'b repr) -> ('a -> 'b) repr
  (* application *)
  val apply : ('a -> 'b) repr -> 'a repr -> 'b repr

  type 'a observation
  val observe : (unit -> 'a repr) -> 'a observation
end

module type Lambda_with_list_operations = sig
  include Lambda_calculus
  module List_repr: sig
    val make: ('a repr) list -> 'a list repr
    val map: ('a list repr) -> f:('a -> 'b) repr -> ('b list repr)
  end
end

(* this should move to the Bwa module *)
type bwa_params = {
  gap_open_penalty: int;
  gap_extension_penalty: int;
}


module type Bioinformatics_base = sig

  include Lambda_with_list_operations

  val fastq : 
    sample_name : string ->
    ?fragment_id : string ->
    r1: string ->
    ?r2: string ->
    unit -> [ `Fastq ] repr

  val fastq_gz:
    sample_name : string ->
    ?fragment_id : string ->
    r1: string -> ?r2: string ->
    unit -> [ `Gz of [ `Fastq ] ] repr

  val bam :
    path : string ->
    ?sorting: [ `Coordinate | `Read_name ] ->
    reference_build: string ->
    unit -> [ `Bam ] repr

  val bwa_aln:
    ?configuration: bwa_params ->
    [ `Fastq ] repr ->
    [ `Bam ] repr

  val gunzip: [ `Gz of 'a] repr -> 'a repr

  val gunzip_concat: ([ `Gz of 'a] list) repr -> 'a repr

  val concat: ('a list) repr -> 'a repr


  val merge_bams: ([ `Bam ] list) repr -> [ `Bam ] repr

  val mutect:
    configuration: Biokepi_bfx_tools.Mutect.Configuration.t ->
    normal: [ `Bam ] repr ->
    tumor: [ `Bam ] repr ->
    [ `Vcf ] repr

end

