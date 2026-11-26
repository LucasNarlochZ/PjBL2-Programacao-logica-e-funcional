module Leitura
    ( Erro(..)
    , separar
    , lerPartida
    , lerCampeonato
    , todosOsErros
    , tabelaFormatada
    ) where

import Data.Char (isSpace)
import Data.List (dropWhileEnd, intercalate, isPrefixOf, nub)
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
    deriving (Eq, Show)

aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace


separar :: Char -> String -> [String]

separar delimitador texto =
    case break (== delimitador) texto of
        (campo, []) ->
            [campo]

        (campo, _:resto) ->
            campo : separar delimitador resto


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

        [txtRodada, nomeMandante, txtGolsMandante,
         txtGolsVisitante, nomeVisitante]

            | null nomeMandante || null nomeVisitante ->
                Left (CamposInvalidos numeroLinha)

            | otherwise -> do

                numeroRodada <- lerNumero numeroLinha txtRodada

                golsCasa <- lerNumero numeroLinha txtGolsMandante

                golsFora <- lerNumero numeroLinha txtGolsVisitante

                if golsCasa < 0 || golsFora < 0
                    then Left (PlacarNegativo numeroLinha)

                    else if nomeMandante == nomeVisitante
                        then Left (MesmoTime numeroLinha)

                        else Right
                            (Partida
                                { rodada = numeroRodada
                                , mandante = nomeMandante
                                , golsMandante = golsCasa
                                , golsVisitante = golsFora
                                , visitante = nomeVisitante
                                })

        _ ->
            Left (CamposInvalidos numeroLinha)


quantidadeNaRodada :: Int -> Time -> [Partida] -> Int

quantidadeNaRodada numeroRodada nomeTime partidas =
    length
        (filter
            (\p ->
                rodada p == numeroRodada &&
                (mandante p == nomeTime ||
                 visitante p == nomeTime)
            )
            partidas
        )


errosRepetidos :: [Partida] -> [Erro]

errosRepetidos partidas =
    nub
        [ TimeRepetidoNaRodada numeroRodada nomeTime

        | partida <- partidas

        , let numeroRodada = rodada partida

        , nomeTime <- [mandante partida, visitante partida]

        , quantidadeNaRodada numeroRodada nomeTime partidas > 1
        ]


validarRepeticao :: [Partida] -> Either Erro [Partida]

validarRepeticao partidas =
    case errosRepetidos partidas of

        [] ->
            Right partidas

        primeiroErro : _ ->
            Left primeiroErro


linhasComNumero :: String -> [(Int, String)]

linhasComNumero texto =
    [ (numero, conteudo)

    | (numero, linha) <- zip [1..] (lines texto)

    , let conteudo = aparar linha

    , not (null conteudo)

    , not ("#" `isPrefixOf` conteudo)
    ]



lerCampeonato :: String -> Either Erro [Partida]

lerCampeonato texto = do

    partidas <-
        traverse
            (uncurry lerPartida)
            (linhasComNumero texto)

    validarRepeticao partidas




todosOsErros :: String -> [Erro]

todosOsErros texto = errosDeLinha ++ errosDeRodada

    where

        resultados =
            map
                (uncurry lerPartida)
                (linhasComNumero texto)

        errosDeLinha =
            [ erro
            | Left erro <- resultados
            ]

        partidasValidas =
            [ partida
            | Right partida <- resultados
            ]

        errosDeRodada =
            errosRepetidos partidasValidas




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
