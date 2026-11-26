module Classificacao
  ( pontos
  , linhaDoTime
  , pontosLinha
  , saldo
  , aproveitamento
  , classificacao
  , ateRodada
  , maiorGoleada
  , mediaGols
  ) where

import Data.List (foldl', sortBy)
import Data.Ord (Down (..), comparing)
import Tipos
  ( Linha (..)
  , Partida (..)
  , Resultado (..)
  , Time
  , participou
  , resultadoPara
  , times
  )

pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime partidas nomeTime =
  foldl' (atualizarLinha nomeTime) linhaInicial (filter (participou nomeTime) partidas)
  where
    linhaInicial =
      Linha
        { time = nomeTime
        , jogos = 0
        , vitorias = 0
        , empates = 0
        , derrotas = 0
        , golsPro = 0
        , golsContra = 0
        }

atualizarLinha :: Time -> Linha -> Partida -> Linha
atualizarLinha nomeTime acc partida =
  case resultadoPara nomeTime partida of
    Nothing -> acc
    Just res ->
      acc
        { jogos = jogos acc + 1
        , vitorias = vitorias acc + if res == Vitoria then 1 else 0
        , empates = empates acc + if res == Empate then 1 else 0
        , derrotas = derrotas acc + if res == Derrota then 1 else 0
        , golsPro = golsPro acc + feitos
        , golsContra = golsContra acc + sofridos
        }
  where
    (feitos, sofridos)
      | nomeTime == mandante partida = (golsMandante partida, golsVisitante partida)
      | otherwise                    = (golsVisitante partida, golsMandante partida)

pontosLinha :: Linha -> Int
pontosLinha linha =
  vitorias linha * pontos Vitoria + empates linha * pontos Empate

saldo :: Linha -> Int
saldo linha = golsPro linha - golsContra linha

aproveitamento :: Linha -> Double
aproveitamento linha
  | jogos linha == 0 = 0.0
  | otherwise =
      (fromIntegral (pontosLinha linha) / fromIntegral (jogos linha * pontos Vitoria)) * 100.0

classificacao :: [Partida] -> [Linha]
classificacao partidas =
  sortBy compararLinhas . map (linhaDoTime partidas) $ times partidas

compararLinhas :: Linha -> Linha -> Ordering
compararLinhas =
  comparing (Down . pontosLinha)
    <> comparing (Down . saldo)
    <> comparing (Down . golsPro)
    <> comparing time

ateRodada :: Int -> [Partida] -> [Partida]
ateRodada r = filter ((<= r) . rodada)

maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada [] = Nothing
maiorGoleada (p : ps) = Just (foldl' escolherMaior p ps)
  where
    escolherMaior atual candidata
      | diferencaGols candidata > diferencaGols atual = candidata
      | otherwise                                     = atual

diferencaGols :: Partida -> Int
diferencaGols p = abs (golsMandante p - golsVisitante p)

mediaGols :: [Partida] -> Maybe Double
mediaGols [] = Nothing
mediaGols partidas =
  Just (fromIntegral totalGols / fromIntegral totalPartidas)
  where
    (totalGols, totalPartidas) =
      foldl' (\(g, n) p -> (g + toInteger (golsMandante p) + toInteger (golsVisitante p), n + 1))
        (0, 0 :: Int) partidas
