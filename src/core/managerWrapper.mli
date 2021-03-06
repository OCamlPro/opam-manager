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

open ManagerTypes

val create: OpamFilename.Base.t -> unit

(** Create wrappers for all the binaries found in 'switch'. *)
val update_switch: opam_switch -> unit

(** Create or remove wrappers to match the binaries found in all known
    switches. *)
val update:
  ?check_symlink:bool -> ?verbose:bool ->
  unit -> unit
