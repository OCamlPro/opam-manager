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

val current: opam_switch Lazy.t
val all: opam_switch list Lazy.t

val of_bin_dir: dirname -> opam_switch

(** Accessors *)

val is_system_switch: opam_switch -> bool
val bin_dir: opam_switch -> dirname

(** Environment *)

val setup_env: opam_switch -> unit
