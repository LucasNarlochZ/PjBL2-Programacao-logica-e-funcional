module Dados (dadosCampeonato) where

dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , "1;Athletico;4;0;Paran\225"
  , "1;Coritiba;0;0;Oper\225rio"
  , "1;Londrina;1;2;Maring\225"
  , "2;Athletico;1;1;Oper\225rio"
  , "2;Paran\225;2;0;Maring\225"
  , "2;Coritiba;2;0;Londrina"
  , "3;Athletico;2;1;Maring\225"
  , "3;Oper\225rio;1;0;Londrina"
  , "3;Paran\225;1;2;Coritiba"
  , "4;Athletico;0;1;Londrina"
  , "4;Maring\225;1;1;Coritiba"
  , "4;Oper\225rio;2;1;Paran\225"
  , "5;Athletico;1;0;Coritiba"
  , "5;Londrina;0;0;Paran\225"
  , "5;Maring\225;2;0;Oper\225rio"
  ]
