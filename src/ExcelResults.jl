# planilhas.jl
# Módulo dedicado exclusivamente a salvar DataFrames em arquivos .xlsx
# já formatados (cabeçalho destacado, bordas finas, fonte profissional
# e largura de coluna ajustada ao conteúdo).

"""
    _num_para_letra_coluna(n)

Converte um número de coluna (1, 2, 3, ...) para a letra correspondente
usada em referências de célula do Excel (A, B, ..., Z, AA, AB, ...).
"""
function _num_para_letra_coluna(n::Integer)
    letras = ""
    while n > 0
        n, r = divrem(n - 1, 26)
        letras = string(Char(65 + r)) * letras
    end
    return letras
end

"""
    _estilizar_aba!(sheet, dados; cor_cabecalho, cor_fonte_cabecalho)

Aplica o estilo padrão (fonte Arial, bordas finas, cabeçalho em negrito
com fundo colorido e texto centralizado) a uma aba que já contém `dados`
escritos a partir da célula A1. Função auxiliar interna, usada tanto por
`salvar_planilha` quanto por `salvar_planilha_por_ano`, garantindo que o
estilo visual seja idêntico em ambas.
"""
function _estilizar_aba!(
    sheet,
    dados::DataFrame;
    cor_cabecalho::AbstractString,
    cor_fonte_cabecalho::AbstractString,
)
    n_linhas = nrow(dados)
    n_colunas = DataFrames.ncol(dados)
    ultima_coluna = _num_para_letra_coluna(n_colunas)
    faixa_cabecalho = "A1:$(ultima_coluna)1"
    faixa_dados = "A1:$(ultima_coluna)$(n_linhas + 1)"

    # Estilo base (fonte e bordas) para toda a tabela, incluindo o cabeçalho
    XLSX.setUniformFont(sheet, faixa_dados; name = "Aptos", size = 11)
    XLSX.setUniformBorder(sheet, faixa_dados; allsides = ["style" => "thin", "color" => "FF808080"])

    # Estilo do cabeçalho: sobrepõe o estilo base apenas na primeira linha
    XLSX.setUniformFont(sheet, faixa_cabecalho; bold = true, color = cor_fonte_cabecalho, name = "Aptos", size = 11)
    XLSX.setUniformFill(sheet, faixa_cabecalho; pattern = "solid", fgColor = cor_cabecalho)
    XLSX.setUniformAlignment(sheet, faixa_cabecalho; horizontal = "center", vertical = "center")

    return nothing
end

"""
    _ajustar_largura_colunas!(sheet, dados)

Ajusta a largura de cada coluna de `sheet` ao maior conteúdo (cabeçalho
ou dados) presente em `dados`. Função auxiliar interna, usada tanto por
`salvar_planilha` quanto por `salvar_planilha_por_ano`.
"""
function _ajustar_largura_colunas!(sheet, dados::DataFrame)
    n_colunas = DataFrames.ncol(dados)
    for c in 1:n_colunas
        letra = _num_para_letra_coluna(c)
        largura_cabecalho = length(string(names(dados)[c]))
        largura_dados = maximum(v -> ismissing(v) ? 0 : length(string(v)), dados[!, c]; init = 0)
        largura = max(largura_cabecalho, largura_dados) + 2
        XLSX.setColumnWidth(sheet, "$(letra)1"; width = largura)
    end
    return nothing
end

