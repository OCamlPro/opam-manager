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

let opam_switch_name opam_switch =
  match opam_switch.opam_switch with
  | Some name -> name
  | None ->
      (* Lookup for the default switch in OPAM state. *)
      let state = ManagerRoot.get_opam_env_state opam_switch.opam_root in
      state.switch

let name = function
  | Opam_switch opam_switch ->
      OpamSwitch.to_string @@ opam_switch_name opam_switch

(* Interpret "switch string" such as "root_name:switch_name". *)
let find_switch config ?default name =
  match OpamStd.String.cut_at name ':' with
  | None -> begin
      let default =
        match default with
        | None -> ManagerRoot.default config
        | Some default -> default in
      match default with
      | { root_name; root_kind = Opam_root opam_root } ->
          let opam_switch =
            match name with
            | "" -> None
            | s -> Some (OpamSwitch.of_string s) in
          Opam_switch
            { opam_root_name = root_name ; opam_root ;
              opam_switch; opam_env_state = None ;
            }
    end
  | Some (root, switch) -> begin
      match ManagerRoot.from_name config root with
      | { root_name; root_kind = Opam_root opam_root } ->
          let opam_switch =
            match switch with
            | "" -> None
            | s -> Some (OpamSwitch.of_string switch) in
          Opam_switch
            { opam_root_name = root_name; opam_root;
              opam_switch; opam_env_state = None  }
    end

(** Find switch selected in argv *)

let find_arg s a =
  let len = Array.length a in
  let rec loop i =
    if i >= len then None else
    if Sys.argv.(i) = s then
      if i + 1 < len then Some (i+1, Sys.argv.(i+1)) else None
    else
      loop (i+1)
  in
  loop 0

let find_opam_root config name =
  match ManagerRoot.from_name config name with
  | { root_kind = Opam_root opam_root } as root ->
      (root, opam_root)
  | exception ManagerRoot.Unknown_root_name _ ->
      match ManagerRoot.from_path config (OpamFilename.Dir.of_string name) with
      | { root_kind = Opam_root opam_root } as root ->
          (root, opam_root)

let argv_opam_switch argv config =
  let argv_opamroot =
    OpamStd.Option.map
      (fun (pos, root) ->
         let root, opam_root = find_opam_root config root in
         argv.(pos) <-
           OpamFilename.Dir.to_string opam_root.opam_root_path;
         (root, opam_root) )
      (find_arg "--root" argv) in
  let argv_opamswitch =
    OpamStd.Option.map
      (fun (pos, opam_switch) ->
         try
           let default = OpamStd.Option.map fst argv_opamroot in
           match find_switch ?default config opam_switch with
           | Opam_switch switch ->
               argv.(pos) <-
                 OpamSwitch.to_string @@ opam_switch_name switch;
               switch
         with ManagerRoot.Unknown_root_name (name, default) ->
           fail "Unknown%s root name %S, in the --switch argument."
             (if default then " default" else "") name)
      (find_arg "--switch" argv) in
  match argv_opamroot, argv_opamswitch with
  | None, None -> None
  | None, Some opam_switch -> Some (Opam_switch opam_switch, `Argv)
  | Some (root, opam_root), (None as opam_switch) ->
      Some (Opam_switch
              { opam_root_name = root.root_name; opam_root;
                opam_switch; opam_env_state = None },
            `Argv)
  | Some (_, opam_root), (Some opam_switch) ->
      if opam_root.opam_root_path <> opam_switch.opam_root.opam_root_path then
        fail "Inconsistent OPAMROOT between the options --root and --switch.";
      Some (Opam_switch opam_switch, `Argv)

(** Find switch selected from the environment *)

let env_opam_switch config =
  let getenv name = try Some (Sys.getenv name) with Not_found -> None in
  let env_opamroot =
    OpamStd.Option.map (find_opam_root config) (getenv "OPAMROOT") in
  let env_opamswitch =
    OpamStd.Option.map
      (fun opam_switch ->
         try
           let default = OpamStd.Option.map fst env_opamroot in
           match find_switch ?default config opam_switch with
           | Opam_switch switch -> switch
         with ManagerRoot.Unknown_root_name (name, default) ->
           fail "Unknown%s root name %S, in OPAMSWITCH."
             (if default then " default" else "") name)
      (getenv "OPAMSWITCH") in
  match env_opamroot, env_opamswitch with
  | None, None -> None
  | None, Some opam_switch -> Some (Opam_switch opam_switch, `Env "OPAMSWITCH")
  | Some (root, opam_root), (None as opam_switch) ->
      Some (Opam_switch
              { opam_root_name = root.root_name; opam_root;
                opam_switch; opam_env_state = None },
            `Env "OPAMROOT")
  | Some (_, opam_root), (Some opam_switch) ->
      if opam_root.opam_root_path <> opam_switch.opam_root.opam_root_path then
        fail "Inconsistent option between OPAMROOT and OPAMSWITCH.";
      Some (Opam_switch opam_switch, `Env "OPAMSWITCH")

