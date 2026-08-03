# graficos.jl
# Gráficos de distribuição por classe (ex.: Índice de Margalef por
# faixa de valores), com um painel por ano organizado em um grid,
# usando CairoMakie.

"""
    contar_por_classe(valores, limite_superior; intervalo=1)

Conta quantos elementos de `valores` caem em cada classe de largura
`intervalo`, de 0 até `limite_superior` (classes fechadas à esquerda e
abertas à direita, ex.: `"0 |- 1"`, `"1 |- 2"`, ...), mais uma classe
final `">limite_superior"` para os valores que o ultrapassam.
`missing` é ignorado.

Retorna a tupla `(rotulos, contagens)`.
"""
function contar_por_classe(valores::AbstractVector, limite_superior::Real; intervalo::Real = 1)
    _fmt(x) = isinteger(x) ? string(Int(x)) : string(x)

    limites_inferiores = 0:intervalo:(limite_superior-intervalo)
    rotulos = [_fmt(li) * " |- " * _fmt(li + intervalo) for li in limites_inferiores]
    push!(rotulos, ">" * _fmt(limite_superior))

    contagens = zeros(Int, length(rotulos))
    for v in valores
        (ismissing(v) || v < 0) && continue
        idx = v >= limite_superior ? length(rotulos) : floor(Int, v / intervalo) + 1
        contagens[idx] += 1
    end

    return rotulos, contagens
end

"""
    _dimensoes_grid(n, max_colunas, max_linhas)

Calcula um grid aproximadamente quadrado com `n` painéis, respeitando
`max_colunas` e `max_linhas`. Lança erro se `n` não couber nesse limite.
"""
function _dimensoes_grid(n::Integer, max_colunas::Integer, max_linhas::Integer)
    ncolunas = min(max_colunas, ceil(Int, sqrt(n)))
    nlinhas = ceil(Int, n / ncolunas)

    if nlinhas > max_linhas
        throw(ArgumentError(
            "Não é possível organizar $n painéis em um grid de até $(max_linhas)x$(max_colunas). " *
            "Aumente max_linhas_grid/max_colunas_grid ou gere os gráficos em mais de uma figura.",
        ))
    end

    return nlinhas, ncolunas
end

"""
    _plotar_painel_distribuicao!(posicao, indice, ano, rotulos, contagens;
                                  cor_barra, y_max, mesma_escala_y)

Cria, na `posicao` informada (uma célula de `Figure` ou a própria
`Figure`), o eixo com o gráfico de barras de um único ano, sem linhas
de grade e com os rótulos numéricos acima das barras formatados como
inteiros. Função auxiliar compartilhada entre o grid completo e os
gráficos individuais por ano.
"""
function _plotar_painel_distribuicao!(
    posicao,
    indice::Symbol,
    ano,
    rotulos,
    contagens;
    cor_barra,
    y_max,
    mesma_escala_y::Bool,
)
    ax = Axis(
        posicao;
        title = "Índice de $(string(indice)) - $ano",
        xlabel = "Índices",
        ylabel = "Faixas por Classe",
        xticks = (1:length(rotulos), rotulos),
        xgridvisible = false,
        ygridvisible = false,
    )

    barplot!(
        ax,
        1:length(rotulos),
        contagens;
        color = cor_barra,
        bar_labels = :y,
        label_formatter = x -> string(round(Int, x)),
    )
    mesma_escala_y && ylims!(ax, 0, y_max)

    return ax
end

