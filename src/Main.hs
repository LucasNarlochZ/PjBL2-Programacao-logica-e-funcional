module Main (main) where

import Classificacao
  ( ateRodada, classificacao, maiorGoleada, mediaGols )
import Dados (dadosCampeonato)
import Leitura (lerCampeonato, tabelaFormatada, todosOsErros)
import Tipos (Partida, rodada)

main :: IO ()
main = case lerCampeonato dadosCampeonato of
  Left erro -> putStrLn ("Erro ao ler campeonato: " ++ show erro)
  Right partidas -> demonstrar partidas

demonstrar :: [Partida] -> IO ()
demonstrar partidas = do
  putStrLn "Classificação final:"
  putStr (tabelaFormatada (classificacao partidas))
  let rodadaIntermediaria = max 1 (maximum (0 : map rodada partidas) `div` 2)
  putStrLn ("\nClassificação após a rodada " ++ show rodadaIntermediaria ++ ":")
  putStr (tabelaFormatada (classificacao (ateRodada rodadaIntermediaria partidas)))
  putStrLn "\nEstatísticas:"
  putStrLn ("Maior goleada: " ++ maybe "sem partidas" show (maiorGoleada partidas))
  putStrLn ("Média de gols: " ++ maybe "sem partidas" show (mediaGols partidas))
  putStrLn "\nDemonstração de entradas inválidas:"
  mapM_ (putStrLn . show) (todosOsErros "1;Time A;dois;0;Time B\n1;Time C;0;0;Time C\n1;Time A;1;0;Time D")
