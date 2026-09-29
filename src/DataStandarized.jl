"""
    extrair_periodos(dados)

Identifica as colunas `CAP_AAAA`/`DAP_AAAA`, extrai os Anos de medição
e monta os rótulos de período entre medições consecutivas.
Retorna a tupla `(Anos, periodos)`.
"""
function select_periods(dados::DataFrame, Var::String)
    titulos = filter(n -> occursin(Var, n), names(dados))
    Anos = parse.(Int, replace.(titulos, "$(Var)_" => ""))
    periodos = ["$(Anos[p]) - $(Anos[p+1])" for p in 1:(length(Anos)-1)]
    return Anos, periodos
end

function dataTrees(dados::DataFrame, Var::String, Anos::Vector{Int64})
    dados_arvores = [DataFrame() for _ in 1:(length(Anos))]
    
    for i in 1:length(Anos)
        col = Symbol(Var, "_", Anos[i])
        dapcol = Symbol("DAP", "_", Anos[i])
        dados_arvores[i] = filter(x -> !ismissing(x[col]) && x.Fuste == 1, dados)
        
        if Var == "CAP"
            rename!(dados_arvores[i], col => "DAP_$(Anos[i])")

            transform!(dados_arvores[i], dapcol => ByRow(x -> round(x/pi, digits=2)) => Symbol("DAP_$(Anos[i])"))
        end
    end

    salvar_planilha_por_ano(dados_arvores, Anos, joinpath(pwd(), "Resultados\\1 - Dados_Anuais.xlsx"))
    return dados_arvores
end  

function dataStem(dados::DataFrame, Var::String,Anos::Vector{Int64}; parametros_fustes::Vector{Int64})
    dados_fustes = [DataFrame() for _ in 1:length(Anos)]
    especies_distintas = unique(skipmissing(dados.Nome_Cientifico))

    for i in 1:length(Anos)
        col = Symbol(Var, "_", Anos[i])
        dapcol = Symbol("DAP_", Anos[i])

        dados_arvores_aux = DataFrame()
        for especie in especies_distintas
            filtered_rows = filter(
                row ->
                    !ismissing(row.Nome_Cientifico) &&
                    !ismissing(row.Familia) &&
                    row.Nome_Cientifico == especie &&
                    !contains(row[col], "Ingresso") &&
                    !contains(row[col], "Morta") &&
                    !contains(row[col], "Sem") &&
                    !contains(row[col], "Mudou") &&
                    !contains(row[col], "Eliminada"),
                dados,
            )
            dados_arvores_aux = vcat(dados_arvores_aux, filtered_rows)
        end

        transform!(
            dados_arvores_aux,
            col => ByRow(x -> round(parse(Float64, String(x)) / pi, digits = 2)) => dapcol,
        )

        dados_fustes[i] = dados_arvores_aux[
            ((dados_arvores_aux.Familia .== "Araucariaceae") .&& (dados_arvores_aux.Código .∈ Ref(parametros_fustes))) .||
            ((dados_arvores_aux.Familia .!= "Araucariaceae") .&& (dados_arvores_aux.Código .∈ Ref([0, 1, 2, 3, 4]))),
            :,
        ]
    end

    salvar_planilha_por_ano(dados_fustes, Anos, joinpath(pwd(), "Resultados\\2 - Dados_Fustes.xlsx"))
    return dados_fustes
end