"""
    salvar_planilha(dados, caminho; nome_aba="Dados", cor_cabecalho="FF4472C4",
                     cor_fonte_cabecalho="FFFFFFFF", ajustar_largura_colunas=true)

Salva `dados` (um `DataFrame`) em `caminho` como um arquivo `.xlsx` com
formatação padrão: cabeçalho em negrito com fundo colorido e texto
centralizado, bordas finas em toda a tabela, fonte Arial, e largura de
coluna ajustada ao conteúdo. Cria o diretório de `caminho` caso ainda
não exista.

# Argumentos
- `dados::DataFrame`: dados a serem salvos.
- `caminho::AbstractString`: caminho completo do arquivo `.xlsx` de saída
  (use `joinpath` para montá-lo, nunca concatene `"\\\\"` manualmente).

# Palavras-chave
- `nome_aba::AbstractString = "Dados"`: nome da aba (truncado para 31
  caracteres, limite do Excel).
- `cor_cabecalho::AbstractString = "FF4472C4"`: cor de fundo do cabeçalho
  (ARGB hexadecimal, 8 dígitos).
- `cor_fonte_cabecalho::AbstractString = "FFFFFFFF"`: cor da fonte do
  cabeçalho (ARGB hexadecimal).
- `ajustar_largura_colunas::Bool = true`: se `true`, reabre o arquivo em
  modo `"rw"` para ajustar a largura das colunas ao conteúdo — isso é
  necessário porque `XLSX.setColumnWidth` exige um arquivo aberto para
  leitura e escrita simultaneamente. Para dados simples (sem fórmulas ou
  gráficos) isso é seguro; desative caso perceba qualquer problema.

# Exemplo
```julia
salvar_planilha(
    inconsistencias,
    joinpath(savepath, "Resultados", "Verificação_Botânica.xlsx");
    nome_aba = "Inconsistencias",
)
```
"""
function salvar_planilha(
    dados::DataFrame,
    caminho::AbstractString;
    nome_aba::AbstractString = "Dados",
    cor_cabecalho::AbstractString = "FF203764",
    cor_fonte_cabecalho::AbstractString = "FFFFFFFF",
    ajustar_largura_colunas::Bool = true,
)
    dir = dirname(caminho)
    (isempty(dir) || isdir(dir)) || mkpath(dir)

    nome_aba = first(nome_aba, 31)  # Excel não permite nomes de aba com mais de 31 caracteres

    XLSX.openxlsx(caminho, mode = "w") do xf
        sheet = xf[1]
        XLSX.rename!(sheet, nome_aba)
        XLSX.writetable!(sheet, dados)
        _estilizar_aba!(sheet, dados; cor_cabecalho, cor_fonte_cabecalho)
    end

    if ajustar_largura_colunas
        XLSX.openxlsx(caminho, mode = "rw") do xf
            sheet = xf[1]
            _ajustar_largura_colunas!(sheet, dados)
        end
    end

    println("Planilha salva em: $caminho")
    return caminho
end

"""
    salvar_planilha_por_ano(dados, anos, caminho; cor_cabecalho="FF4472C4",
                             cor_fonte_cabecalho="FFFFFFFF", ajustar_largura_colunas=true,
                             prefixo_aba="")

Salva `dados` (um `Vector{DataFrame}`) em `caminho` como um arquivo `.xlsx`
com **uma aba para cada ano** em `anos`. Os dois vetores são pareados por
posição: `dados[i]` é salvo na aba correspondente a `anos[i]`. Cada aba
recebe a mesma formatação padrão usada em `salvar_planilha` (cabeçalho em
negrito com fundo colorido, bordas finas, fonte Arial e largura de coluna
ajustada ao conteúdo). Cria o diretório de `caminho` caso ainda não exista.

# Argumentos
- `dados::Vector{DataFrame}`: um `DataFrame` por ano, na mesma ordem de `anos`.
- `anos::Vector{Int64}`: os anos correspondentes a cada elemento de `dados`.
- `caminho::AbstractString`: caminho completo do arquivo `.xlsx` de saída
  (use `joinpath` para montá-lo, nunca concatene `"\\\\"` manualmente).

# Palavras-chave
- `cor_cabecalho::AbstractString = "FF4472C4"`: cor de fundo do cabeçalho
  (ARGB hexadecimal, 8 dígitos).
- `cor_fonte_cabecalho::AbstractString = "FFFFFFFF"`: cor da fonte do
  cabeçalho (ARGB hexadecimal).
- `ajustar_largura_colunas::Bool = true`: se `true`, reabre o arquivo em
  modo `"rw"` para ajustar a largura das colunas de cada aba ao conteúdo.
- `prefixo_aba::AbstractString = ""`: texto opcional prefixado ao nome de
  cada aba (ex.: `"Ano_"` gera abas `"Ano_2020"`, `"Ano_2021"`, ...). O
  nome final é truncado para 31 caracteres, limite do Excel.

# Exemplo
```julia
salvar_planilha_por_ano(
    [dados_2020, dados_2021, dados_2022],
    [2020, 2021, 2022],
    joinpath(savepath, "Resultados", "Inventario_por_Ano.xlsx"),
)
```
"""
function salvar_planilha_por_ano(
    dados::Vector{DataFrame},
    anos::Vector{Int64},
    caminho::AbstractString;
    cor_cabecalho::AbstractString = "FF203764",
    cor_fonte_cabecalho::AbstractString = "FFFFFFFF",
    ajustar_largura_colunas::Bool = true,
    prefixo_aba::AbstractString = "",
)
    length(dados) == length(anos) ||
        error("`dados` e `anos` devem ter o mesmo tamanho (recebido $(length(dados)) e $(length(anos))).")
    isempty(dados) && error("`dados` não pode ser um vetor vazio.")
    allunique(anos) || error("`anos` contém valores repetidos; cada ano deve aparecer uma única vez.")

    dir = dirname(caminho)
    (isempty(dir) || isdir(dir)) || mkpath(dir)

    nomes_abas = [first(string(prefixo_aba, ano), 31) for ano in anos]

    XLSX.openxlsx(caminho, mode = "w") do xf
        for (i, (sub, nome_aba)) in enumerate(zip(dados, nomes_abas))
            sheet = i == 1 ? xf[1] : XLSX.addsheet!(xf)
            XLSX.rename!(sheet, nome_aba)
            XLSX.writetable!(sheet, sub)
            _estilizar_aba!(sheet, sub; cor_cabecalho, cor_fonte_cabecalho)
        end
    end

    if ajustar_largura_colunas
        XLSX.openxlsx(caminho, mode = "rw") do xf
            for (sub, nome_aba) in zip(dados, nomes_abas)
                sheet = xf[nome_aba]
                _ajustar_largura_colunas!(sheet, sub)
            end
        end
    end

    println("Planilha salva em: $caminho ($(length(anos)) aba(s), uma por ano)")
    return caminho
