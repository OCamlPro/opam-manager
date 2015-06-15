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
open OpamState.Types

let get_opam_root_config opam_root =
  match opam_root.opam_root_config with
  | Some config -> config
  | None ->
      match OpamStateConfig.load opam_root.opam_root_path with
      | None ->
          fail "Invalid OPAMROOT : %S"
            (OpamFilename.Dir.to_string opam_root.opam_root_path)
      | Some config ->
          opam_root.opam_root_config <- Some config;
          config

let get_opam_state opam_root =
  match opam_root.opam_root_state with
  | Some state -> state
  | None ->
      let root_dir = opam_root.opam_root_path in
      let opam_root_config = get_opam_root_config opam_root in
      let current_switch = OpamFile.Config.switch opam_root_config in
      OpamStateConfig.update ~root_dir ~current_switch ();
      let state =
        OpamState.load_state "manager-root-state" current_switch in
      opam_root.opam_root_state <- Some state;
      state

let get_opam_env_state opam_root =
  match opam_root.opam_root_state with
  | Some state -> state
  | None ->
      (* FIXME: .opam/config is read twice in this branch! *)
      let root_dir = opam_root.opam_root_path in
      let opam_root_config = get_opam_root_config opam_root in
      let current_switch = OpamFile.Config.switch opam_root_config in
      OpamStateConfig.update ~root_dir ~current_switch ();
      let state =
        OpamState.load_env_state "manager-root-env-state" current_switch in
      opam_root.opam_root_state <- Some state;
      state

let create_opam_root root_name opam_root_path =
  { root_name ;
    root_kind =
      Opam_root
        { opam_root_path ;
          opam_root_config = None ;
          opam_root_state = None ;
          opam_root_env_state = None ;
        }
  }

let from_path ?(anonymous = true) config path =
  let have_path = function
    | { root_kind = Opam_root { opam_root_path } } -> opam_root_path = path in
  try List.find have_path config.known_roots
  with Not_found ->
    (* TODO warn: fail "using unregistered root %S.\n%!" path; *)
    (* TODO fail when the path does not correspond to a valid OPAMROOT *)
    if anonymous then create_opam_root "**anonymous**" path else raise Not_found

exception Unknown_root_name of string * bool

let from_name config name =
  let have_name { root_name } = root_name = name in
  try List.find have_name config.known_roots
  with Not_found ->
    raise (Unknown_root_name (name, false))

let default config =
  try from_name config config.default_root_name
  with Unknown_root_name _ ->
    raise (Unknown_root_name (config.default_root_name, true))

let opam_switches opam_root_name opam_root =
  let state = get_opam_env_state opam_root in
  OpamSwitch.Map.fold
    (fun switch compiler acc ->
       { opam_root_name;
         opam_root;
         opam_switch = Some switch;
         opam_env_state = Some { state with switch; compiler }
       } :: acc)
    state.aliases []

let switches root =
  match root.root_kind with
  | Opam_root opam_root ->
      List.map (fun x -> Opam_switch x)
      @@ opam_switches root.root_name opam_root

let equal r1 r2 = r1.root_name = r2.root_name
