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

type opam_root = {
  opam_root_path: OpamPath.t;
  (* Cache: *)
  mutable opam_root_config: OpamFile.Config.t option;
  mutable opam_root_env_state: OpamState.state option;
  mutable opam_root_state: OpamState.state option;
}

type root_kind =
  | Opam_root of opam_root

type root = {
  root_name: string;
  root_kind: root_kind;
}

type opam_switch = {
  opam_root_name: string;
  opam_root: opam_root;
  opam_switch: OpamSwitch.t option; (* [None] means the default switch *)
  (* Cache: *)
  mutable opam_env_state: OpamState.state option;
}

type switch =
  | Opam_switch of opam_switch

(** Configuration files *)

type config = {
  default_root_name: string;
  known_roots: root list;
  wrapper_binary: OpamFilename.t;
}

type root_config = {
  manager_dir: dirname;
}
