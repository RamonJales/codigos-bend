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


def list_remove_items(list: List(u24), to_remove: List(u24)) -> List(u24):
  match list:
    case List/Nil: 
      return []
    case List/Cons:
      tail_filtered = list_remove_items(list.tail, to_remove)
      if list_contains(to_remove, list.head) == 1:
        return tail_filtered
      else:
        return List/Cons{head: list.head, tail: tail_filtered}


# // -----------------------------------------
# // Função para grafo
# // -----------------------------------------

def get_neighbors(adj_list: List((u24, List(u24))), vertex: u24) -> List(u24):
  match adj_list:
    case List/Nil: 
      return []
    case List/Cons:
      (v, neighbors) = adj_list.head
      if v == vertex:
        return neighbors
      else:
        return get_neighbors(adj_list.tail, vertex)


def get_degree(adj_list: List((u24, List(u24))), vertex: u24) -> u24:
  return count_list_elements(get_neighbors(adj_list, vertex))


def find_vertex_with_max_degree(adj_list: List((u24, List(u24)))) -> u24:
  # A função auxiliar 'find_max' está correta e não precisa de mudanças.
  def find_max(list: List((u24, List(u24))), current_max_v: u24, current_max_d: u24) -> u24:
    match list:
      case List/Nil: 
        return current_max_v
      case List/Cons:
        (v, neighbors) = list.head
        degree = count_list_elements(neighbors)
        if degree > current_max_d:
          return find_max(list.tail, v, degree)
        else:
          return find_max(list.tail, current_max_v, current_max_d)

  match adj_list:
    case List/Nil:
      return 0
    case List/Cons:
      # ...podemos acessar .head e .tail com segurança para iniciar a busca.
      (initial_v, initial_neighbors) = adj_list.head
      initial_degree = count_list_elements(initial_neighbors)
      # Inicia a busca a partir do segundo elemento da lista.
      return find_max(adj_list.tail, initial_v, initial_degree)


def remove_vertices(graph: Graph, to_remove: List(u24)) -> Graph:
  open Graph: graph
  # Filtra a lista de adjacência para remover os vértices principais.
  def filter_adj(adj: List((u24, List(u24)))) -> List((u24, List(u24))):
    match adj:
      case List/Nil: 
        return []
      case List/Cons:
        (v, neighbors) = adj.head
        tail_filtered = filter_adj(adj.tail)
        if list_contains(to_remove, v) == 1:
          return tail_filtered
        else:
          # Filtra também as listas de vizinhos.
          new_neighbors = list_remove_items(neighbors, to_remove)
          return List/Cons{head: (v, new_neighbors), tail: tail_filtered}
  return Graph{adj: filter_adj(graph.adj)}


# // -----------------------------------------
# // Função para RLF
# // -----------------------------------------

def find_best_next_in_list(adj: List((u24, List(u24))), candidates: List(u24), current_set: List(u24)) -> (u24, u24):
  
  # Função interna para calcular o score de um vértice
  def get_score(candidate: u24) -> u24:
    candidate_neighbors = get_neighbors(adj, candidate)
    def count_adj_to_set(c_neighbors: List(u24)) -> u24:
      match c_neighbors:
        case List/Nil: 
          return 0
        case List/Cons:
          is_in_set = list_contains(current_set, c_neighbors.head)
          return is_in_set + count_adj_to_set(c_neighbors.tail)
    return count_adj_to_set(candidate_neighbors)

  # A lógica recursiva principal para encontrar o máximo
  match candidates:
    # Caso base: sem candidatos, sem melhor vértice. Retornamos (0, -1) como sentinela.
    case List/Nil:
      return (0, 0) # (vértice, score) - usando score 0 como "não encontrado"
    case List/Cons:
      # Pega o primeiro candidato e seu score como a melhor opção inicial
      head_v = candidates.head
      head_score = get_score(head_v)

      # Encontra o melhor candidato no resto da lista
      (best_in_tail_v, best_in_tail_score) = find_best_next_in_list(adj, candidates.tail, current_set)

      # Compara o head com o melhor do resto da lista
      if head_score >= best_in_tail_score:
        return (head_v, head_score)
      else:
        return (best_in_tail_v, best_in_tail_score)