end

"""
    salvar_planilha_multiplas_abas(dados, nomes_abas, caminho; cor_cabecalho="FF4472C4",
                                    cor_fonte_cabecalho="FFFFFFFF", ajustar_largura_colunas=true)

Salva `dados` (um `Vector{DataFrame}`) em `caminho` como um arquivo `.xlsx`
com **uma aba para cada elemento do vetor**, nomeada de acordo com
`nomes_abas`. Os dois vetores são pareados por posição: `dados[i]` é salvo
na aba `nomes_abas[i]`. Útil para reunir diferentes níveis de uma mesma
análise (ex.: fitossociologia geral, por parcela, por faixa) em um único
arquivo, cada um em sua própria aba. Cada aba recebe a mesma formatação
padrão usada em `salvar_planilha` (cabeçalho em negrito com fundo
colorido, bordas finas, fonte Arial e largura de coluna ajustada ao
conteúdo). Cria o diretório de `caminho` caso ainda não exista.

# Argumentos
- `dados::Vector{DataFrame}`: um `DataFrame` por aba, na mesma ordem de `nomes_abas`.
- `nomes_abas::Vector{String}`: os nomes das abas correspondentes a cada
  elemento de `dados` (cada nome é truncado para 31 caracteres, limite
  do Excel).
- `caminho::AbstractString`: caminho completo do arquivo `.xlsx` de saída
  (use `joinpath` para montá-lo, nunca concatene `"\\\\"` manualmente).

# Palavras-chave
- `cor_cabecalho::AbstractString = "FF4472C4"`: cor de fundo do cabeçalho
  (ARGB hexadecimal, 8 dígitos).
- `cor_fonte_cabecalho::AbstractString = "FFFFFFFF"`: cor da fonte do
  cabeçalho (ARGB hexadecimal).
- `ajustar_largura_colunas::Bool = true`: se `true`, reabre o arquivo em
  modo `"rw"` para ajustar a largura das colunas de cada aba ao conteúdo.

# Exemplo
```julia
salvar_planilha_multiplas_abas(
    [fito_geral, fito_parcela, fito_faixa],
    ["Geral", "Parcela", "Faixa"],
    joinpath(savepath, "Resultados", "Fitossociologia_Completa.xlsx"),
)
```
"""
function salvar_planilha_multiplas_abas(
    dados::Vector{DataFrame},
    nomes_abas::Vector{String},
    caminho::AbstractString;
    cor_cabecalho::AbstractString = "FF203764",
    cor_fonte_cabecalho::AbstractString = "FFFFFFFF",
    ajustar_largura_colunas::Bool = true,
)
    length(dados) == length(nomes_abas) ||
        error("`dados` e `nomes_abas` devem ter o mesmo tamanho (recebido $(length(dados)) e $(length(nomes_abas))).")
    isempty(dados) && error("`dados` não pode ser um vetor vazio.")

    nomes_abas = [first(nome, 31) for nome in nomes_abas]
    allunique(nomes_abas) ||
        error("`nomes_abas` contém nomes repetidos (após truncar para 31 caracteres); cada aba precisa de um nome único.")

    dir = dirname(caminho)
    (isempty(dir) || isdir(dir)) || mkpath(dir)

    XLSX.openxlsx(caminho, mode = "w") do xf
        for (i, (sub, nome_aba)) in enumerate(zip(dados, nomes_abas))
            sheet = i == 1 ? xf[1] : XLSX.addsheet!(xf)
            XLSX.rename!(sheet, nome_aba)
            XLSX.writetable!(sheet, sub)
            _estilizar_aba!(sheet, sub; cor_cabecalho, cor_fonte_cabecalho)
        end
    end

    if ajustar_largura_colunas
        XLSX.openxlsx(caminho, mode = "rw") do xf
            for (sub, nome_aba) in zip(dados, nomes_abas)
                sheet = xf[nome_aba]
                _ajustar_largura_colunas!(sheet, sub)
            end
        end
    end

    println("Planilha salva em: $caminho ($(length(nomes_abas)) aba(s))")
    return caminho
