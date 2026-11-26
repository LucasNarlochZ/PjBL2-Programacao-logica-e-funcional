module Main (main) where

import System.Exit (exitFailure)

import Dados (dadosCampeonato)
import Leitura (Erro(..), lerCampeonato, lerPartida, tabelaFormatada, todosOsErros)
import Tipos (Linha(..), Partida(..))

testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado =
  if obtido == esperado
    then putStrLn ("OK " ++ nome)
    else do
      putStrLn ("FALHOU " ++ nome ++ ": esperado " ++ show esperado ++ ", obtido " ++ show obtido)
      exitFailure

main :: IO ()
main = do
  testar "campeonato válido" (fmap length (lerCampeonato dadosCampeonato)) (Right 15)
  testar "espaços nos campos"
    (lerPartida 1 " 1 ; Coritiba ; 2 ; 0 ; Paraná ")
    (Right (Partida 1 "Coritiba" 2 0 "Paraná"))
  testar "linhas em branco e comentários com espaços são ignorados"
    (lerCampeonato " \t\n  # comentário\n1;Coritiba;2;0;Paraná\r\n")
    (Right [Partida 1 "Coritiba" 2 0 "Paraná"])
  testar "campos inválidos" (lerCampeonato "1;Coritiba;2;0") (Left (CamposInvalidos 1))
  testar "número inválido na linha original"
    (lerCampeonato "# cabeçalho\n\n1;Coritiba;dois;0;Paraná")
    (Left (NumeroInvalido 3))
  testar "placar negativo" (lerCampeonato "1;Coritiba;-2;0;Paraná") (Left (PlacarNegativo 1))
  testar "mesmo time" (lerCampeonato "1;Coritiba;2;0;Coritiba") (Left (MesmoTime 1))
  testar "time repetido na rodada"
    (lerCampeonato "1;Coritiba;2;0;Paraná\n1;Maringá;0;1;Coritiba")
    (Left (TimeRepetidoNaRodada 1 "Coritiba"))
  let entradaInvalida = unlines ["1;Coritiba;2;0", "1;Coritiba;dois;0;Paraná", "1;Coritiba;-2;0;Paraná"]
  testar "primeiro erro" (lerCampeonato entradaInvalida) (Left (CamposInvalidos 1))
  testar "todos os erros"
    (todosOsErros entradaInvalida)
    [CamposInvalidos 1, NumeroInvalido 2, PlacarNegativo 3]
  let tabela = tabelaFormatada [Linha "Coritiba" 1 1 0 0 2 0]
  testar "colunas e valores da tabela"
    (lines tabela)
    [ "Pos | Time     | Pts | J | V | E | D | SG"
    , replicate 41 '-'
    , "  1 | Coritiba |   3 | 1 | 1 | 0 | 0 |  2"
    ]