"""
    grafico_distribuicao_indice(dados, indice; coluna_ano=:Ano, limite_superior=7, intervalo=1,
                                 max_colunas_grid=9, max_linhas_grid=9, cor_barra=:steelblue,
                                 mesma_escala_y=true, caminho_saida=nothing)

Gera, com CairoMakie, um gráfico de barras da distribuição por classe
de `dados[!, indice]` para cada ano em `dados[!, coluna_ano]`, com um
painel por ano organizado em um grid de até `max_linhas_grid` ×
`max_colunas_grid` (padrão 9×9).

As classes vão de 0 até `limite_superior` em passos de `intervalo`,
mais uma classe final `">limite_superior"` — ajuste esses dois
parâmetros conforme a escala típica do índice (ex.: para o Pielou, que
varia de 0 a 1, use `limite_superior = 1, intervalo = 0.1`).

Os painéis não exibem linhas de grade, e os rótulos numéricos acima
das barras são formatados como inteiros.

Retorna o objeto `Figure`. Se `caminho_saida` for informado, a figura
com o grid completo também é salva nesse caminho (ex.:
`"Resultados/Gráficos/Distribuições/Margalef.png"`), criando o
diretório se necessário. Além disso, cada ano é salvo individualmente,
no mesmo diretório, com o ano anexado ao nome do arquivo (ex.:
`"Margalef_2020.png"`).

# Palavras-chave
- `coluna_ano::Symbol = :Ano`: coluna usada para separar os painéis.
- `limite_superior::Real = 7`, `intervalo::Real = 1`: definição das classes.
- `max_colunas_grid::Int = 9`, `max_linhas_grid::Int = 9`: tamanho máximo do grid.
- `cor_barra = :steelblue`: cor das barras.
- `mesma_escala_y::Bool = true`: usa a mesma escala do eixo Y (com folga de 15%)
  em todos os painéis, para facilitar a comparação entre anos.
- `caminho_saida::Union{Nothing,AbstractString} = nothing`: caminho para salvar a figura
  com o grid completo e, individualmente, cada ano.

# Exemplo
```julia
fig = grafico_distribuicao_indice(calculo_indices_geral, :Margalef;
                                   caminho_saida = joinpath(diretorio_saida, "Resultados", "Gráficos",
                                                             "Distribuições", "Margalef.png"))
```
"""
function grafico_distribuicao_indice(
    dados::DataFrame,
    indice::Symbol;
    coluna_ano::Symbol = :Ano,
    limite_superior::Real = 7,
    intervalo::Real = 1,
    max_colunas_grid::Int = 9,
    max_linhas_grid::Int = 9,
    cor_barra = :steelblue,
    mesma_escala_y::Bool = true,
    caminho_saida::Union{Nothing,AbstractString} = nothing,
)
    anos = sort(unique(dados[!, coluna_ano]))
    n = length(anos)
    n == 0 && throw(ArgumentError("Não há valores em `dados[!, $coluna_ano]`"))

    nlinhas, ncolunas = _dimensoes_grid(n, max_colunas_grid, max_linhas_grid)

    distribuicoes = [
        contar_por_classe(dados[dados[!, coluna_ano].==ano, indice], limite_superior; intervalo)
        for ano in anos
    ]

    y_max = mesma_escala_y ? maximum(maximum(contagens) for (_, contagens) in distribuicoes) * 1.15 : nothing

    fig = Figure(size = (500 * ncolunas, 380 * nlinhas))

    for (i, ano) in enumerate(anos)
        linha = div(i - 1, ncolunas) + 1
        coluna = mod(i - 1, ncolunas) + 1
        rotulos, contagens = distribuicoes[i]

        _plotar_painel_distribuicao!(
            fig[linha, coluna],
            indice,
            ano,
            rotulos,
            contagens;
            cor_barra,
            y_max,
            mesma_escala_y,
        )
    end

    if !isnothing(caminho_saida)
        dir = dirname(caminho_saida)
        (isempty(dir) || isdir(dir)) || mkpath(dir)
        save(caminho_saida, fig)
        println("Gráfico salvo em: $caminho_saida")

        nome_base, extensao = splitext(basename(caminho_saida))
        for (i, ano) in enumerate(anos)
            rotulos, contagens = distribuicoes[i]

            fig_individual = Figure(size = (700, 500))
            _plotar_painel_distribuicao!(
                fig_individual[1, 1],
                indice,
                ano,
                rotulos,
                contagens;
                cor_barra,
                y_max,
                mesma_escala_y,
            )

            caminho_individual = joinpath(dir, "$(nome_base)_$(ano)$(extensao)")
            save(caminho_individual, fig_individual)
            println("Gráfico salvo em: $caminho_individual")
        end
    end

    return fig
end
