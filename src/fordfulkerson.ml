open Graph
open Tools
open Printf

type flow = int

type capa = int

type vsarc = (flow * capa * bool)

type path = (id * id * vsarc) list

type ff_graph = vsarc graph


let graphe_ecart gr = gmap gr (fun (flow, capa) -> capa-flow)

let write_file_path file_path pth flow = match pth with
    | Some path ->
        let ff = open_out file_path in
            List.iter (fun (id1, id2, (flowloc, capa, _))-> fprintf ff "%d ---(%d/%d)---> %d, " id1 flowloc capa id2) path;
            fprintf ff "\n\nFlow total = %d\n" flow;
            close_out ff;
            ()
    | None -> 
        let ff = open_out file_path in
            fprintf ff "\nNo path found.\n";
            close_out ff;
            ()

let print_path path = List.iter (fun (id1, id2, (flowloc, capa, r))-> Printf.printf "%d ---(%d/%d)---> %d, " id1 flowloc capa id2) path; Printf.printf "\n"
    
let drop_zeros gr = e_fold gr (fun tgr id1 id2 (x,y,r)-> if x = 0 then tgr else new_arc tgr id1 id2 (x,y,r)) (clone_nodes gr)

(* Take a int graph and return a ff graph *)
let init_f_graph gr = gmap gr (fun x -> (0,x,false))

(* Return path's flow *)
let path_flow = function 
    | Some pth ->    List.fold_left (fun x (_,_,(flow,_,_))-> x + flow) 0 pth
    | None -> -1

let path_capa = function 
    | Some pth ->    List.fold_left (fun x (_,_,(_,capa,_))-> x + capa) 0 pth
    | None -> -1

let rec flow_min path = match path with
    | [] -> max_int
    | (src, dst, (f,c,_))::rest -> if c < (flow_min rest) then c else (flow_min rest)


(* Find and return a path between two node. Return None if all path are null *)
(* TODO : Ajouter une condition d'arrêt et retourner liste node *)
let rec find_path ffgr src dst marked = 
    let arcs_sortants = out_arcs ffgr src in
    let rec explore arc_list = match arc_list with
        | [] -> None
        | (d, (f, c, r))::_ when dst = d && c > 0 -> Some [(src, dst, (f, c, r))]
        | (id, (f, c, r))::rest ->
            let path = if (c > 0 && not (List.exists (fun x -> x = id) marked)) 
                        then find_path ffgr id dst (id::marked) 
                        else None 
            in
            match path with
                | None -> explore rest
                | Some p -> Some ((src, id, (f, c, r))::p)
    in
    explore arcs_sortants


(* Remove flow (int)from for each arc in path for ffgr *)
let rec update_capa ffgr path flow = match path with
    | [] -> ffgr
    |((id1,id2,(f, c, r))::tail) -> update_capa (add_vsarc ffgr id1 id2 (flow,-flow, r)) tail flow

    

(* 
    Ford Fulkerson steps:
        Init:
            fl <- Null
        While Exist(Path / flow(Path) != 0) do
            d = min(flow(path.arc[*]))
            for all arc in path do
                fl <- arc(d*sens)
*)


let ford_fulkerson gr src dst =
    let ffgr = init_f_graph gr in
    let rec update_gr ffgr = 
    match find_path ffgr src dst [] with
        | None -> ffgr
        | Some p -> print_path p; Printf.printf "\nFlow min %d\n" (flow_min p); update_gr (update_capa ffgr p (flow_min p))(* CRÉER UNE FONCTION UPDATE_GRAPH PATH *)
    in
    e_fold (gmap (update_gr ffgr) (fun (c,f, r)->(c,c+f, r))) (fun grf id1 id2 (f,c,r)->if r then grf else new_arc grf id1 id2 (f,c,r)) (clone_nodes gr)



let test_ff gr src dst = let path = find_path (init_f_graph gr) 0 5 [] in
    write_file_path "./outfile_ff" path (path_capa path)


