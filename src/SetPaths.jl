# diretorios.jl
# Criação da estrutura de pastas de resultados (gráficos, taxas, índices, etc.)

"""
    criar_estrutura_diretorios(diretorio_saida)

Cria a estrutura de pastas de resultados dentro de `diretorio_saida`,
caso ainda não existam. `mkpath` é idempotente, então não há problema
em chamar esta função repetidamente.
"""
function criar_estrutura_diretorios(diretorio_saida::AbstractString)
    pastas = [
        "Resultados/Gráficos",
        "Resultados/Gráficos/Taxas",
        "Resultados/Gráficos/Taxas/Espécies",
        "Resultados/Gráficos/Taxas/Gêneros",
        "Resultados/Gráficos/Taxas/Famílias",
        "Resultados/Gráficos/Índices",
        "Resultados/Gráficos/Contagens",
        "Resultados/Gráficos/Estoques",
        "Resultados/Gráficos/Distribuições",
    ]

    for pasta in pastas
        caminho = joinpath(diretorio_saida, pasta)
        isdir(caminho) || mkpath(caminho)
    end

    println("Estrutura de diretórios pronta em: $diretorio_saida")

    return nothing
end
