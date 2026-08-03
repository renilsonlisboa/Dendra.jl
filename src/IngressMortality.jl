
function Mortality(dados::DataFrame, Anos::Vector{Int64})
    dados_fustes_mortos = [DataFrame() for _ in 1:(length(Anos))]

    for i in 1:length(Anos)
        dados_fustes_mortos[i] = dados[((dados.Familia .== "Araucariaceae") .&& (
                                         dados.Código .∈ Ref(parametros_fustes))) .|| 
                                       ((dados.Familia .!= "Araucariaceae") .&& 
                                        (dados.Código .∈ Ref([0,1,2,3,4]))), :] 
    end
end

function Ingress(dados::DataFrame, Anos::Vector{Int64})
    dados_fustes_ingressos = [DataFrame() for _ in 1:(length(Anos))]

    for i in 1:length(Anos)
        dados_fustes_ingressos[i] = filter(x -> x.Ano_Ingresso == Anos[i], dados)
    end

    return dados_fustes_ingressos
end 

function countGeral(dados::DataFrame, Anos::Vector{Int64})
    ContagemGeral = DataFrame(
        Ano = Int64[],
        Famílias = Int64[],
        Gêneros = Int64[],
        Espécies = Int64[],
        Árvores_Vivas = Int64[],
        Fustes_Vivos = Int64[],
        Ingresso = Int64[],
        Mortalidade = Int64[]
    )

    dados_arvores = dataTrees(dados, "CAP", Anos)
    dados_fustes = dataFustes(dados, "CAP", Anos)

    for i in 1:length(Anos)
        AnoAtual = Anos[i]
        Familias = length(unique(dados_arvores[i].Familia))
        Generos = length(unique(dados_arvores[i].Gênero))
        Especie = length(unique(dados_arvores[i].Nome_Cientifico))
        N_arvores = size(dados_arvores[i], 1)
        N_fustes = size(dados_fustes[i], 1)

        push!(ContagemGeral, (AnoAtual, Familias, Generos, Especie, N_arvores, N_fustes,0,0))
    end

    return ContagemGeral
end