object Graph {
  adj: List((u24, List(u24)))
}

def count_list_elements(list: List(Any)) -> u24:
  match list:
    case List/Nil:
      return 0
    case List/Cons:
      return 1 + count_list_elements(list.tail)


def count_vertices(g: Graph) -> u24:
  open Graph: g
  return count_list_elements(g.adj)


def list_contains(list: List(u24), element: u24) -> u24:
  match list:
    case List/Nil:
      return 0
    case List/Cons:
      if list.head == element:
        return 1
      else:
        return list_contains(list.tail, element)


def get_all_vertices(adj_list: List((u24, List(u24)))) -> List(u24):
  match adj_list:
    case List/Nil:
      return []
    case List/Cons:
      (vertex, _) = adj_list.head
      return List/Cons{head: vertex, tail: get_all_vertices(adj_list.tail)}


# // -----------------------------------------
# // Função para grafo completo
# // -----------------------------------------

def check_node_connectivity(all_vertices: List(u24), neighbors: List(u24), current_vertex: u24) -> u24:
  match all_vertices:
    case List/Nil:
      return 1
    case List/Cons:
      v = all_vertices.head
      if v == current_vertex:
        is_ok = (list_contains(neighbors, v) == 0)
      else:
        is_ok = (list_contains(neighbors, v) == 1)
      
      if is_ok:
        return check_node_connectivity(all_vertices.tail, neighbors, current_vertex)
      else:
        return 0


def check_all_nodes(adj_list: List((u24, List(u24))), all_vertices: List(u24), n: u24) -> u24:
  match adj_list:
    case List/Nil:
      return 1
    case List/Cons:
      (vertex, neighbors) = adj_list.head
      
      num_neighbors = count_list_elements(neighbors)
      if num_neighbors != n - 1:
        return 0
      else:
        is_connected_ok = check_node_connectivity(all_vertices, neighbors, vertex)
      
        if is_connected_ok == 0:
          return 0
        else:
          return check_all_nodes(adj_list.tail, all_vertices, n)


def is_complete(graph: Graph) -> u24:
  open Graph: graph

  n = count_vertices(graph)
  if n <= 1:
    return 1
  else:
    all_vertices = get_all_vertices(graph.adj)
    return check_all_nodes(graph.adj, all_vertices, n)

# // -----------------------------------------
# // Função zykov
# // -----------------------------------------




def main() -> (u24, u24):
  complete_graph = Graph {
    adj: [
      (0, [1, 2]),
      (1, [0, 2]),
      (2, [0, 1])
    ]
  }

  incomplete_graph = Graph {
    adj: [
      (0, [1]),
      (1, [0, 2]),
      (2, [1])
    ]
  }

  result1 = is_complete(complete_graph)
  result2 = is_complete(incomplete_graph)

  return (result1, result2)

