# Decisões de modelagem

- `Time` é um sinônimo de `String`; `Partida` e `Linha` são records para tornar explícitos os campos usados por cada camada.
- Uma leitura malsucedida é representada por `Either Erro a`. `Maybe` representa resultados ausentes, como estatísticas de um campeonato sem partidas.
- A tabela acumula os dados de cada time com `foldl'`, que evita construir uma cadeia grande de thunks. Listas e transformações usam `map`, `filter`, `traverse` e composição.
- A classificação ordena por pontos, saldo de gols, gols pró (decrescentes) e nome do time (crescente), nessa ordem.
- `lerPartida` usa `readMaybe`; a leitura do campeonato usa `traverse`, mantendo o primeiro erro. `todosOsErros` valida cada linha independentemente e também verifica repetição de times entre as partidas válidas.
- Números de linha contam linhas físicas do texto, incluindo comentários e linhas vazias. Comentários são linhas cujo primeiro caractere não branco é `#`.

## Limitações conhecidas

- Os nomes dos times são comparados literalmente, com distinção entre maiúsculas e minúsculas; não há normalização de acentos.
- Não há validação de intervalo para número da rodada, nem uma quantidade esperada de times ou partidas.
- Quando uma rodada contém várias repetições, é reportado um erro por combinação de rodada e time; o parser retorna o primeiro erro detectado.
- Linhas sem erro sintático são consideradas válidas para `todosOsErros`, mesmo quando outra linha do campeonato tem erro.
