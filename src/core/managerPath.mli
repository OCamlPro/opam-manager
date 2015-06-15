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


(** Commont opam-manager files' path. *)

val base_dir: dirname
val bin_dir: dirname
val defaults_dir: dirname

val config_file: filename
val default_wrapper_binary: filename


(** PATH related *)

val find_in_path: OpamFilename.Base.t -> dirname option

(* The PATH without 'bin_dir' *)
val clean_path: OpamFilename.Dir.t list
val clean_path_str: string
