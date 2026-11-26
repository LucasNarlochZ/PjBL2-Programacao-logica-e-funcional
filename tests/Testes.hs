module Main (main) where

import System.Exit (exitFailure)

import Classificacao (ateRodada, classificacao, maiorGoleada, mediaGols, pontosLinha, saldo)
import Dados (dadosCampeonato)
import Leitura (Erro(..), lerCampeonato, lerPartida, tabelaFormatada, todosOsErros)
import Tipos (Linha(..), Partida(..), Resultado(..), resultadoPara, times)

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
  case lerCampeonato dadosCampeonato of
    Left erro -> do
      print erro
      exitFailure
    Right partidas -> testarClassificacao partidas
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
  let foraDoLimite = show (2 * (toInteger (maxBound :: Int) + 1))
  testar "placar acima do limite de Int"
    (lerPartida 1 ("1;Coritiba;" ++ foraDoLimite ++ ";0;Paraná"))
    (Left (NumeroInvalido 1))
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

testarClassificacao :: [Partida] -> IO ()
testarClassificacao partidas = do
  let abertura = Partida 1 "Athletico" 4 0 "Paraná"
      tabelaFinal = classificacao partidas
      esperadoFinal =
        [ Linha "Athletico" 5 3 1 1 8 3
        , Linha "Coritiba" 5 2 2 1 5 3
        , Linha "Operário" 5 2 2 1 4 4
        , Linha "Maringá" 5 2 1 2 6 6
        , Linha "Londrina" 5 1 1 3 2 5
        , Linha "Paraná" 5 1 1 3 4 8
        ]
      esperadoRodada3 =
        [ Linha "Athletico" 3 2 1 0 7 2
        , Linha "Coritiba" 3 2 1 0 4 1
        , Linha "Operário" 3 1 2 0 2 1
        , Linha "Maringá" 3 1 0 2 3 5
        , Linha "Paraná" 3 1 0 2 3 6
        , Linha "Londrina" 3 0 0 3 1 5
        ]
      empatados = filter ((== 8) . pontosLinha) tabelaFinal
  testar "resultado do mandante" (resultadoPara "Athletico" abertura) (Just Vitoria)
  testar "resultado do visitante" (resultadoPara "Paraná" abertura) (Just Derrota)
  testar "resultado de time ausente" (resultadoPara "Maringá" abertura) Nothing
  testar "times únicos e ordenados" (times partidas)
    ["Athletico", "Coritiba", "Londrina", "Maringá", "Operário", "Paraná"]
  testar "classificação final" tabelaFinal esperadoFinal
  testar "desempate por saldo com oito pontos"
    (map (\linha -> (time linha, saldo linha)) empatados) [("Coritiba", 2), ("Operário", 0)]
  testar "classificação até a rodada 3" (classificacao (ateRodada 3 partidas)) esperadoRodada3
  testar "maior goleada sem partidas" (maiorGoleada []) Nothing
  testar "média de gols sem partidas" (mediaGols []) Nothing