(** Find switch selected from a .opam-switch file *)

let find_up parse file =
  let rec iter dirname =
    let filename = Filename.concat dirname file in
    if Sys.file_exists filename then
      try parse filename
      with
      | OpamStd.Sys.Exit _ as e -> raise e
      | e ->
        warn "exception while parsing per-project files %s: %S. (ignoring file)"
          filename
          (Printexc.to_string e);
        None
    else
      let new_dirname = Filename.dirname dirname in
      if new_dirname = dirname then None else iter new_dirname
  in
  iter (Sys.getcwd ())

let file_opam_switch config =
  let parse_switch_file filename =
    match OpamProcess.read_lines filename with
    | exception Not_found -> None
    | exception exn ->
        fail "Can't read %S (%s)." filename (Printexc.to_string exn)
    | [] -> None
    | opam_switch :: _ ->
        try Some (find_switch config opam_switch, `File filename)
        with ManagerRoot.Unknown_root_name (name, default) ->
          fail "Unknown%s root name %S (while reading %s)"
            (if default then " default" else "") name filename in
  find_up parse_switch_file ".opam-switch"

(** Default switch *)

let default_opam_switch config =
  match
    ManagerRoot.from_path config (OpamStateConfig.opamroot ()) with
  | { root_name; root_kind = Opam_root opam_root } ->
      Opam_switch { opam_root_name = root_name; opam_root;
                    opam_switch = None; opam_env_state = None }


(** Current switch:

   - when [is_opam] is true and "--root" or "--switch" are found
     in [Sys.argv], use them as default.
   - if OPAMROOT and OPAMSWITCH are defined, use them;
   - if only OPAMROOT, use the 'default' switch of it;
   - if only OPAMSWITCH, look for it in the default 'root';
   - if neither OPAMROOT or OPAMSWITCH are defined:
     - look after an `.opam-switch` file;
     - otherwise, use the default 'switch' of the default 'root'.


 *)

let current ?argv config =
  let (||) f g x =
    match f x with
    | None -> g x
    | some -> some in
  let argv_opam_switch =
    match argv with
    | Some argv -> argv_opam_switch argv
    | None -> (fun _ -> None) in
  match (argv_opam_switch || env_opam_switch || file_opam_switch) config with
  | Some switch -> switch
  | None -> default_opam_switch config, `Default


let display_src src =
  match src with
  | `Env name ->
      info "switch selected from %s." name
  | `Argv ->
      info "switch selected from the command line arguments."
  | `File name ->
      info "switch selected from the file %S." name
  | `Default -> ()

(** Environment *)

let setup_minimal_env = function
  | Opam_switch { opam_root; opam_switch } ->
      Unix.putenv "OPAMROOT"
        (OpamFilename.Dir.to_string opam_root.opam_root_path);
      OpamStd.Option.iter
        (fun switch -> Unix.putenv "OPAMSWITCH" (OpamSwitch.to_string switch))
        opam_switch

let get_opam_env_state opam_switch =
  match opam_switch.opam_env_state with
  | Some state -> state
  | None ->
      let state = ManagerRoot.get_opam_env_state opam_switch.opam_root in
      let state =
        match opam_switch.opam_switch with
        | None -> state
        | Some switch -> OpamState.with_switch switch state in
      opam_switch.opam_env_state <- Some state;
      state

let is_valid = function
  | Opam_switch opam_switch ->
      try ignore(get_opam_env_state opam_switch); true
      with Not_found -> false

let setup_env = function
  | Opam_switch opam_switch ->
      let opam_state = get_opam_env_state opam_switch in
      let env = OpamState.get_opam_env ~force_path:false opam_state in
      List.iter (fun (n, v) -> Unix.putenv n v) env


(** Various accessors *)

let is_opam_system_switch = function
  | Opam_switch opam_switch ->
      let opam_state = get_opam_env_state opam_switch in
      opam_state.compiler = OpamCompiler.of_string "system"

let bin_dir = function
  | Opam_switch opam_switch ->
      let switch_name = opam_switch_name opam_switch in
      OpamPath.Switch.Default.bin opam_switch.opam_root.opam_root_path switch_name

let all config =
  List.concat @@
  List.map ManagerRoot.switches config.known_roots

let root = function
  | Opam_switch { opam_root_name; opam_root } ->
      { root_name = opam_root_name;
        root_kind = Opam_root opam_root }

let equal s1 s2 =
  match s1, s2 with
  | Opam_switch s1, Opam_switch s2 ->
      s1.opam_root.opam_root_path = s2.opam_root.opam_root_path &&
      opam_switch_name s1 = opam_switch_name s2

let compare s1 s2 =
  match s1, s2 with
  | Opam_switch s1, Opam_switch s2 ->
      let x =
        compare s1.opam_root.opam_root_path s2.opam_root.opam_root_path in
      if x <> 0 then x else compare (opam_switch_name s1) (opam_switch_name s2)
