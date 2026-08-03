# validacao_taxonomica.jl
# Validação dos nomes científicos/gênero/família registrados em campo
# contra a base de referência da Flora do Brasil (via taxonomia_api.jl).

"""
    validar_taxonomia(df)

Consulta a API do Reflora para cada nome científico único em `df`
(ignorando `"N.I."` e nomes terminados em `"spp."`) e compara
Gênero/Espécie/Família registrados em campo contra os retornados pela
API. Retorna um DataFrame apenas com as linhas inconsistentes ou não
encontradas.
"""
function ValidateTaxonomy(df::DataFrame, savepath::String, save::Bool = true)
    inconsistencias = DataFrame(
        Nome_Cientifico = String[],
        Gênero          = String[],
        Familia         = String[],
        Genero_api      = Union{String,Missing}[],
        Especie_api     = Union{String,Missing}[],
        Familia_api     = Union{String,Missing}[],
        Status          = String[],
    )

    for j in sort(unique(df.Nome_Cientifico))
        (j == "N.I." || contains(j, "spp.")) && continue

        r = reflora_taxon(join(split(j, " ")[1:2], " "))
        isempty(r) && continue

        if haskey(r[1], :taxon)
            status = get(r[1][:taxon], :nomenclaturalstatus, "")
            nome_corrente = r[1][:taxon][:scientificname]
        else
            status = "DESCONHECIDO"
            nome_corrente = j
        end

        # Só testa relacionamentos (sinônimos) se o nome não for já o correto
        if status != "NOME_CORRETO" || isnothing(status)
            for rel in get(r[1], :resource_relationship, [])
                nome_binomio = join(split(rel[:scientificname])[1:min(2, end)], " ")
                r_new = reflora_taxon(nome_binomio)

                if !isempty(r_new) && get(r_new[1][:taxon], :nomenclaturalstatus, "") == "NOME_CORRETO"
                    r = r_new
                    nome_corrente = r[1][:taxon][:scientificname]
                    status = "NOME_CORRETO"
                    break
                end
            end
        end

        status != "NOME_CORRETO" &&
            println("Entrada: $j → Nome válido: $nome_corrente (status: $status)")

        for row in eachrow(df[df.Nome_Cientifico.==j, :])
            if length(r) == 0 || (haskey(r[1], :matchType) && r[1][:matchType] == "NONE")
                push!(inconsistencias, (
                    String(row.Nome_Cientifico), String(row.Gênero), String(row.Familia),
                    "N.I.", "N.I.", "N.I.", "Não encontrado",
                ))
                continue
            end

            nome_api = r[1][:taxon][:scientificname]
            genero_api = ismissing(nome_api) ? missing : split(nome_api, " ")[1]
            especie_api = nome_api
            familia_api = r[1][:taxon][:family]

            genero_api = lowercase(string(row.Gênero)) == "n.i." ? "N.I." : genero_api
            especie_api = lowercase(string(row.Nome_Cientifico)) == "n.i." ? "N.I." : especie_api
            familia_api = lowercase(string(row.Familia)) == "n.i." ? "N.I." : familia_api

            erros = String[]
            nomes_iguais(row.Gênero, genero_api) || push!(erros, "Gênero")
            nomes_iguais(row.Nome_Cientifico, especie_api) || push!(erros, "Espécie")
            nomes_iguais(row.Familia, familia_api) || push!(erros, "Família")

            status_linha = isempty(erros) ? "Correto" : "Inconsistente (" * join(erros, ", ") * ")"

            push!(inconsistencias, (
                String(row.Nome_Cientifico), String(row.Gênero), String(row.Familia),
                genero_api, especie_api, familia_api, status_linha,
            ))
        end
    end
    
    if save == true
        salvar_planilha(inconsistencias, joinpath(savepath, "Resultados\\Verificação_Botânica.xlsx"))
"""        XLSX.writetable(, 
                       "Inconsistencias" => inconsistencias, 
                       overwrite = true
        )"""
    end

    return filter(x -> x.Status != "Correto", inconsistencias)
end
