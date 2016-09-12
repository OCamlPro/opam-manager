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
open ManagerMisc


let opam_root = OpamStateConfig.opamroot ()

let () =
  let _ = OpamStateConfig.load_defaults opam_root in
  OpamStateConfig.init ~root_dir:opam_root ()

let read_switch_config name =
  let fn = OpamPath.Switch.switch_config ManagerPath.opam_root name in
  if not (OpamFile.exists fn) then
    fail ~rc:2 "No global config file found for switch %s."
      (OpamSwitch.to_string name) ;
  OpamFile.Switch_config.read fn

let read_switch_env name =
  let fn = OpamPath.Switch.environment ManagerPath.opam_root name in
  if not (OpamFile.exists fn) then
    fail ~rc:2 "Cannot read %S." (OpamFile.to_string fn) ;
  OpamFile.Environment.read fn

let build name : opam_switch = {
  name ;
  switch_config = lazy (read_switch_config name) ;
  switch_env = lazy (read_switch_env name) ;
}

let safe_build name =
  let fn = OpamPath.Switch.switch_config ManagerPath.opam_root name in
  if not (OpamFile.exists fn) then None
  else Some (build name)

let current = lazy (build (OpamStateConfig.get_switch ()))

(** Environment *)

let bin_dir opam_switch =
  let config = Lazy.force opam_switch.switch_config in
  OpamPath.Switch.bin ManagerPath.opam_root opam_switch.name config

let get_opam_compiler opam_switch =
  let config = Lazy.force opam_switch.switch_config in
  match
    OpamFile.Switch_config.variable config (OpamVariable.of_string "compiler")
  with
  | None | Some (OpamVariable.B _) -> None
  | Some (OpamVariable.S p) -> Some p

let get_env opam_switch =
  let update = Lazy.force opam_switch.switch_env in
  let env =
    let open OpamTypes in
    let add_to_path = bin_dir opam_switch in
    let new_path =
      "PATH", Eq,
      OpamFilename.Dir.to_string add_to_path ^ ":" ^ ManagerPath.clean_path_str,
      Some "Current opam switch binary dir" in
    new_path :: (List.filter (fun (name, _,_,_) -> name <> "PATH") update) in
  OpamEnv.add [] env

let setup_env opam_switch =
  let env = get_env opam_switch in
  List.iter (fun (n, v, _) -> Unix.putenv n v) env

(** Various accessors *)

let is_system_switch opam_switch =
  false (* TODO *)

let opam_config =
  lazy
    (OpamFile.Config.read (OpamPath.config ManagerPath.opam_root))

let all =
  lazy
    (List.fold_left
       (fun acc s ->
          match safe_build s with
          | None -> acc
          | Some s -> s :: acc) []
        (OpamFile.Config.installed_switches (Lazy.force opam_config)))

let of_bin_dir dir =
  let all_switches = Lazy.force all in
  List.find (fun s -> bin_dir s = dir) all_switches

