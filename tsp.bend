# -----------------------------------------
# Estruturas de Dados e Constantes
# -----------------------------------------

# Define uma cidade com coordenadas x, y.
object City { x, y }

# O número de cidades para o problema. O cálculo é para (N-1)! permutações.
# NOTA: Valores acima de 12 levam muito tempo. O artigo mostra que para 15 cidades,
# a execução sequencial leva mais de 2000 segundos[cite: 203].
def NUM_CITIES():
  return 8

# A profundidade da árvore de paralelismo. O número de tarefas paralelas será 2^DEPTH.
# Uma profundidade de 10 cria 1024 tarefas paralelas.
def PARALLELISM_DEPTH():
  return 10

def distance(c1: City, c2: City) -> f24:
  open City: c1
  open City: c2
  dx = c2.x - c1.x
  dy = c2.y - c1.y
  return (dx * dx + dy * dy) ** 0.5

def distances_from_one(city1: City, all_cities: List(City)) -> List(f24):
  match all_cities:
    case List/Nil:
      return []
    case List/Cons:
      head_dist = distance(city1, all_cities.head)
      tail_dists = distances_from_one(city1, all_cities.tail)
      return List/Cons{head: head_dist, tail: tail_dists}

# --- VERSÃO CORRIGIDA ---
def get_distance_matrix(cities: List(City)) -> List(List(f24)):
  
  # Helper recursivo que passa a lista original explicitamente.
  def build_matrix_helper(cities_to_process: List(City), original_cities: List(City)) -> List(List(f24)):
    match cities_to_process:
      case List/Nil:
        return []
      case List/Cons:
        # Calcula a linha usando a lista original completa.
        current_row = distances_from_one(cities_to_process.head, original_cities)
        
        # A chamada recursiva continua com a cauda da lista a ser processada,
        # mas ainda passa a lista original inalterada.
        remaining_matrix = build_matrix_helper(cities_to_process.tail, original_cities)
        
        return List/Cons{head: current_row, tail: remaining_matrix}

  # Inicia a recursão passando a lista de cidades para ambos os parâmetros.
  return build_matrix_helper(cities, cities)


# Acessa um valor em uma matriz (lista de listas)
# Acessa um valor em uma matriz (lista de listas) usando 'match'.
def get_matrix_val(matrix: List(List(f24)), row: u24, col: u24) -> f24:
  match matrix:
    # Caso base: se a matriz estiver vazia, não há como encontrar a linha.
    case List/Nil:
      return -1.0 # Retorna um valor inválido para indicar erro.
    
    # Caso recursivo: a matriz tem pelo menos uma linha.
    case List/Cons:
      if row == 0:
        # Encontramos a linha correta (matrix.head). Agora, buscamos a coluna.
        def get_col(list_row: List(f24), c: u24) -> f24:
          match list_row:
            # Caso base: a linha é mais curta que o índice da coluna.
            case List/Nil:
              return -1.0 # Retorna um valor inválido.
            
            # Caso recursivo: a linha tem pelo menos um elemento.
            case List/Cons:
              if c == 0:
                # Encontramos o elemento correto.
                return list_row.head
              else:
                # Continua a busca na cauda da linha.
                return get_col(list_row.tail, c - 1)
        
        return get_col(matrix.head, col)
      else:
        # Continua a busca pela linha na cauda da matriz.
        return get_matrix_val(matrix.tail, row - 1, col)


def calculate_route_cost(route: List(u24), dist_matrix: List(List(f24))) -> f24:
  match route:
    case List/Nil:
      return 0.0
    case List/Cons:
      # Se houver mais de uma cidade na rota restante
      match route.tail:
        case List/Cons:
          from_city = route.head
          to_city = route.tail.head
          dist = get_matrix_val(dist_matrix, from_city, to_city)
          return dist + calculate_route_cost(route.tail, dist_matrix)
        # Se for a última cidade, calcula o retorno à cidade inicial (cidade 0)
        case List/Nil:
          from_city = route.head
          to_city = 0 # Retorna ao início
          return get_matrix_val(dist_matrix, from_city, to_city)


