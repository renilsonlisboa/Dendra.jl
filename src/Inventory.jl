function NativeInventory(dados::DataFrame, Var::String, savepath::String, save::Bool)

    criar_estrutura_diretorios(savepath)

    ValidateTaxonomy(dados, savepath, save)

    dataTrees(dados, "CAP", Anos)
end


