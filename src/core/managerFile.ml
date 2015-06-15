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

let parse_filename = OpamFormat.parse_string @> OpamFilename.of_string
let make_filename = OpamFilename.to_string @> OpamFormat.make_string

let parse_dir = OpamFormat.parse_string @> OpamFilename.Dir.of_string
let make_dir = OpamFilename.Dir.to_string @> OpamFormat.make_string

let make_version = OpamVersion.to_string @> OpamFormat.make_string
let parse_version = OpamFormat.parse_string @> OpamVersion.of_string

let parse_root =
  OpamFormat.(parse_pair parse_string parse_dir) @>
  (fun (root_name, opam_root_path) ->
     ManagerRoot.create_opam_root root_name opam_root_path)

let make_root =
  (fun { root_name; root_kind = Opam_root { opam_root_path } } ->
     (root_name, opam_root_path)) @>
  OpamFormat.(make_pair make_string make_dir)

module Config_base = struct

  let internal = "manager/global_config"

  type t = ManagerTypes.config

  let s_manager_version = "opam-manager-version"
  let s_known_roots = "known-roots"
  let s_default_root_name = "default-root"
  let s_wrapper_binary = "wrapper-binary"

  let empty = {
    default_root_name = "**unconfigured**";
    known_roots = [];
    wrapper_binary = OpamFilename.of_string "/unconfigured";
  }

  let valid_fields = [
    s_manager_version;
    s_default_root_name;
    s_known_roots;
  ]

  let of_channel filename ic =
    let s = OpamFile.Syntax.of_channel filename ic in
    let _permissive = OpamFile.Syntax.check s valid_fields in
    let _manager_version =
      OpamFormat.assoc s.file_contents s_manager_version
        parse_version in
    let default_root_name =
      OpamFormat.assoc s.file_contents s_default_root_name
        OpamFormat.parse_string in
    let known_roots =
      OpamFormat.assoc_list
        s.file_contents s_known_roots
        OpamFormat.(parse_list_list parse_root) in
    let wrapper_binary =
      OpamFormat.assoc s.file_contents s_wrapper_binary parse_filename in
    { default_root_name;
      known_roots;
      wrapper_binary;
    }

  let to_string filename t =
    let variables =
      [ ( s_manager_version, make_version ManagerVersion.current ) ;
        ( s_default_root_name,
          OpamFormat.make_string t.default_root_name );
        ( s_known_roots,
          OpamFormat.(make_list make_root)
            t.known_roots);
        ( s_wrapper_binary, make_filename t.wrapper_binary );
      ] in
    OpamFile.Syntax.to_string {
      file_format   = OpamVersion.current;
      file_name     = OpamFilename.to_string filename;
      file_contents = List.map OpamFormat.make_variable variables;
    }

end

module Config = struct
  include Config_base
  include OpamFile.Make(Config_base)
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
