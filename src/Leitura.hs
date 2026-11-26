module Leitura
    ( Erro(..)
    , separar
    , lerPartida
    , lerCampeonato
    , todosOsErros
    , tabelaFormatada
    ) where

import Data.Char (isSpace)
import Data.List (dropWhileEnd, groupBy, intercalate, isPrefixOf, sortOn)
import Text.Read (readMaybe)

import Tipos
    ( Time
    , Partida(..)
    , Linha(..)
    )

import Classificacao
    ( pontosLinha
    , saldo
    )

data Erro
    = CamposInvalidos Int
    | NumeroInvalido Int
    | PlacarNegativo Int
    | MesmoTime Int
    | TimeRepetidoNaRodada Int Time
    | TotalGolsExcedido Int Time
    deriving (Eq, Show)

aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace


separar :: Char -> String -> [String]
separar delimitador texto =
    case break (== delimitador) texto of
        (campo, []) -> [campo]
        (campo, _:resto) -> campo : separar delimitador resto

lerNumero :: Int -> String -> Either Erro Int
lerNumero linha texto =
    case readMaybe texto :: Maybe Integer of
        Just numero
            | numero >= toInteger (minBound :: Int)
            , numero <= toInteger (maxBound :: Int) -> Right (fromInteger numero)
        _ -> Left (NumeroInvalido linha)

lerPartida :: Int -> String -> Either Erro Partida
lerPartida numeroLinha texto =
    case map aparar (separar ';' texto) of
        [txtRodada, nomeMandante, txtGolsMandante, txtGolsVisitante, nomeVisitante]
            | not (null nomeMandante || null nomeVisitante) -> do
                numeroRodada <- lerNumero numeroLinha txtRodada
                golsCasa <- lerNumero numeroLinha txtGolsMandante
                golsFora <- lerNumero numeroLinha txtGolsVisitante
                validarPlacar numeroRodada nomeMandante golsCasa golsFora nomeVisitante
        _ -> Left (CamposInvalidos numeroLinha)
  where
    validarPlacar numeroRodada nomeMandante golsCasa golsFora nomeVisitante
        | golsCasa < 0 || golsFora < 0 = Left (PlacarNegativo numeroLinha)
        | nomeMandante == nomeVisitante = Left (MesmoTime numeroLinha)
        | otherwise = Right Partida
            { rodada = numeroRodada, mandante = nomeMandante, visitante = nomeVisitante
            , golsMandante = golsCasa, golsVisitante = golsFora
            }

data Participacao = Participacao
    { nomeTime :: Time
    , rodadaDaPartida :: Int
    , ordemEntrada :: (Int, Bool)
    , golsFeitos :: Int
    , golsSofridos :: Int
    }

participacoes :: (Int, Partida) -> [Participacao]
participacoes (linha, partida) =
    [ Participacao (mandante partida) (rodada partida) (linha, False) casa fora
    , Participacao (visitante partida) (rodada partida) (linha, True) fora casa
    ]
  where
    casa = golsMandante partida
    fora = golsVisitante partida

agruparPor :: Ord chave => (a -> chave) -> [a] -> [[a]]
agruparPor chave = groupBy (\a b -> chave a == chave b) . sortOn chave

errosCampeonato :: [(Int, Partida)] -> [Erro]
errosCampeonato partidas =
    map snd (sortOn fst repeticoes) ++ map snd (sortOn fst totaisExcedidos)
  where
    registros = concatMap participacoes partidas
    repeticoes =
        [ (ordemEntrada p, TimeRepetidoNaRodada (rodadaDaPartida p) (nomeTime p))
        | p : _ : _ <- agruparPor (\p -> (rodadaDaPartida p, nomeTime p)) registros
        ]
    totaisExcedidos =
        [ (ordemEntrada p, TotalGolsExcedido (fst (ordemEntrada p)) (nomeTime p))
        | Just p <- map encontrouExcesso (agruparPor nomeTime registros)
        ]

encontrouExcesso :: [Participacao] -> Maybe Participacao
encontrouExcesso = acumular 0 0
  where
    limite = toInteger (maxBound :: Int)

    acumular _ _ [] = Nothing
    acumular pro contra (p : resto)
        | novosPro > limite || novosContra > limite = Just p
        | otherwise = acumular novosPro novosContra resto
      where
        novosPro = pro + toInteger (golsFeitos p)
        novosContra = contra + toInteger (golsSofridos p)

linhasComNumero :: String -> [(Int, String)]
linhasComNumero texto =
    [ (numero, conteudo)
    | (numero, linha) <- zip [1..] (lines texto)
    , let conteudo = aparar linha
    , not (null conteudo)
    , not ("#" `isPrefixOf` conteudo)
    ]

lerLinha :: (Int, String) -> Either Erro (Int, Partida)
lerLinha (numero, texto) = fmap ((,) numero) (lerPartida numero texto)

lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto = do
    partidas <- traverse lerLinha (linhasComNumero texto)
    case errosCampeonato partidas of
        [] -> Right (map snd partidas)
        erro : _ -> Left erro

todosOsErros :: String -> [Erro]
todosOsErros texto = errosDeLinha ++ errosCampeonato partidasValidas
  where
    resultados = map lerLinha (linhasComNumero texto)
    errosDeLinha = [erro | Left erro <- resultados]
    partidasValidas = [partida | Right partida <- resultados]

tabelaFormatada :: [Linha] -> String

tabelaFormatada linhas =
    unlines (cabecalho : linhaSeparadora : linhasFormatadas)

    where

        larguraPosicao =
            max 3 (length (show (length linhas)))

        larguraTime =
            maximum (length "Time" : map (length . time) linhas)

        larguraPontos =
            maximum
                (length "Pts" : map (length . show . pontosLinha) linhas)

        larguraJogos =
            maximum
                (length "J" : map (length . show . jogos) linhas)

        larguraVitorias =
            maximum
                (length "V" : map (length . show . vitorias) linhas)

        larguraEmpates =
            maximum
                (length "E" : map (length . show . empates) linhas)

        larguraDerrotas =
            maximum
                (length "D" : map (length . show . derrotas) linhas)

        larguraSaldo =
            maximum
                (length "SG" : map (length . show . saldo) linhas)

        cabecalho =
            intercalate " | "
                [ padLeft larguraPosicao "Pos"
                , padRight larguraTime "Time"
                , padLeft larguraPontos "Pts"
                , padLeft larguraJogos "J"
                , padLeft larguraVitorias "V"
                , padLeft larguraEmpates "E"
                , padLeft larguraDerrotas "D"
                , padLeft larguraSaldo "SG"
                ]

        linhaSeparadora =
            replicate (length cabecalho) '-'

        linhasFormatadas =
            zipWith formatar [1..] linhas

        formatar :: Int -> Linha -> String
        formatar posicao linha =
            intercalate " | "
                [ padLeft larguraPosicao (show posicao)
                , padRight larguraTime (time linha)
                , padLeft larguraPontos (show (pontosLinha linha))
                , padLeft larguraJogos (show (jogos linha))
                , padLeft larguraVitorias (show (vitorias linha))
                , padLeft larguraEmpates (show (empates linha))
                , padLeft larguraDerrotas (show (derrotas linha))
                , padLeft larguraSaldo (show (saldo linha))
                ]

padLeft :: Int -> String -> String

padLeft largura valor =
    replicate (max 0 (largura - length valor)) ' ' ++ valor


padRight :: Int -> String -> String

padRight largura valor =
    valor ++ replicate (max 0 (largura - length valor)) ' '
