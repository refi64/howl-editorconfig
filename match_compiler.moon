import P, S, Cg, sequence, any from howl.util.lpeg_lexer

eof_sequence = (...) ->
  args = {...}
  table.insert args, -1
  sequence args

recursive_glob = P'**' / -> P 1
basic_glob = P'*' / -> P(1) - P'/'

glob = recursive_glob + basic_glob

any_wildcard = P'?' / -> P 1

escaped_char = P'\\' * Cg(P 1) / P

set = P'[' * Cg(P'!'^-1) * Cg((P(1) - P']')^0) * P']' / (neg, chars) ->
  matcher = S(chars)
  return if #neg != 0
    P(1) - matcher
  else
    matcher

one_of_item = Cg((P(1) - S',}')^0)
one_of = P'{' * one_of_item * (P',' * one_of_item)^1 * P'}' / (...) ->
  items = {...}
  table.sort items, (a, b) -> a >= b
  any items

normal_char = (P(1) - S'[]{}*?') / P

basic_pattern = escaped_char + any_wildcard + set + one_of + normal_char

middle_glob = glob * basic_pattern^1 / (glob_matcher, ...) ->
  patterns = eof_sequence ...
  (glob_matcher - patterns * -1)^0 * patterns
end_glob = glob * -1 / (glob_matcher) -> glob_matcher^0

complete_pattern = ((middle_glob + basic_pattern)^0 * end_glob^-1 * -1) / eof_sequence

return complete_pattern\match
