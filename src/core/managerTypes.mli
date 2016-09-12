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

(** Root *)

type opam_root = {
  path: OpamPath.t ;
  (* Parsed file cache: *)
  config: OpamFile.Config.t Lazy.t ;
}

(** Switch *)

type opam_switch = {
  name: OpamSwitch.t ;
  (* Parsed file cache: *)
  switch_config: OpamFile.Switch_config.t Lazy.t ;
  switch_env: OpamFile.Environment.t Lazy.t ;
}
