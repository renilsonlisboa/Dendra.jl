module Dendra
    
using DataFrames
using HTTP
using JSON3
using XLSX
using CSV
using CairoMakie


include("RefloraAPI.jl")
include("TaxonomicValidation.jl")
include("ExcelResults.jl")
include("SetPaths.jl")
include("Inventory.jl")
include("DataStandarized.jl")
include("Fito.jl")
include("IngressMortality.jl")
include("Charts.jl")

export inventario_nativas,
       reflora_taxon,
       ValidateTaxonomy,
       criar_estrutura_diretorios,
       NativeInventory,
       salvar_planilha_por_ano,
       salvar_fitossociologia,
       salvar_planilha,
       FitoGeral,
       FitoBlocos,
       FitoParcela,
       FitoFaixa,
       countFamily,
       dataFustes,
       dataTrees,
       grafico_distribuicao_indice
end
