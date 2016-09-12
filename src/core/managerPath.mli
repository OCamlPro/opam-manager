(**************************************************************************)
(*                                                                        *)
(*    Copyright 2014-2015, Gregoire Henry, OCamlPro                       *)
(*                                                                        *)
(*  All rights reserved.This file is distributed under the terms of the   *)
(*  GNU Lesser General Public License version 3.0 with linking            *)
(*  exception.                                                            *)
(*                                                                        *)
(*  OPAM is distributed in the hope that it will be useful, but WITHOUT   *)
(*  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY    *)
(*  or FITNESS FOR A PARTICULAR PURPOSE.See the GNU General Public        *)
(*  License for more details.                                             *)
(*                                                                        *)
(**************************************************************************)

open OpamTypes
open ManagerTypes

(** Commont opam-manager files' path. *)

val opam_root: dirname

val base_dir: dirname
val bin_dir: dirname
val defaults_dir: dirname

val default_wrapper_binary: OpamFilename.t
val wrapper_binary: OpamFilename.t

(** PATH related *)

val find_in_path: OpamFilename.Base.t -> dirname option

val is_path_uptodate: unit -> bool

(* The PATH without 'bin_dir' *)
val clean_path: dirname list
val clean_path_str: string
