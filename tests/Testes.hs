module Main (main) where

import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)

import Classificacao
  ( aproveitamento, ateRodada, classificacao, linhaDoTime, maiorGoleada, mediaGols, pontosLinha, saldo )
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
  hSetEncoding stdout utf8
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
  testar "mesmo time com o mesmo mando em outra rodada"
    (fmap length (lerCampeonato "1;Coritiba;2;0;Paraná\n2;Maringá;0;1;Coritiba"))
    (Right 2)
  let errosCombinados = "1;Z;0;0;A\n1;Z;0;0;A\n2;B;dois;0;C"
  testar "erro de linha tem prioridade sobre repetição"
    (lerCampeonato errosCombinados) (Left (NumeroInvalido 3))
  testar "repetições são únicas e seguem a ordem de entrada"
    (todosOsErros errosCombinados) [NumeroInvalido 3, TimeRepetidoNaRodada 1 "Z", TimeRepetidoNaRodada 1 "A"]
  testar "campeonato sem partidas" (lerCampeonato "# comentário\n \t\n") (Right [])
  testar "aproveitamento sem jogos" (aproveitamento (linhaDoTime [] "Coritiba")) 0
  testar "formatação da tabela vazia" (length (lines (tabelaFormatada []))) 2
  testar "desempate por gols pró"
    (take 2 (map time (classificacao [Partida 1 "Z" 2 1 "Y", Partida 1 "A" 1 0 "X"]))) ["Z", "A"]
  testar "desempate por nome"
    (take 2 (map time (classificacao [Partida 1 "Z" 1 0 "Y", Partida 1 "A" 1 0 "X"]))) ["A", "Z"]
  let limite = maxBound :: Int
      placarNoLimite = "1;A;" ++ show limite ++ ";1;B"
  testar "média de gols soma além do limite de Int"
    (fmap mediaGols (lerCampeonato placarNoLimite))
    (Right (Just (fromInteger (toInteger limite + 1))))
  let totaisExcedidos = unlines ["1;A;" ++ show limite ++ ";0;B", "# intervalo", "2;A;1;0;B"]
  testar "total de gols acima do limite da tabela"
    (lerCampeonato totaisExcedidos) (Left (TotalGolsExcedido 3 "A"))
  testar "relatório inclui totais excedidos de gols pró e contra"
    (todosOsErros totaisExcedidos) [TotalGolsExcedido 3 "A", TotalGolsExcedido 3 "B"]
  let entradaInvalida = unlines ["1;Coritiba;2;0", "1;Coritiba;dois;0;Paraná", "1;Coritiba;-2;0;Paraná"]
  testar "primeiro erro" (lerCampeonato entradaInvalida) (Left (CamposInvalidos 1))
  testar "todos os erros"
    (todosOsErros entradaInvalida)
    [CamposInvalidos 1, NumeroInvalido 2, PlacarNegativo 3]
  let linhaComDoisErros = "1;A;-1;0;A"
  testar "relatório inclui dois erros na mesma linha"
    (todosOsErros linhaComDoisErros) [PlacarNegativo 1, MesmoTime 1]
  testar "leitura retorna apenas o primeiro erro da linha"
    (lerCampeonato linhaComDoisErros) (Left (PlacarNegativo 1))
  testar "números inválidos preservam outros erros da linha"
    (todosOsErros "# cabeçalho\ntexto;A;texto;-1;A")
    [NumeroInvalido 2, PlacarNegativo 2, MesmoTime 2]
  testar "nome ausente tem prioridade e preserva erros numéricos"
    (todosOsErros "texto; ;0;-1;A")
    [CamposInvalidos 1, NumeroInvalido 1, PlacarNegativo 1]
  testar "linha inválida não entra na verificação de repetições"
    (todosOsErros (unlines ["1;A;0;0;B", linhaComDoisErros])) [PlacarNegativo 2, MesmoTime 2]
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
