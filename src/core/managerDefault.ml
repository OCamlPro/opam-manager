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
open ManagerTypes

(** Symlink creation and destruction *)

type defaults =
  | Absolute of OpamFilename.t
  | Switch of opam_switch

let safe_remove file =
  if OpamFilename.exists file then
    Unix.handle_unix_error OpamFilename.remove file

let safe_link ~src ~dst =
  Unix.handle_unix_error (fun () -> OpamFilename.link ~src ~dst) ()

let rec resolve file =
  if OpamFilename.exists file && OpamFilename.is_symlink file then
    resolve (OpamFilename.readlink file)
  else
    file

let create basename binary =
  let default = OpamFilename.create ManagerPath.defaults_dir basename in
  let binary =
    match binary with
    | Absolute binary -> binary
    | Switch s -> OpamFilename.create (ManagerSwitch.bin_dir s) basename in
  safe_remove default;
  safe_link ~src:binary ~dst:default

let remove basename =
  safe_remove @@ OpamFilename.create ManagerPath.defaults_dir basename

let parse file =
  try
    let link = OpamFilename.readlink file in
    let bin_dir = OpamFilename.dirname link in
    Switch (ManagerSwitch.of_bin_dir bin_dir)
  with _ -> Absolute (resolve file)

(* List all the 'default' binaries. *)
let all () =
  List.fold_right
    (fun file acc ->
       let name = OpamFilename.Base.to_string (OpamFilename.basename file) in
       OpamStd.String.Map.add name (parse file) acc)
    (OpamFilename.files ManagerPath.defaults_dir)
    OpamStd.String.Map.empty

let check filename =
  let resolved = resolve filename in
  let kind = parse filename in
  if not (OpamFilename.exists resolved) then
    match kind with
    | Absolute _ ->
        fail "Dangling external in %s : %s."
          (OpamFilename.Dir.to_string ManagerPath.defaults_dir)
          (OpamFilename.(Base.to_string @@ basename filename))
    | Switch s ->
        fail "Dangling promoted binary from %s : %s."
          (OpamSwitch.to_string s.name)
          (OpamFilename.(Base.to_string @@ basename filename))
  else if not (OpamFilename.is_exec resolved) then
    match kind with
    | Absolute file ->
        fail "Promoted external binary is not extecutable %S."
          (OpamFilename.to_string file)
    | Switch s ->
        fail "Promoted binary is not executable %S from %s."
          (OpamFilename.(Base.to_string @@ basename filename))
          (OpamSwitch.to_string s.name)

let find name =
  let filename = OpamFilename.create ManagerPath.defaults_dir name in
  if OpamFilename.exists filename &&
     OpamFilename.is_symlink filename then begin
    check filename;
    Some filename
  end else
    None

let create name kind =
  let dst = OpamFilename.create ManagerPath.defaults_dir name in
  let src =
    match kind with
    | Absolute path -> path
    | Switch s -> OpamFilename.create (ManagerSwitch.bin_dir s) name in
  OpamFilename.link ~src ~dst

let create_absolute name =
  match ManagerPath.find_in_path name with
  | None -> raise Not_found
  | Some path -> create name (Absolute (OpamFilename.create path name))

let list_absolute config =
  List.fold_left
    (fun acc file ->
       match parse file with
       | Absolute _ ->
           let base = OpamFilename.basename file in
           let name = OpamFilename.Base.to_string base in
           OpamStd.String.Set.add name acc
       | Switch _   ->
           acc)
    OpamStd.String.Set.empty
    (OpamFilename.files ManagerPath.defaults_dir)
