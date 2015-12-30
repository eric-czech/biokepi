(** Simplified creation of {!Run_enviromment.Machine.t} values *)

(** Build a {!Run_enviromment.Machine.t} with convenient default values.

    The [string] argument is a URI like the one expected 
    by {!Ketrew.EDSL.Host.parse} except that the “path” is the
    meta-playground for Biokepi (the ketrew playground will be
    [(meta_playground // "ketrew_playground")].

    The default [run_program] is daemonizing with [`Python_daemon].

    This machine will get tools installations and data-fethcing form
    Biokepi's defaults. The [?b37] argument allows to override the
    locations of the “B37” genome; to override other deafult please use directly
    {!Run_enviromment.Machine.create}.
*)
val create :
  gatk_jar_location:(unit -> [ `Scp of string | `Wget of string ]) ->
  mutect_jar_location:(unit -> [ `Scp of string | `Wget of string ]) ->
  ?run_program:Run_environment.Machine.run_function ->
  ?b37:Reference_genome.t -> string ->
  Run_environment.Machine.t