# Shared championship interfaces

Use `src/Tipos.hs` as the source of the shared types and record fields. `Tipos` exports `Time`, `Resultado(..)`, `Partida(..)`, and `Linha(..)`. With GHC available, verify the base from the repository root with `ghc -Wall -Werror -fno-code src/Tipos.hs src/Dados.hs`.

## `Tipos` and `Dados`

```haskell
participou :: Time -> Partida -> Bool
resultadoPara :: Time -> Partida -> Maybe Resultado
times :: [Partida] -> [Time]
dadosCampeonato :: String
```

In the opening Athletico–Paraná match (4–0), `participou` is `True` for both teams and `False` for Maringá. `resultadoPara` gives `Just Vitoria` for Athletico, `Just Derrota` for Paraná, and `Nothing` for Maringá. `times` gives `["Athletico", "Coritiba", "Londrina", "Maringá", "Operário", "Paraná"]` for the full sample.

Each match occupies one line in the order `round;home team;home goals;away goals;away team`. The reader skips blank lines and lines beginning with `#`.

## `Classificacao`

```haskell
pontos :: Resultado -> Int
linhaDoTime :: [Partida] -> Time -> Linha
pontosLinha :: Linha -> Int
saldo :: Linha -> Int
aproveitamento :: Linha -> Double
classificacao :: [Partida] -> [Linha]
ateRodada :: Int -> [Partida] -> [Partida]
maiorGoleada :: [Partida] -> Maybe Partida
mediaGols :: [Partida] -> Maybe Double
```

Award three points for a win, one for a draw, and zero for a loss. Rank teams by points, then goal difference (`golsPro - golsContra`), then goals scored, all descending. Break any remaining tie by team name in ascending `String` order. In the sample, Coritiba ranks ahead of Operário on goal difference (+2 versus 0) after both finish with eight points.

`ateRodada` includes the specified round. `aproveitamento` returns a percentage from 0 to 100 and returns 0 for a team with no games. On empty input, `classificacao` returns `[]`, while `maiorGoleada` and `mediaGols` return `Nothing`.

## `Leitura`

```haskell
data Erro
  = CamposInvalidos Int
  | NumeroInvalido Int
  | PlacarNegativo Int
  | MesmoTime Int
  | TimeRepetidoNaRodada Int Time
  | TotalGolsExcedido Int Time
  deriving (Eq, Show)

separar :: Char -> String -> [String]
lerPartida :: Int -> String -> Either Erro Partida
lerCampeonato :: String -> Either Erro [Partida]
todosOsErros :: String -> [Erro]
tabelaFormatada :: [Linha] -> String
```

The `Int` in the first four constructors identifies the original input line, numbered from 1. `TimeRepetidoNaRodada` identifies the round and the team that appears more than once. `TotalGolsExcedido` identifies the line where a team's goals for or against first exceed the upper bound of `Int`. `lerCampeonato` checks line errors first, then repeated appearances and goal totals. `todosOsErros` reports errors in the same order and checks repetitions and totals across individually valid matches.

## `Main`

```haskell
main :: IO ()
```

`Main` reads `dadosCampeonato` through `lerCampeonato` and demonstrates the final standings, intermediate standings, statistics, and handling of invalid input.