def factorial(n: u24) -> u24:
  if n == 0:
    return 1
  else:
    return n * factorial(n - 1)


def find_kth_permutation(n: u24, k: u24, elements: List(u24)) -> List(u24):
  if n == 0:
    return []
  else:
    fact = factorial(n - 1)
    index = k / fact
    new_k = k % fact
    
    def pop(list: List(u24), i: u24) -> (u24, List(u24)):
      match list:
        case List/Cons:
          if i == 0:
            return (list.head, list.tail)
          else:
            (elem, remaining_tail) = pop(list.tail, i - 1)
            return (elem, List/Cons{head: list.head, tail: remaining_tail})
        case List/Nil:
          # This case should ideally not be reached with correct logic
          return (0, List/Nil)

    (elem, remaining_elements) = pop(elements, index)
    
    return List/Cons{head: elem, tail: find_kth_permutation(n - 1, new_k, remaining_elements)}


# Função que cada thread/núcleo executará.
def solve_chunk(start_k: u24, count: u24, num_cities: u24, dist_matrix: List(List(f24))) -> f24:
  def build_elements(i: u24, max: u24) -> List(u24):
    if i > max:
      return []
    else:
      return List/Cons{head: i, tail: build_elements(i + 1, max)}
  elements_to_permute = build_elements(1, num_cities - 1)

  def loop(k: u24, remaining: u24, best_cost: f24) -> f24:
    if remaining == 0:
      return best_cost
    else:
      perm = find_kth_permutation(num_cities - 1, k, elements_to_permute)
      route = List/Cons{head: 0, tail: perm}
      current_cost = calculate_route_cost(route, dist_matrix)
      
      # --- LÓGICA CORRIGIDA ---
      # Condição usando o operador bitwise '&'
      is_better = (current_cost < best_cost) & (current_cost >= 0.0)
      
      # Estrutura de blocos 'if/else' para a atribuição
      if is_better == 1:
        new_best = current_cost
      else:
        new_best = best_cost
      
      return loop(k + 1, remaining - 1, new_best)

  initial_best_cost = 9999999.0 
  return loop(start_k, count, initial_best_cost)


def main() -> f24:
  cities = [
    City{x: 10.0, y: 20.0}, City{x: 50.0, y: 80.0}, City{x: 90.0, y: 10.0},
    City{x: 15.0, y: 75.0}, City{x: 45.0, y: 60.0}, City{x: 80.0, y: 30.0},
    City{x: 25.0, y: 95.0}, City{x: 65.0, y: 5.0},  City{x: 5.0,  y: 40.0},
    City{x: 70.0, y: 70.0}
  ]
  
  dist_matrix = get_distance_matrix(cities)
  
  num_permutations = factorial(NUM_CITIES() - 1)
  
  # --- SINTAXE DO 'bend' CORRIGIDA ---
  # 'bend' é uma instrução que atribui o resultado a 'tree_of_costs' internamente.
  bend depth = 0, index = 0:
    when depth < PARALLELISM_DEPTH():
      left_branch  = fork(depth + 1, index * 2 + 0)
      right_branch = fork(depth + 1, index * 2 + 1)
      tree_of_costs = Tree/Node{left: left_branch, right: right_branch}
    else:
      num_tasks = 2 ** PARALLELISM_DEPTH()
      chunk_size = num_permutations / num_tasks
      start_k = index * chunk_size
      
      best_cost_for_chunk = solve_chunk(start_k, chunk_size, NUM_CITIES(), dist_matrix)
      tree_of_costs = Tree/Leaf{value: best_cost_for_chunk}

  # --- SINTAXE DO 'fold' E 'if' CORRIGIDA ---
  # Cada caso do 'fold' agora retorna um valor, e o 'if' usa a sintaxe de blocos.
  fold tree_of_costs:
    case Tree/Node:
      min_left = tree_of_costs.left
      min_right = tree_of_costs.right
      if min_left < min_right:
        return min_left
      else:
        return min_right
    case Tree/Leaf:
      return tree_of_costs.value