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

(** Read the config file or create the initial one. *)

let config, first_run =
  match ManagerConfig.load () with
  | None ->
      info "Initialising opam-manager!";
      let default_root_name = "default" in
      let default_root =
        ManagerRoot.create_opam_root
          default_root_name
          (OpamStateConfig.opamroot ()) in
      let initial_config = {
        manager_version = ManagerVersion.current;
        default_root_name;
        known_roots = [default_root];
        wrapper_binary = ManagerPath.default_wrapper_binary;
      } in
      OpamFilename.mkdir ManagerPath.defaults_dir;
      OpamFilename.mkdir ManagerPath.bin_dir;
      ManagerConfig.write initial_config;
      (initial_config, true)
  | Some config -> (config, false)


(** Create wrapper and configure default binary for 'man' and 'opam'. *)

let check_external_wrapper name =
  let base = OpamFilename.Base.of_string name in
  match ManagerDefault.find config base with
  | Some _ -> ()
  | None ->
      try
        info "Creating wrapper for the external binary %S." name;
        ManagerDefault.create_absolute base;
        ManagerWrapper.create config base
      with Not_found -> warn "Can't locate %S in PATH." name

let () =
  if first_run then begin
    check_external_wrapper "opam";
    check_external_wrapper "man"
  end


(** Create or remove wrappers to match the binaries found in all known
    switches. *)

let () =
  ManagerWrapper.update ~check_symlink:true ~verbose:true config
