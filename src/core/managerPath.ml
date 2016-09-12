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

let opam_root = OpamStateConfig.opamroot ()

let base_dir =
  let open OpamFilename.Op in
  opam_root / "plugins" / "manager"

let bin_dir =
  let open OpamFilename.Op in
  base_dir / "bin"

let defaults_dir =
  let open OpamFilename.Op in
  base_dir / "defaults"

let default_wrapper_binary =
  let open OpamFilename.Op in
  let exec_dir =
    OpamFilename.dirname (OpamFilename.of_string Sys.executable_name) in
  OpamFilename.dirname_dir exec_dir / "lib" / "opam-manager" // "opam-manager-wrapper"

let wrapper_binary =
  let open OpamFilename.Op in
  base_dir / "lib" / "opam-manager" // "opam-manager-wrapper"


(** **)

let path_sep = OpamStd.Sys.path_sep ()

let rec remove_trailing_slash dir =
  let len = String.length dir in
  if len > 1 && dir.[len-1] = '/' then
    remove_trailing_slash (String.sub dir 0 (len-1))
  else
    dir

let path =
  let path = try OpamStd.Env.get "PATH" with Not_found -> "" in
  let path = OpamStd.String.split path path_sep in
  let path = List.map remove_trailing_slash path in
  List.map OpamFilename.Dir.of_string path

let is_path_uptodate () = List.mem bin_dir path

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
