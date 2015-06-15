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

val current:
  ?argv:string array -> config ->
  switch * [ `File of string | `Env of string | `Argv | `Default ]
val all: config -> switch list

val find_switch: config -> ?default:ManagerTypes.root -> string -> switch

val display_src:
  [ `File of string | `Env of string | `Argv | `Default ] -> unit

(** Accessors *)

val is_valid: switch -> bool

val name: switch -> string
val is_opam_system_switch: switch -> bool
val bin_dir: switch -> dirname
val root: switch -> root

val opam_switch_name: opam_switch -> OpamSwitch.t

(** Environment *)

val setup_minimal_env: switch -> unit
val setup_env: switch -> unit

(** Helpers *)

val equal: switch -> switch -> bool
val compare: switch -> switch -> int
