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

(** First-run initialization. *)

let first_run = not (OpamFilename.exists_dir ManagerPath.base_dir)

let () =
  if first_run then begin
    try
      info "Initialising opam-manager !" ;
      let check_external_wrapper name =
        let base = OpamFilename.Base.of_string name in
        try
          info "Creating wrapper for the external binary %S." name ;
          ManagerDefault.create_absolute base ;
          ManagerWrapper.create base
        with Not_found -> warn "Can't locate %S in PATH." name in
      OpamFilename.mkdir ManagerPath.defaults_dir ;
      OpamFilename.mkdir ManagerPath.bin_dir ;
      check_external_wrapper "opam" ;
      check_external_wrapper "man" ;
      check_external_wrapper "which" ;
      let manager = OpamFilename.Base.of_string "opam-manager" in
      ManagerDefault.create manager
        (ManagerDefault.Absolute (OpamFilename.of_string Sys.executable_name)) ;
      ManagerWrapper.create manager ;
    with e ->
      OpamFilename.rmdir_cleanup ManagerPath.base_dir ;
      raise e
  end

let () =
  OpamFilename.copy
    ~src:ManagerPath.default_wrapper_binary
    ~dst:ManagerPath.wrapper_binary

(** Create or remove wrappers to match the binaries found in all known
    switches. *)

let () =
  ManagerWrapper.update ~check_symlink:true ~verbose:true ()

let () =
  if not (ManagerPath.is_path_uptodate ()) then
    info "You may now add \"%s\" to your PATH."
      (OpamFilename.Dir.to_string ManagerPath.bin_dir)
