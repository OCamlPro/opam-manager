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
  opam_root_path: OpamPath.t;
  (* Parsed file cache: *)
  mutable opam_root_config: OpamFile.Config.t option;
}

type root_kind =
  | Opam_root of opam_root

type root = {
  root_name: string;
  root_kind: root_kind;
}

(** Switch *)

type opam_switch = {
  opam_root_name: string;
  opam_root: opam_root;
  opam_switch: OpamSwitch.t;
  (* Parsed file cache: *)
  mutable opam_switch_config: OpamFile.Dot_config.t option;
  mutable opam_switch_env: OpamFile.Environment.t option;
}

type switch =
  | Opam_switch of opam_switch

(** Opam-manager configuration file *)

type config = {
  manager_version: ManagerVersion.t;
  default_root_name: string;
  known_roots: root list;
  wrapper_binary: OpamFilename.t;
}

type root_config = {
  manager_dir: dirname;
}
