module Main (main) where

import Classificacao
import Dados (dadosCampeonato)
import Leitura
import Tipos

testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise = putStrLn ("FALHOU  " ++ nome ++ ": obtido " ++ show obtido ++ ", esperado " ++ show esperado)

main :: IO ()
main = do
  let abertura = Partida 1 "Athletico" 4 0 "Paraná"
      partidas = either (const []) id (lerCampeonato dadosCampeonato)
      esperadoFinal =
        [ Linha "Athletico" 5 3 1 1 8 3
        , Linha "Coritiba" 5 2 2 1 5 3
        , Linha "Oper?rio" 5 2 2 1 4 4
        , Linha "Maring?" 5 2 1 2 6 6
        , Linha "Paran?" 4 1 1 2 4 4
        , Linha "Londrina" 5 1 1 3 2 5
        ]
      esperadoRodada3 =
        [ Linha "Athletico" 3 2 1 0 7 2
        , Linha "Coritiba" 3 2 1 0 4 1
        , Linha "Oper?rio" 3 1 2 0 2 1
        , Linha "Paran?" 2 1 0 1 3 2
        , Linha "Maring?" 3 1 0 2 3 5
        , Linha "Londrina" 3 0 0 3 1 5
        ]
  testar "resultado do mandante" (resultadoPara "Athletico" abertura) (Just Vitoria)
  testar "resultado do visitante" (resultadoPara "Paraná" abertura) (Just Derrota)
  testar "resultado de time ausente" (resultadoPara "Maringá" abertura) Nothing
  testar "times únicos e ordenados" (times partidas) ["Athletico", "Coritiba", "Londrina", "Maringá", "Operário", "Paraná"]
  testar "classificação final" (classificacao partidas) esperadoFinal
  testar "desempate por saldo: Coritiba e Operário empatam com 8 pontos"
    (drop 1 (take 3 (map time (classificacao partidas)))) ["Coritiba", "Operário"]
  testar "classificação até rodada 3" (classificacao (ateRodada 3 partidas)) esperadoRodada3
  testar "goleada em lista vazia" (maiorGoleada []) Nothing
  testar "média em lista vazia" (mediaGols []) Nothing
  testar "campeonato válido" (lerCampeonato dadosCampeonato == Right partidas) True
  testar "CamposInvalidos" (lerPartida 7 "1;A;0;0") (Left (CamposInvalidos 7))
  testar "NumeroInvalido" (lerPartida 8 "x;A;0;0;B") (Left (NumeroInvalido 8))
  testar "PlacarNegativo" (lerPartida 9 "1;A;-1;0;B") (Left (PlacarNegativo 9))
  testar "MesmoTime" (lerPartida 10 "1;A;0;0;A") (Left (MesmoTime 10))
  testar "TimeRepetidoNaRodada" (lerCampeonato "1;A;0;0;B\n1;A;1;0;C") (Left (TimeRepetidoNaRodada 1 "A"))
  testar "múltiplos erros" (todosOsErros "a;A;0;0;B\n1;C;-1;0;D\n1;E;0;0")
    [NumeroInvalido 1, PlacarNegativo 2, CamposInvalidos 3]
