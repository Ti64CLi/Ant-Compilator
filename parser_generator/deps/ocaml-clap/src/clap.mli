type 'a action =
  | Flag of ('a -> 'a)
  | Int of (int -> 'a -> 'a)
  | String of (string -> 'a -> 'a)
  | Help
  | Version

(** Option identifier *)
type ident

type 'a arg_spec

type 'a t

val app : string -> string -> string list -> string -> 'a t
(** [app name version authors summary] *)

val arg : ident -> ('a action) -> string -> 'a arg_spec

val anon : string -> ?multiple:bool -> ('a action) -> string -> 'a arg_spec

val long : string -> ident

val short : char -> ident

val id : string -> char -> ident

val (+>) : 'a t -> 'a arg_spec -> 'a t

val parse : 'a t -> 'a -> 'a