def build_independent_set(adj: List((u24, List(u24))), candidates: List(u24), current_set: List(u24)) -> List(u24):
  # Se não houver mais candidatos, o conjunto está pronto.
  if count_list_elements(candidates) == 0:
    return current_set
  else:
    (best_next, best_score) = find_best_next_in_list(adj, candidates, current_set)

    # Caso base: não há mais candidatos válidos para adicionar.
    # Se o score for 0 e o vértice for 0, pode ser nosso sentinela de "não encontrado".
    # Uma verificação mais robusta é necessária, mas vamos assumir que se ele retorna um 
    # candidato, ele é válido para ser adicionado.
    
    # Vamos simplificar: se find_best_next_in_list retorna um (v, score), pegamos v.
    # Se a lista de candidatos estava vazia, ele retorna (0,0) e a função principal para.
    
    new_set = List/Cons{head: best_next, tail: current_set}
    best_next_neighbors = get_neighbors(adj, best_next)
    
    # Remove o vértice adicionado e seus vizinhos dos candidatos.
    to_remove_from_candidates = List/Cons{head: best_next, tail: best_next_neighbors}
    new_candidates = list_remove_items(candidates, to_remove_from_candidates)
    
    return build_independent_set(adj, new_candidates, new_set)


def rlf(graph: Graph) -> List(List(u24)):
  open Graph: graph
  
  # Caso base: se o grafo está vazio, não há mais cores para atribuir.
  if count_list_elements(graph.adj) == 0:
    return []
  else:
    # Passo 1: Encontra o vértice "semente" (maior grau).
    seed_vertex = find_vertex_with_max_degree(graph.adj)

    # Passo 2: Constrói o conjunto independente maximal (a classe de cor).
    initial_set = [seed_vertex]
    seed_neighbors = get_neighbors(graph.adj, seed_vertex)
    all_vertices = get_all_vertices(graph.adj)
    # Candidatos são todos os vértices menos a semente e seus vizinhos.
    to_remove_from_candidates = List/Cons{head: seed_vertex, tail: seed_neighbors}
    initial_candidates = list_remove_items(all_vertices, to_remove_from_candidates)
    
    color_class = build_independent_set(graph.adj, initial_candidates, initial_set)
    
    # Passo 3: Remove os vértices coloridos do grafo.
    remaining_graph = remove_vertices(graph, color_class)

    # Passo 4: Chamada recursiva com o grafo restante.
    remaining_colors = rlf(remaining_graph)
    
    # Retorna a cor atual mais as cores encontradas na recursão.
    return List/Cons{head: color_class, tail: remaining_colors}


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


def main() -> (u24, u24, u24, u24):
  # Teste 1: Grafo Completo K4 (4 vértices, todos conectados)
  # Esperado: 4 cores
  k4_graph = Graph {
    adj: [
      (0, [1, 2, 3]),
      (1, [0, 2, 3]),
      (2, [0, 1, 3]),
      (3, [0, 1, 2])
    ]
  }

  # Teste 2: Grafo Ciclo C5 (pentágono)
  # Esperado: 3 cores
  c5_graph = Graph {
    adj: [
      (0, [1, 4]),
      (1, [0, 2]),
      (2, [1, 3]),
      (3, [2, 4]),
      (4, [3, 0])
    ]
  }

  # Teste 3: Grafo Caminho P5 (bipartido)
  # 0 -- 1 -- 2 -- 3 -- 4
  # Esperado: 2 cores
  p5_graph = Graph {
    adj: [
      (0, [1]),
      (1, [0, 2]),
      (2, [1, 3]),
      (3, [2, 4]),
      (4, [3])
    ]
  }

  # Teste 4: Grafo Roda W5 (hub central '0', ciclo externo 1-2-3-4)
  # Esperado: 3 cores
  w5_graph = Graph {
    adj: [
      (0, [1, 2, 3, 4]), # Hub
      (1, [0, 2, 4]),     # Ciclo externo
      (2, [0, 1, 3]),
      (3, [0, 2, 4]),
      (4, [0, 1, 3])
    ]
  }

  # Executa o RLF em cada grafo
  k4_colors_list = rlf(k4_graph)
  c5_colors_list = rlf(c5_graph)
  p5_colors_list = rlf(p5_graph)
  w5_colors_list = rlf(w5_graph)

  # Conta o número de cores (o tamanho da lista de listas) para cada resultado
  k4_num_colors = count_list_elements(k4_colors_list)
  c5_num_colors = count_list_elements(c5_colors_list)
  p5_num_colors = count_list_elements(p5_colors_list)
  w5_num_colors = count_list_elements(w5_colors_list)

  # Retorna uma tupla com a contagem de cores para cada teste
  return (k4_num_colors, c5_num_colors, p5_num_colors, w5_num_colors)


