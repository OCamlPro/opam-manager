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

let get_opam_root_config opam_root =
  match opam_root.opam_root_config with
  | Some config -> config
  | None ->
      match OpamFile.Config.read (OpamPath.config opam_root.opam_root_path) with
      | exception exn ->
          fail "Invalid OPAMROOT : %S.\n%s"
            (OpamFilename.Dir.to_string opam_root.opam_root_path)
            (Printexc.to_string exn)
      | config ->
          opam_root.opam_root_config <- Some config;
          config

let get_opam_root_aliases opam_root =
  match opam_root.opam_root_aliases with
  | Some aliases -> aliases
  | None ->
      match OpamFile.Aliases.read (OpamPath.aliases opam_root.opam_root_path) with
      | exception exn ->
          fail "Invalid OPAMROOT : %S.\n%s"
            (OpamFilename.Dir.to_string opam_root.opam_root_path)
            (Printexc.to_string exn)
      | aliases ->
          opam_root.opam_root_aliases <- Some aliases;
          aliases


let get_opam_default_switch opam_root =
  (* Lookup for the default switch in OPAM config. *)
  let config = get_opam_root_config opam_root in
  OpamFile.Config.switch config

let create_opam_root root_name opam_root_path =
  { root_name ;
    root_kind =
      Opam_root
        { opam_root_path ;
          opam_root_config = None ;
          opam_root_aliases = None ;
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
  let aliases = get_opam_root_aliases opam_root in
  OpamSwitch.Map.fold
    (fun switch compiler acc ->
       { opam_root_name;
         opam_root;
         opam_switch = switch;
         opam_switch_config = None;
         opam_switch_env = None;
       } :: acc)
    aliases []

let switches root =
  match root.root_kind with
  | Opam_root opam_root ->
      List.map (fun x -> Opam_switch x)
      @@ opam_switches root.root_name opam_root

let equal r1 r2 = r1.root_name = r2.root_name
