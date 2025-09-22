# -----------------------------------------
# Estruturas de Dados e Constantes
# -----------------------------------------

object City { x, y }

def NUM_CITIES():
  return 7

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
        remaining_matrix = build_matrix_helper(cities_to_process.tail, original_cities)
        
        return List/Cons{head: current_row, tail: remaining_matrix}

  return build_matrix_helper(cities, cities)


def get_matrix_val(matrix: List(List(f24)), row: u24, col: u24) -> f24:
  match matrix:
    case List/Nil:
      return -1.0
    
    case List/Cons:
      if row == 0:
        def get_col(list_row: List(f24), c: u24) -> f24:
          match list_row:
            case List/Nil:
              return -1.0
            
            case List/Cons:
              if c == 0:
                return list_row.head
              else:
                return get_col(list_row.tail, c - 1)
        
        return get_col(matrix.head, col)
      else:
        return get_matrix_val(matrix.tail, row - 1, col)


def calculate_route_cost(route: List(u24), dist_matrix: List(List(f24))) -> f24:
  match route:
    case List/Nil:
      return 0.0
    case List/Cons:
      match route.tail:
        case List/Cons:
          from_city = route.head
          to_city = route.tail.head
          dist = get_matrix_val(dist_matrix, from_city, to_city)
          return dist + calculate_route_cost(route.tail, dist_matrix)
        case List/Nil:
          from_city = route.head
          to_city = 0
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
          return (0, List/Nil)

    (elem, remaining_elements) = pop(elements, index)
    
    return List/Cons{head: elem, tail: find_kth_permutation(n - 1, new_k, remaining_elements)}


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
      
      is_better = (current_cost < best_cost) & (current_cost >= 0.0)
      
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
    City{x: 25.0, y: 95.0}
  ]
  
  dist_matrix = get_distance_matrix(cities)
  
  num_permutations = factorial(NUM_CITIES() - 1)
  
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