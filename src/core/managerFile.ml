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

open OpamStd.Op
open OpamTypes
open OpamTypesBase
open ManagerTypes

module Pp = OpamFormat.Pp
open Pp.Op

module ConfigSyntax = struct

  let internal = "manager/global_config"

  type t = ManagerTypes.config

  let manager_version t = t.manager_version
  let known_roots t = t.known_roots
  let default_root_name t = t.default_root_name
  let wrapper_binary t = t.wrapper_binary

  let with_manager_version manager_version t = { t with manager_version }
  let with_known_roots known_roots t = { t with known_roots }
  let with_default_root_name default_root_name t = { t with default_root_name }
  let with_wrapper_binary wrapper_binary t = { t with wrapper_binary }

  let s_manager_version = "opam-manager-version"
  let s_known_roots = "known-roots"
  let s_default_root_name = "default-root"
  let s_wrapper_binary = "wrapper-binary"

  let empty = {
    manager_version = ManagerVersion.current;
    default_root_name = "**unconfigured**";
    known_roots = [];
    wrapper_binary = OpamFilename.of_string "/unconfigured";
  }

  let valid_fields = [
    s_manager_version;
    s_default_root_name;
    s_known_roots;
  ]

  let pp_known_root :
    (OpamTypes.value, ManagerTypes.root) Pp.t =
    Pp.V.map_pair
      Pp.V.string
      (Pp.V.string -|
       Pp.of_module "directory"
         (module OpamFilename.Dir: Pp.STR with type t = OpamFilename.Dir.t)) -|
    Pp.of_pair
      "known_root"
      ((fun (root_name, root_path) ->
         ManagerRoot.create_opam_root root_name root_path),
       (fun { root_name; root_kind = Opam_root { opam_root_path }} ->
          (root_name, opam_root_path)))
  let pp_known_roots :
    (OpamTypes.value, ManagerTypes.root list) Pp.t =
    Pp.V.map_list ~depth:2 pp_known_root

  let fields =
    [
      "opam-manager-version", Pp.ppacc
        with_manager_version manager_version
        (Pp.V.string -|
         Pp.of_module "opam-manager-version"
           (module ManagerVersion)) ;
      "default-root", Pp.ppacc
        with_default_root_name default_root_name
        Pp.V.string ;
      "known-root", Pp.ppacc
        with_known_roots known_roots
        pp_known_roots ;
      "wrapper-binary", Pp.ppacc
        with_wrapper_binary wrapper_binary
        (Pp.V.string -|
         Pp.of_module "file"
           (module OpamFilename: Pp.STR with type t = OpamFilename.t))
    ]

  let pp =
    let name = internal in
    ( Pp.I.map_file
      @@ Pp.I.check_fields ~name fields
         -| Pp.I.fields ~name ~empty fields )
    -| Pp.pp (fun ~pos:_ (a, b) -> (OpamFile.make a, b))
             (fun (a, b) -> (OpamFile.filename a, b))

    (* -| *)
    (* Pp.check ~name (fun t -> t.switch <> empty.switch) *)
      (* ~errmsg:"missing switch" *)

end

module Config = struct
  include ConfigSyntax
  include OpamFile.SyntaxFile(ConfigSyntax)
end

(*
module Root_config_base = struct

  let internal = "manager/root_config"

  type t = ManagerTypes.root_config

  let s_manager_version = "opam-manager-version"
  let s_manager_dir = "manager-dir"

  let empty = {
    manager_dir = OpamFilename.Dir.of_string "**unconfigured**";
  }

  let valid_fields = [
    s_manager_version;
    s_manager_dir;
  ]

  let of_channel filename ic =
    let s = OpamFile.Syntax.of_channel filename ic in
    let _permissive = OpamFile.Syntax.check s valid_fields in
    let _manager_version =
      OpamFormat.assoc s.file_contents s_manager_version
        parse_version in
    let manager_dir =
      OpamFormat.assoc s.file_contents s_manager_dir parse_dir in
    { manager_dir;
    }

  let to_string filename t =
    let variables =
      [ ( s_manager_version, make_version ManagerVersion.current ) ;
        ( s_manager_dir, make_dir t.manager_dir ); ] in
    OpamFile.Syntax.to_string {
      file_format   = OpamVersion.current;
      file_name     = OpamFilename.to_string filename;
      file_contents = List.map OpamFormat.make_variable variables;
    }

end

module Root_config = struct
  include Root_config_base
  include OpamFile.Make(Root_config_base)
end
*)
