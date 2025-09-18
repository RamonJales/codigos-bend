# Arquivo: tsp_bruteforce_corrigido.bend

# Representa uma cidade com coordenadas 2D, conforme descrito no artigo[cite: 63].
object City { x: f24, y: f24 }

# Armazena o melhor resultado encontrado e seu custo.
object BestResult {
  cost: f24,
  route: List(u24)
}

# Funções auxiliares para manipulação de Listas (Cons/Nil)
# A biblioteca padrão do Bend é mínima, então precisamos definir essas funções.

# Pega o elemento em um determinado índice de uma lista.
def List/get(idx: u24, list: List(Any)) -> Any:
  match list:
    case List/Cons:
      if idx == 0:
        return list.head
      else:
        return List/get(idx - 1, list.tail)
    case List/Nil:
      # Retornar um valor padrão ou erro; aqui retornamos 0 para simplicidade.
      return 0

# Remove o elemento em um determinado índice de uma lista.
def List/remove_at(idx: u24, list: List(Any)) -> List(Any):
  match list:
    case List/Cons:
      if idx == 0:
        return list.tail
      else:
        return List/Cons(list.head, List/remove_at(idx - 1, list.tail))
    case List/Nil:
      return []

# Obtém o último elemento de uma lista.
def List/last(list: List(Any)) -> Any:
  match list:
    case List/Cons:
      if list.tail == List/Nil:
        return list.head
      else:
        return List/last(list.tail)
    case List/Nil:
      return 0

# Calcula a distância euclidiana entre duas cidades[cite: 67, 69].
def city_distance(a: City, b: City) -> f24:
  open City: a
  open City: b
  dx = b.x - a.x
  dy = b.y - a.y
  return (dx * dx + dy * dy) ** 0.5

# CORRIGIDO: Constrói a matriz de distâncias de forma eficiente usando recursão.
def build_dist_matrix(cities: List(City), num_cities: u24) -> List(List(f24)):
  def build_row(city1: City, remaining_cities: List(City)):
    match remaining_cities:
      case List/Cons:
        dist = city_distance(city1, remaining_cities.head)
        return List/Cons(dist, build_row(city1, remaining_cities.tail))
      case List/Nil:
        return []

  def build_all_rows(cities_to_process: List(City)):
    match cities_to_process:
      case List/Cons:
        row = build_row(cities_to_process.head, cities)
        return List/Cons(row, build_all_rows(cities_to_process.tail))
      case List/Nil:
        return []

  return build_all_rows(cities)

# CORRIGIDO: Calcula o custo de uma rota usando recursão, que é mais idiomático.
# O algoritmo está descrito em "Algorithm 2" do artigo[cite: 82].
def calculate_route_cost(route: List(u24), dist_matrix: List(List(f24))) -> f24:
  # Adiciona a distância da última cidade de volta para a primeira
  first_city_idx = route.head
  last_city_idx = List/last(route)
  
  matrix_row = List/get(last_city_idx, dist_matrix)
  return_dist = List/get(first_city_idx, matrix_row)

  # Usa recursão para somar as distâncias do caminho
  def sum_path(current_route: List(u24)):
    match current_route.tail:
      case List/Nil: # Fim da rota
        return 0.0
      case _:
        city1_idx = current_route.head
        city2_idx = current_route.tail.head
        
        row = List/get(city1_idx, dist_matrix)
        dist = List/get(city2_idx, row)
        
        return dist + sum_path(current_route.tail)

  return sum_path(route) + return_dist

# Função auxiliar para calcular o fatorial.
def factorial(n: u24) -> u24:
  if n == 0:
    return 1
  else:
    return n * factorial(n - 1)

# CORRIGIDO: Gera a k-ésima permutação usando as funções auxiliares de lista.
# Este é o núcleo do algoritmo de geração lexicográfica que permite o paralelismo[cite: 102, 132].
def get_kth_permutation(k: u24, elements: List(u24), n: u24) -> List(u24):
  if n == 0:
    return []
  else:
    fact = factorial(n - 1)
    index = k / fact
    new_k = k % fact
    
    elem_at_index = List/get(index, elements)
    remaining_elements = List/remove_at(index, elements)
    
    perm_tail = get_kth_permutation(new_k, remaining_elements, n - 1)
    return List/Cons(elem_at_index, perm_tail)

# O trabalho realizado por uma única "thread", correspondente ao "Algorithm 6" do artigo[cite: 143].
# A estrutura de 'bend' para emular um loop sequencial está correta.
def find_local_best(task_id: u24, routes_per_task: u24, initial_elements: List(u24), dist_matrix: List(List(f24)), num_cities: u24) -> BestResult:
  start_k = task_id * routes_per_task
  end_k = start_k + routes_per_task
  
  # Usa um número muito grande para representar infinito.
  initial_best = BestResult { cost: 9999999.0, route: [] }

  bend k = start_k, best_result = initial_best:
    when k < end_k:
      current_perm = get_kth_permutation(k, initial_elements, num_cities)
      current_cost = calculate_route_cost(current_perm, dist_matrix)

      if current_cost < best_result.cost:
        new_best = BestResult { cost: current_cost, route: current_perm }
        result = fork(k + 1, new_best)
      else:
        result = fork(k + 1, best_result)
    else:
      result = best_result
      
  return result

# Função auxiliar para criar uma lista de números em um intervalo.
def list_range(start: u24, end: u24) -> List(u24):
  if start < end:
    return List/Cons(start, list_range(start + 1, end))
  else:
    return []


# Função principal que orquestra a execução paralela.
def main() -> BestResult:
  # Definindo as cidades como no exemplo do artigo.
  cities = [
    City {x: 325.0, y: 492.0}, # 0
    City {x: 552.0, y: 890.0}, # 1
    City {x: 878.0, y: 1204.0}, # 2
    City {x: 400.0, y: 600.0}, # 3
    City {x: 950.0, y: 1100.0}  # 4
  ]
  NUM_CITIES = 5
  # Profundidade da árvore de paralelismo. Cria 2^N tarefas.
  PARALLELISM_DEPTH = 4 
  NUM_TASKS = 2 ** PARALLELISM_DEPTH
  TOTAL_ROUTES = factorial(NUM_CITIES - 1) # (n-1)! rotas distintas
  ROUTES_PER_TASK = TOTAL_ROUTES / NUM_TASKS

  dist_matrix = build_dist_matrix(cities, NUM_CITIES)
  initial_elements = list_range(1, NUM_CITIES) # Permutações de 1 a N-1, 0 é fixo

  # 1. DIVIDIR: A declaração 'bend' define a variável 'tree_of_results'.
  bend d = 0, i = 0:
    when d < PARALLELISM_DEPTH:
      tree_of_results = ![fork(d + 1, i * 2 + 0), fork(d + 1, i * 2 + 1)]
    else:
      local_perms_task = find_local_best(i, ROUTES_PER_TASK, initial_elements, dist_matrix, NUM_CITIES - 1)
      fixed_route = List/Cons(0, local_perms_task.route)
      tree_of_results = !BestResult { cost: local_perms_task.cost, route: fixed_route }

  # 2. CONQUISTAR: 'fold' é a última DECLARAÇÃO da função.
  #    NÃO há 'return' antes dele. Os 'return's estão DENTRO de cada 'case'.
  fold tree_of_results:
    case Tree/Node:
      if tree_of_results.left.cost < tree_of_results.right.cost:
        return tree_of_results.left
      else:
        return tree_of_results.right
    case Tree/Leaf:
      return tree_of_results.value