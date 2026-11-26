# Tabela de classificação em Haskell

Projeto de programação funcional que lê resultados de um campeonato, valida as partidas e calcula classificação e estatísticas. O código usa apenas módulos da biblioteca padrão (`base`).

## Estrutura

- `src/Tipos.hs`: tipos do domínio e consultas sobre partidas.
- `src/Dados.hs`: campeonato de exemplo com seis times e cinco rodadas.
- `src/Classificacao.hs`: pontuação, classificação e estatísticas.
- `src/Leitura.hs`: parser, validação, erros acumulados e impressão da tabela.
- `src/Main.hs`: demonstração das funcionalidades.
- `tests/Testes.hs`: testes executáveis das três camadas.
- `docs/decisoes.md`: decisões e limitações.

## Compilar e executar

Com GHC instalado, na raiz do projeto:

```sh
ghc -Wall -isrc src/Main.hs -o campeonato
./campeonato
```

No PowerShell, execute `./campeonato.exe` após compilar.

## Executar os testes

```sh
ghc -Wall -isrc tests/Testes.hs -o testes
./testes
```

Os testes comparam os resultados com valores esperados definidos a partir dos resultados do campeonato e dos requisitos.