end
"""
    salvar_fitossociologia(resultado, caminho; coluna_ano=:Ano, coluna_ordenacao=:IVI,
                            remover_coluna_ano=true, cor_cabecalho="FF4472C4",
                            cor_fonte_cabecalho="FFFFFFFF", ajustar_largura_colunas=true,
                            prefixo_aba="")

Salva o `resultado` de uma análise fitossociológica (um único `DataFrame`
com uma coluna de ano, como o retornado por `tete`) em `caminho` como um
arquivo `.xlsx` com **uma aba por ano**. Internamente separa `resultado`
por `coluna_ano` e delega a escrita para `salvar_planilha_por_ano`, então
o estilo visual (cabeçalho colorido, bordas, fonte, largura de coluna) é
idêntico ao das demais funções deste módulo.

# Argumentos
- `resultado::DataFrame`: tabela única com todos os anos empilhados,
  contendo pelo menos a coluna `coluna_ano`.
- `caminho::AbstractString`: caminho completo do arquivo `.xlsx` de saída.

# Palavras-chave
- `coluna_ano::Symbol = :Ano`: coluna usada para separar os dados em abas.
- `coluna_ordenacao::Union{Symbol, Nothing} = :IVI`: se não for `nothing`,
  cada aba é reordenada de forma decrescente por essa coluna antes de
  salvar (útil para manter as espécies de maior IVI no topo). Passe
  `nothing` para preservar a ordem original de `resultado`.
- `remover_coluna_ano::Bool = true`: se `true` (padrão), remove a coluna
  de ano de cada aba, já que a informação já está no nome da aba.
- `cor_cabecalho`, `cor_fonte_cabecalho`, `ajustar_largura_colunas`,
  `prefixo_aba`: repassados diretamente a `salvar_planilha_por_ano`.

# Exemplo
```julia
resultado = tete(dados_arvores, Anos, AreaTotal)
salvar_fitossociologia(
    resultado,
    joinpath(savepath, "Resultados", "Fitossociologia.xlsx");
    prefixo_aba = "Ano_",
)
```
"""
function salvar_fitossociologia(
    resultado::DataFrame,
    caminho::AbstractString;
    coluna_ano::Symbol = :Ano,
    coluna_ordenacao::Union{Symbol, Nothing} = :IVI,
    remover_coluna_ano::Bool = true,
    cor_cabecalho::AbstractString = "FF203764",
    cor_fonte_cabecalho::AbstractString = "FFFFFFFF",
    ajustar_largura_colunas::Bool = true,
    prefixo_aba::AbstractString = "",
)
    hasproperty(resultado, coluna_ano) ||
        error("A coluna `$coluna_ano` não existe no DataFrame informado.")

    anos::Vector{Int64} = sort(unique(Int64.(skipmissing(resultado[!, coluna_ano]))))
    isempty(anos) && error("Nenhum ano encontrado na coluna `$coluna_ano`.")

    dados = DataFrame[]
    for ano in anos
        mascara = [!ismissing(v) && Int64(v) == ano for v in resultado[!, coluna_ano]]
        sub = resultado[mascara, :]
        remover_coluna_ano && (sub = select(sub, Not(coluna_ano)))
        if coluna_ordenacao !== nothing
            sort!(sub, coluna_ordenacao, rev = true)
        end
        push!(dados, sub)
    end

    return salvar_planilha_por_ano(
        dados,
        anos,
        caminho;
        cor_cabecalho,
        cor_fonte_cabecalho,
        ajustar_largura_colunas,
        prefixo_aba,
    )
end