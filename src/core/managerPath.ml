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

open ManagerMisc

let base_dir =
  let open OpamFilename.Op in
  try OpamFilename.Dir.of_string @@ Sys.getenv "OPAMMANAGERROOT"
  with Not_found ->
    try OpamFilename.Dir.of_string (Sys.getenv "HOME") / ".ocp" / "manager"
    with Not_found ->
      fail "Error: can't configure `opam-manager` main directory.\
           \ Please define HOME ot OPAMMANAGERROOT"

let bin_dir =
  let open OpamFilename.Op in
  base_dir / "bin"

let defaults_dir =
  let open OpamFilename.Op in
  base_dir / "defaults"

let config_file =
  let open OpamFilename.Op in
  base_dir // "config"

let default_wrapper_binary =
  let open OpamFilename.Op in
  let exec_dir =
    OpamFilename.dirname (OpamFilename.of_string Sys.executable_name) in
  let base_dir = OpamFilename.dirname_dir exec_dir in
  base_dir / "lib" / "opam-manager" // "opam-manager-wrapper"


(** **)

(* TODO remove unit in OPAM ?? *)
let path_sep = OpamStd.Sys.path_sep ()

let path =
  let path = try OpamStd.Env.get "PATH" with Not_found -> "" in
  let path = OpamStd.String.split path path_sep in
  List.map OpamFilename.Dir.of_string path

(* PATH without opam_manager's own "bin" directory *)
let clean_path = List.filter (fun d -> d <> bin_dir) path

let clean_path_str =
  let path_sep = String.make 1 path_sep in
  String.concat path_sep (List.map OpamFilename.Dir.to_string clean_path)

let find_in_path exe =
  let open OpamFilename.Op in
  let rec iter path =
    match path with
      [] -> None
    | bindir :: next_path ->
        if OpamFilename.exists (OpamFilename.create bindir exe) then
          Some bindir
        else
          iter next_path in
  iter clean_path
