# Dendra

[![Build Status](https://github.com/renilsonlisboa/Dendra.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/renilsonlisboa/Dendra.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Dendra** é um pacote em [Julia](https://julialang.org/) para processamento e análise de dados de **inventário florestal contínuo**. O pacote reúne, em um único fluxo de trabalho, a padronização de dados de campo (árvores e fustes), o cálculo de índices fitossociológicos (densidade, dominância, frequência, IVI e índices de diversidade), a validação taxonômica contra a Flora do Brasil (JBRJ/Reflora), a geração de gráficos de distribuição e a exportação de todos os resultados em planilhas `.xlsx` já formatadas.

O pacote foi desenvolvido para dar suporte à análise de parcelas permanentes organizadas hierarquicamente em **Ano → Bloco → Parcela → Faixa → Árvore/Fuste**.

> ⚠️ **Status do projeto:** Dendra está em desenvolvimento ativo (versão `1.0.0-DEV`). Algumas funções listadas na seção `export` do módulo (`inventario_nativas`, `countFamily`, `FitoBlocos`) ainda estão em implementação ou passando por ajustes de nome/assinatura e podem não estar totalmente funcionais nesta fase.

---

## Sumário

- [Instalação](#instalação)
- [Dependências](#dependências)
- [Visão geral do fluxo de trabalho](#visão-geral-do-fluxo-de-trabalho)
- [Referência de funções](#referência-de-funções)
  - [Estrutura de diretórios](#estrutura-de-diretórios)
  - [Padronização de dados](#padronização-de-dados)
  - [Validação taxonômica (Reflora/JBRJ)](#validação-taxonômica-reflorajbrj)
  - [Fitossociologia](#fitossociologia)
  - [Ingresso e mortalidade](#ingresso-e-mortalidade)
  - [Exportação para Excel](#exportação-para-excel)
  - [Gráficos](#gráficos)
- [Estrutura de saída (`Resultados/`)](#estrutura-de-saída-resultados)
- [Autores](#autores)
- [Licença](#licença)

---

## Instalação

O pacote ainda não está registrado no repositório geral do Julia. Instale diretamente a partir do GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/renilsonlisboa/Dendra.jl")
```

Ou, para desenvolvimento local:

```julia
using Pkg
Pkg.develop(url="https://github.com/renilsonlisboa/Dendra.jl")
```

Requer **Julia ≥ 1.10**.

## Dependências

| Pacote | Versão (compat) | Uso |
|---|---|---|
| `DataFrames` | 1.8.2 | Estrutura tabular central dos dados de inventário |
| `XLSX` | 0.12.0 | Leitura/escrita de planilhas Excel formatadas |
| `CairoMakie` | 0.15.13 | Geração dos gráficos de distribuição |
| `HTTP` | 2.5.5 | Requisições ao serviço web da Flora do Brasil |
| `JSON3` | 1.14.3 | Parsing das respostas da API do Reflora |

## Visão geral do fluxo de trabalho

Um fluxo típico de análise com o Dendra segue, aproximadamente, esta sequência:

```julia
using Dendra, DataFrames

# 1. Cria a estrutura de pastas de saída
criar_estrutura_diretorios(savepath)

# 2. Valida a taxonomia registrada em campo contra a Flora do Brasil
inconsistencias = ValidateTaxonomy(dados, savepath)

# 3. Padroniza os dados de árvores e de fustes por ano
dados_arvores = dataTrees(dados, "CAP", Anos)
dados_fustes  = dataFustes(dados, "CAP", Anos; parametros_fustes = [5, 6])

# 4. Calcula a fitossociologia em diferentes níveis de agregação
fito_geral, indices_geral     = FitoGeral(dados_arvores, Anos, Area)
fito_parcela, indices_parcela = FitoParcela(dados_arvores, Anos, Area)
fito_faixa, indices_faixa     = FitoFaixa(dados_arvores, Anos, Area)

# 5. Exporta os resultados consolidados em planilhas formatadas
salvar_planilha_multiplas_abas(
    [fito_geral, fito_parcela, fito_faixa],
    ["Geral", "Parcela", "Faixa"],
    joinpath(savepath, "Resultados", "Fitossociologia_Completa.xlsx"),
)

# 6. Gera gráficos de distribuição dos índices de diversidade
grafico_distribuicao_indice(indices_geral, :Shannon)
```

---

## Referência de funções

### Estrutura de diretórios

#### `criar_estrutura_diretorios(diretorio_saida)`
Cria, dentro de `diretorio_saida`, toda a árvore de pastas usada pelas demais funções para salvar resultados (`Resultados/Gráficos`, `Resultados/Gráficos/Taxas/{Espécies,Gêneros,Famílias}`, `Índices`, `Contagens`, `Estoques`, `Distribuições`). Usa `mkpath`, então é seguro chamá-la repetidamente.

### Padronização de dados

#### `dataTrees(dados, Var, Anos)`
Filtra, para cada ano em `Anos`, apenas as linhas correspondentes ao fuste principal (`Fuste == 1`) e converte a variável de medição (`Var`, tipicamente `"CAP"`) em DAP (dividindo por π) quando aplicável. Retorna um vetor de `DataFrame` (um por ano) e salva o resultado em `Resultados/1 - Dados_Anuais.xlsx` (uma aba por ano).

#### `dataFustes(dados, Var, Anos; parametros_fustes)`
Monta, para cada ano, a base de **fustes** (em vez de árvores), removendo registros marcados como `"Ingresso"`, `"Morta"`, `"Sem"`, `"Mudou"` ou `"Eliminada"` na coluna de medição do ano, convertendo `CAP → DAP`, e filtrando os códigos de fuste válidos — usando `parametros_fustes` para a família *Araucariaceae* e os códigos `[0,1,2,3,4]` para as demais famílias. Salva em `Resultados/2 - Dados_Fustes.xlsx`.

#### `select_periods(dados, Var)`
Função auxiliar interna que identifica as colunas `Var_AAAA` (ex.: `CAP_2020`, `DAP_2021`), extrai os anos de medição a partir dos nomes de coluna e monta os rótulos de período entre medições consecutivas (ex.: `"2020 - 2021"`). Retorna a tupla `(Anos, periodos)`.

### Validação taxonômica (Reflora/JBRJ)

#### `reflora_taxon(nome)`
Consulta o serviço web da **Flora do Brasil** (JBRJ/Reflora) para o nome científico `nome` e retorna o JSON de resposta já parseado (via `JSON3`). Lança um erro se a requisição HTTP não retornar status `200`.

#### `ValidateTaxonomy(df, savepath, save=true)`
Para cada nome científico único em `df` (ignorando `"N.I."` e nomes terminados em `"spp."`), consulta `reflora_taxon` e compara Gênero, Espécie e Família registrados em campo contra os dados oficiais retornados pela API — inclusive testando sinônimos via `resource_relationship` quando o nome não é o nome corrente aceito. Retorna um `DataFrame` apenas com as linhas inconsistentes ou não encontradas e, se `save = true`, salva o relatório em `Resultados/Verificação_Botânica.xlsx`.

*Função auxiliar interna:* `nomes_iguais(a, b)` compara dois valores ignorando `missing` e diferenças de maiúsculas/minúsculas.

### Fitossociologia

Todas as funções de fitossociologia recebem `dados_arvores::Vector{DataFrame}` (um `DataFrame` por ano, no formato retornado por `dataTrees`), o vetor `Anos` e a área de amostragem, e retornam uma tupla `(Fitossociologia, Indices)`.

Os índices fitossociológicos calculados em cada nível são:

| Sigla | Índice |
|---|---|
| `DA` / `DR` | Densidade Absoluta / Relativa |
| `DoA` / `DoR` | Dominância Absoluta / Relativa |
| `FA` / `FR` | Frequência Absoluta / Relativa |
| `IVI` | Índice de Valor de Importância (`DR + DoR + FR`) |

#### `FitoGeral(dados_arvores, Anos, Area)`
Calcula os índices fitossociológicos por espécie **agregados no nível do inventário completo**, para cada ano. Também calcula, por ano, os índices de diversidade e equabilidade (via `CalcIndice`): Margalef, Menhinick, McIntosh, Simpson, Shannon, Odum, QM de Jentsch e Pielou. Salva a tabela de fitossociologia em `Resultados/Tst.xlsx`.

#### `FitoBloco(dados_arvores, Anos, Area)`
Repete o cálculo acima com agregação por **Bloco**, dentro de cada ano.

#### `FitoParcela(dados_arvores, Anos, Area)`
Calcula os índices por espécie no nível de **Parcela** (dentro de Bloco, dentro de Ano). A Frequência (FA/FR) é obtida a partir da ocorrência da espécie entre as **Faixas** de cada parcela. Salva o resultado em `Resultados/Tst.xlsx`.

#### `FitoFaixa(dados_arvores, Anos, Area)`
Refina o cálculo até o nível de **Faixa** (dentro de Parcela, dentro de Bloco, dentro de Ano) — o nível mais detalhado de agregação espacial. Além de salvar a planilha, gera automaticamente, para cada índice de diversidade calculado, um gráfico de distribuição via `grafico_distribuicao_indice`.

#### `CalcIndice(...)`
Função auxiliar interna (com múltiplos métodos, um para cada nível de agregação — Geral / Bloco / Parcela / Faixa) que calcula, a partir do número de indivíduos (`N`), riqueza (`S`), número de unidades amostrais com ocorrência (`U`) e densidades relativas (`DR`), os índices de diversidade: **Margalef**, **Menhinick**, **McIntosh**, **Simpson**, **Shannon**, **Odum**, **QM de Jentsch** e **Pielou**.

### Ingresso e mortalidade

#### `Ingress(dados, Anos)`
Filtra, para cada ano em `Anos`, os registros cujo `Ano_Ingresso` corresponde ao ano em questão — ou seja, as árvores/fustes que ingressaram na parcela naquele período.

#### `Mortality(dados, Anos)`
Filtra, para cada ano, os registros de fustes mortos com base no código de fuste e na família (mesma lógica de filtragem por código usada em `dataFustes`).

#### `countGeral(dados, Anos)`
Consolida, por ano, uma contagem geral do inventário: número de Famílias, Gêneros e Espécies distintas, número de árvores vivas, número de fustes vivos, e (placeholders para) Ingresso e Mortalidade. Internamente chama `dataTrees` e `dataFustes`.

### Exportação para Excel

Módulo dedicado a salvar `DataFrame`s em `.xlsx` já formatados: cabeçalho em negrito com fundo colorido e texto centralizado, bordas finas em toda a tabela, fonte **Aptos** e largura de coluna ajustada automaticamente ao conteúdo.

#### `salvar_planilha(dados, caminho; nome_aba="Dados", cor_cabecalho="FF203764", cor_fonte_cabecalho="FFFFFFFF", ajustar_largura_colunas=true)`
Salva um único `DataFrame` em uma única aba.

#### `salvar_planilha_por_ano(dados, anos, caminho; ..., prefixo_aba="")`
Salva um `Vector{DataFrame}` com **uma aba por ano**, pareando `dados[i]` com `anos[i]` por posição.

#### `salvar_planilha_multiplas_abas(dados, nomes_abas, caminho; ...)`
Salva um `Vector{DataFrame}` com **uma aba por elemento do vetor**, nomeada conforme `nomes_abas` — útil para reunir diferentes níveis de uma mesma análise (ex.: fitossociologia geral, por parcela e por faixa) em um único arquivo.

#### `salvar_fitossociologia(resultado, caminho; coluna_ano=:Ano, coluna_ordenacao=:IVI, remover_coluna_ano=true, ...)`
Recebe um único `DataFrame` com todos os anos empilhados (contendo uma coluna de ano), separa-o internamente por ano e delega a escrita para `salvar_planilha_por_ano` — mantendo a mesma formatação visual. Por padrão, ordena cada aba de forma decrescente por `IVI`.

*Funções auxiliares internas:* `_num_para_letra_coluna`, `_estilizar_aba!` e `_ajustar_largura_colunas!` cuidam, respectivamente, da conversão de índice de coluna para letra do Excel, da aplicação do estilo padrão e do ajuste de largura das colunas.

### Gráficos

#### `grafico_distribuicao_indice(dados, indice; coluna_ano=:Ano, limite_superior=7, intervalo=1, max_colunas_grid=9, max_linhas_grid=9, cor_barra=:steelblue, mesma_escala_y=true, caminho_saida=nothing)`
Gera, com **CairoMakie**, um gráfico de barras da distribuição por classe de um índice (ex.: `:Margalef`, `:Shannon`, `:Pielou`) para cada ano presente em `dados`, organizados em um grid (até 9×9 painéis). As classes são definidas de `0` até `limite_superior`, em passos de `intervalo`, mais uma classe final `">limite_superior"`. Se `caminho_saida` for informado, salva tanto a figura com o grid completo quanto uma figura individual por ano no mesmo diretório.

*Funções auxiliares internas:* `contar_por_classe` (conta valores por faixa/classe), `_dimensoes_grid` (calcula um grid aproximadamente quadrado para *n* painéis) e `_plotar_painel_distribuicao!` (desenha um único painel do grid).

---

## Estrutura de saída (`Resultados/`)

Ao rodar o fluxo completo de análise, o Dendra organiza as saídas da seguinte forma dentro de `savepath`:

```
Resultados/
├── 1 - Dados_Anuais.xlsx          # dataTrees — uma aba por ano
├── 2 - Dados_Fustes.xlsx          # dataFustes — uma aba por ano
├── Verificação_Botânica.xlsx      # ValidateTaxonomy
├── Fitossociologia_Completa.xlsx  # FitoGeral + FitoParcela + FitoFaixa consolidados
├── Tst.xlsx                       # saída intermediária das funções Fito*
└── Gráficos/
    ├── Distribuições/             # grafico_distribuicao_indice (grid + individuais)
    ├── Taxas/{Espécies,Gêneros,Famílias}/
    ├── Índices/
    ├── Contagens/
    └── Estoques/
```

## Autores

- Renilson Lisboa Junior
- Alexandre Behling
- Afonso Figueiredo Filho
- Richardson Ribeiro

## Licença

Distribuído sob a licença **MIT**. Veja [`LICENSE`](LICENSE) para mais detalhes.