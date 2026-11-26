# Decisões de modelagem

- `Time` é um sinônimo de `String`; `Partida` e `Linha` são records para tornar explícitos os campos usados por cada camada.
- Uma leitura malsucedida é representada por `Either Erro a`. `Maybe` representa resultados ausentes, como estatísticas de um campeonato sem partidas.
- A tabela acumula os dados de cada time com `foldl'`, que evita construir uma cadeia grande de thunks. Listas e transformações usam `map`, `filter`, `traverse` e composição.
- A classificação ordena por pontos, saldo de gols, gols pró (decrescentes) e nome do time (crescente), nessa ordem.
- `lerPartida` usa `readMaybe` e rejeita números fora dos limites de `Int`. O leitor usa `traverse` para retornar o primeiro erro de linha. Quando todas as linhas são válidas, verifica repetições e depois totais de gols. `todosOsErros` acumula os erros na mesma ordem e usa as partidas válidas para as verificações do campeonato.
- A verificação de repetições ordena e agrupa as participações por rodada e time, evitando varrer todas as partidas para cada time. Os erros de repetição seguem a ordem da primeira participação de cada time naquela rodada.
- A média soma os gols em `Integer` antes de converter para `Double`. A classificação mantém gols pró, gols contra e saldo em `Int`. O leitor devolve `TotalGolsExcedido` com a primeira linha em que o total de gols pró ou contra daquele time ultrapassa o limite da tabela.
- Números de linha contam linhas físicas do texto, incluindo comentários e linhas vazias. Comentários são linhas cujo primeiro caractere não branco é `#`.

## Limitações conhecidas

- Os nomes dos times são comparados literalmente, com distinção entre maiúsculas e minúsculas; não há normalização de acentos.
- O número da rodada precisa caber em `Int`. O leitor aceita qualquer rodada dentro desse intervalo e não exige uma quantidade fixa de times ou partidas.
- Cada combinação de rodada e time produz no máximo um erro de repetição.
- Ao montar uma lista de `Partida` diretamente para a classificação, quem chama deve garantir placares não negativos e totais de gols por time dentro dos limites de `Int`. A leitura a partir de texto já verifica essas condições.
