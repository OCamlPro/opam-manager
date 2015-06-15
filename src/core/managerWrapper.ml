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

let safe_remove file =
  Unix.handle_unix_error OpamFilename.remove file

let safe_link ~src ~dst =
  Unix.handle_unix_error (fun () -> OpamFilename.link ~src ~dst) ()

(** Info about binaries in switch *)

(* List the binaries provided by all the [switches] *)
let get_binaries switches =
  let get switch =
    List.fold_right
      (fun file acc ->
         let name = OpamFilename.Base.to_string (OpamFilename.basename file) in
         OpamStd.String.Set.add name acc)
      (OpamFilename.files (ManagerSwitch.bin_dir switch))
      OpamStd.String.Set.empty in
  List.fold_left
    OpamStd.String.Set.union
    OpamStd.String.Set.empty
    (List.map get switches)

(* Returns the map that associates to each binaries found in 'switches'
   the list of switches that provides the binary. *)
let get_binaries_info switches =
  List.fold_left
    (fun map switch ->
       let binaries = get_binaries switch in
       let add_switch binary map =
         let switches =
           try switch :: (OpamStd.String.Map.find binary map)
           with Not_found -> [switch] in
         OpamStd.String.Map.add binary switches map in
       OpamStd.String.Set.fold add_switch binaries map)
    OpamStd.String.Map.empty
    switches


(** Wrapper creation/removal *)

let create config basename =
  let wrapper = OpamFilename.create ManagerPath.bin_dir basename in
  safe_remove wrapper;
  safe_link ~src:config.wrapper_binary ~dst:wrapper

let remove basename =
  safe_remove @@ OpamFilename.create ManagerPath.bin_dir basename

(* List all the wrappers in [.ocp/manager/bin] *)
let get_wrappers () =
  List.fold_right
    (fun file acc ->
       let name = OpamFilename.Base.to_string (OpamFilename.basename file) in
       OpamStd.String.Set.add name acc)
    (OpamFilename.files ManagerPath.bin_dir)
    OpamStd.String.Set.empty

let update_switch config switch =
  let binaries = get_binaries [switch] in
  let wrappers = get_wrappers () in
  let missings = OpamStd.String.Set.diff binaries wrappers in
  OpamStd.String.Set.iter
    (fun name -> create config (OpamFilename.Base.of_string name))
    missings

let update ?(verbose = false) config =
  let binaries = get_binaries (ManagerSwitch.all config) in
  let wrapper = get_wrappers () in
  let defaults = ManagerDefault.list_absolute config in
  let missings = OpamStd.String.Set.diff binaries wrapper in
  let dangling =
    OpamStd.String.Set.diff
      wrapper
      (OpamStd.String.Set.union defaults binaries) in
  if verbose && OpamStd.String.Set.empty <> dangling then
    info "Removing %d wrapper(s)" (OpamStd.String.Set.cardinal dangling);
  OpamStd.String.Set.iter
    (fun name -> remove (OpamFilename.Base.of_string name))
    dangling;
  if verbose then
    if OpamStd.String.Set.empty = missings then
      info "No missing wrapper"
    else
      info "Creating %d generic wrapper(s)" (OpamStd.String.Set.cardinal missings);
  OpamStd.String.Set.iter
    (fun name -> create config (OpamFilename.Base.of_string name))
    missings

