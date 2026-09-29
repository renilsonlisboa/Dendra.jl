function FitoGeral(dados_arvores::Vector{DataFrame}, Anos::Vector{Int64}, Area::Int64)
    Fitossociologia = DataFrame(
        Ano = Int64[],
        Especie = String[],
        N = Float64[],
        Fustes = Float64[],
        DA = Float64[],
        DR = Float64[],
        DoA = Float64[],
        DoR = Float64[],
        FA = Float64[],
        FR = Float64[],
        IVI = Float64[],
        AB = Float64[],
        U = Float64[],
    )

    Indices = DataFrame()

    for i in 1:length(Anos)
        df = dados_arvores[i]
        especies = unique(df.Nome_Cientifico)
        col = Symbol("DAP_", Anos[i])

        AB_vec     = Float64[]
        U_vec      = Float64[]
        N_vec      = Float64[]
        Fustes_vec = Float64[]
        DA_vec     = Float64[]
        DoA_vec    = Float64[]
        FA_vec     = Float64[]

        for especie in especies
            sub = filter(:Nome_Cientifico => ==(especie), df)

            AB     = (pi*(sum(sub[:, col].^2)))/40000             # área basal total da espécie
            N      = nrow(sub)/Area                # nº de indivíduos
            Fustes = nrow(sub)/Area           # nº de fustes (se aplicável)
            U      = length(unique(sub.Bloco)) # nº de parcelas em que a espécie ocorre

            DA  = N           # densidade absoluta
            DoA = (AB / Area)          # dominância absoluta
            FA  = (U / Area)*100   # frequência absoluta

            push!(AB_vec, AB)
            push!(U_vec, U)
            push!(N_vec, N)
            push!(Fustes_vec, Fustes)
            push!(DA_vec, DA)
            push!(DoA_vec, DoA)
            push!(FA_vec, FA)
        end

        soma_DA = sum(DA_vec)
        soma_DoA = sum(DoA_vec)
        soma_FA = sum(FA_vec)

        for (j, especie) in enumerate(especies)
            DR = 100 * DA_vec[j] / soma_DA
            DoR = 100 * DoA_vec[j] / soma_DoA
            FR = 100 * FA_vec[j] / soma_FA
            IVI = DR + DoR + FR  

            push!(Fitossociologia, (
                Ano = Int64(Anos[i]),
                Especie = especie,
                AB = AB_vec[j],
                U = U_vec[j],
                N = N_vec[j],
                Fustes = Fustes_vec[j],
                DA = DA_vec[j],
                DR = DR,
                DoA = DoA_vec[j],
                DoR = DoR,
                FA = FA_vec[j],
                FR = FR,
                IVI = IVI,
            ))
        end

        DR_ind = filter(x -> x.Ano == Anos[i], Fitossociologia).DR ./ 100
        S_ind = length(especies)
        N_ind = size(df, 1)
        U_ind = sqrt(sum(filter(x -> x.Ano == Anos[i], Fitossociologia).U))

        append!(Indices, (CalcIndice(Anos[i], N_ind, S_ind, U_ind, DR_ind)))
    end

    select!(Fitossociologia, Not([:U, :AB]))
    
    for col in names(Fitossociologia, Float64)
        Fitossociologia[!, col] = round.(Fitossociologia[!, col], digits = 2)
    end
    
    sort!(Fitossociologia, [:Ano, :IVI], rev = [false, true])
    
    salvar_planilha(Fitossociologia, joinpath(pwd(), "Resultados\\Tst.xlsx"))
    return Fitossociologia, Indices
end

function CalcIndice(Ano::Int64, N::Int64, S::Int64, U::Float64, DR::Vector{Float64})
    Indices = DataFrame(
        Ano        = Int64[],
        Margalef   = Float64[],
        Menhinick  = Float64[],
        McIntosh   = Float64[],
        Simpson    = Float64[],
        Shannon    = Float64[],
        Odum       = Float64[],
        QM_Jentsch = Float64[],
        Pielou     = Float64[]
    )

    Margalef = round((S - 1) / log(N), digits = 3)
    Menhinick = round(S / (sqrt(N)), digits=3)
    McIntosh = round((N - U) / (N - (sqrt(N))), digits = 3)
    Simpson = round(sum(DR.^2), digits=3)
    Shannon = round(-sum(DR .* log.(DR)), digits = 3)
    Odum = round((S) / (log(N)), digits=3)
    QM_Jentsch = round(S / N, digits=3)
    Pielou = round((Shannon/log(S)), digits=3)

    push!(Indices, (
            Ano = Ano,
            Margalef = Margalef,
            Menhinick = Menhinick,
            McIntosh = McIntosh,
            Simpson = Simpson,
            Shannon = Shannon,
            Odum = Odum,
            QM_Jentsch = QM_Jentsch,
            Pielou = Pielou
        )
    )
end

function CalcIndice(Ano::Int64, Bloco::Int64, N::Int64, S::Int64, U::Float64, DR::Vector{Float64})
    Indices = DataFrame(
        Ano        = Int64[],
        Bloco      = Int64[],
        Margalef   = Float64[],
        Menhinick  = Float64[],
        McIntosh   = Float64[],
        Simpson    = Float64[],
        Shannon    = Float64[],
        Odum       = Float64[],
        QM_Jentsch = Float64[],
        Pielou     = Float64[]
    )

    Margalef = round((S - 1) / log(N), digits = 3)
    Menhinick = round(S / (sqrt(N)), digits=3)
    McIntosh = round((N - U) / (N - (sqrt(N))), digits = 3)
    Simpson = round(sum(DR.^2), digits=3)
    Shannon = round(-sum(DR .* log.(DR)), digits = 3)
    Odum = round((S) / (log(N)), digits=3)
    QM_Jentsch = round(S / N, digits=3)
    Pielou = round((Shannon/log(S)), digits=3)

    push!(Indices, (
            Ano = Ano,
            Bloco = Bloco,
            Margalef = Margalef,
            Menhinick = Menhinick,
            McIntosh = McIntosh,
            Simpson = Simpson,
            Shannon = Shannon,
            Odum = Odum,
            QM_Jentsch = QM_Jentsch,
            Pielou = Pielou
        )
    )
end

function CalcIndice(Ano::Int64, Bloco::Int64, Parcela::Int64, N::Int64, S::Int64, U::Float64, DR::Vector{Float64})
    Indices = DataFrame(
        Ano        = Int64[],
        Bloco      = Int64[],
        Parcela    = Int64[],
        Margalef   = Float64[],
        Menhinick  = Float64[],
        McIntosh   = Float64[],
        Simpson    = Float64[],
        Shannon    = Float64[],
        Odum       = Float64[],
        QM_Jentsch = Float64[],
        Pielou     = Float64[]
    )

    Margalef = round((S - 1) / log(N), digits = 3)
    Menhinick = round(S / (sqrt(N)), digits=3)
    McIntosh = round((N - U) / (N - (sqrt(N))), digits = 3)
    Simpson = round(sum(DR.^2), digits=3)
    Shannon = round(-sum(DR .* log.(DR)), digits = 3)
    Odum = round((S) / (log(N)), digits=3)
    QM_Jentsch = round(S / N, digits=3)
    Pielou = round((Shannon/log(S)), digits=3)

    push!(Indices, (
            Ano = Ano,
            Bloco = Bloco,
            Parcela = Parcela,
            Margalef = Margalef,
            Menhinick = Menhinick,
            McIntosh = McIntosh,
            Simpson = Simpson,
            Shannon = Shannon,
            Odum = Odum,
            QM_Jentsch = QM_Jentsch,
            Pielou = Pielou
        )
    )
end

function CalcIndice(Ano::Int64, Bloco::Int64, Parcela::Int64, Faixa::Int64, N::Int64, S::Int64, U::Float64, DR::Vector{Float64})
    Indices = DataFrame(
        Ano        = Int64[],
        Bloco      = Int64[],
        Parcela    = Int64[],
        Faixa      = Int64[],
        Margalef   = Float64[],
        Menhinick  = Float64[],
        McIntosh   = Float64[],
        Simpson    = Float64[],
        Shannon    = Float64[],
        Odum       = Float64[],
        QM_Jentsch = Float64[],
        Pielou     = Float64[]
    )

    Margalef = round((S - 1) / log(N), digits = 3)
    Menhinick = round(S / (sqrt(N)), digits=3)
    McIntosh = round((N - U) / (N - (sqrt(N))), digits = 3)
    Simpson = round(sum(DR.^2), digits=3)
    Shannon = round(-sum(DR .* log.(DR)), digits = 3)
    Odum = round((S) / (log(N)), digits=3)
    QM_Jentsch = round(S / N, digits=3)
    Pielou = round((Shannon/log(S)), digits=3)

    push!(Indices, (
            Ano = Ano,
            Bloco = Bloco,
            Parcela = Parcela,
            Faixa = Faixa,
            Margalef = Margalef,
            Menhinick = Menhinick,
            McIntosh = McIntosh,
            Simpson = Simpson,
            Shannon = Shannon,
            Odum = Odum,
            QM_Jentsch = QM_Jentsch,
            Pielou = Pielou
        )
    )
end

function Phytosociology(dados_arvores::Vector{DataFrame}, Anos::Vector{Int64}, Area::Int64)
    Fitossociologia = DataFrame(
        Ano = Int64[],
        Bloco = Int64[],
        Especie = String[],
        N = Float64[],
        Fustes = Float64[],
        DA = Float64[],
        DR = Float64[],
        DoA = Float64[],
        DoR = Float64[],
        FA = Float64[],
        FR = Float64[],
        IVI = Float64[],
        AB = Float64[],
        U = Float64[],
    )
    
    Indices = DataFrame()

    for i in 1:length(Anos)
        df = dados_arvores[i]
        col = Symbol("DAP_", Anos[i])
        blocos = unique(df.Bloco)

        for bloco in blocos
            sub_bloco = filter(:Bloco => ==(bloco), df)
            especies = unique(sub_bloco.Nome_Cientifico)
            parcelas = length(unique(sub_bloco.Parcela))

            AB_vec     = Float64[]
            U_vec      = Float64[]
            N_vec      = Float64[]
            Fustes_vec = Float64[]
            DA_vec     = Float64[]
            DoA_vec    = Float64[]
            FA_vec     = Float64[]

            for especie in especies
                sub = filter(:Nome_Cientifico => ==(especie), sub_bloco)

                AB     = (pi*(sum(sub[:, col].^2)))/40000   # área basal total da espécie no bloco
                N      = nrow(sub)/Area                      # nº de indivíduos por área do bloco
                Fustes = nrow(sub)/Area                       # nº de fustes por área do bloco
                U      = length(unique(sub.Parcela))          # nº de parcelas do bloco em que a espécie ocorre

                DA  = N
                DoA = (AB / Area)
                FA  = (U / parcelas)*100

                push!(AB_vec, AB)
                push!(U_vec, U)
                push!(N_vec, N)
                push!(Fustes_vec, Fustes)
                push!(DA_vec, DA)
                push!(DoA_vec, DoA)
                push!(FA_vec, FA)
            end

            soma_DA  = sum(DA_vec)
            soma_DoA = sum(DoA_vec)
            soma_FA  = sum(FA_vec)

            for (j, especie) in enumerate(especies)
                DR  = 100 * DA_vec[j] / soma_DA
                DoR = 100 * DoA_vec[j] / soma_DoA
                FR  = 100 * FA_vec[j] / soma_FA
                IVI = DR + DoR + FR

                push!(Fitossociologia, (
                    Ano = Int64(Anos[i]),
                    Bloco = bloco,
                    Especie = especie,
                    AB = AB_vec[j],
                    U = U_vec[j],
                    N = N_vec[j],
                    Fustes = Fustes_vec[j],
                    DA = DA_vec[j],
                    DR = DR,
                    DoA = DoA_vec[j],
                    DoR = DoR,
                    FA = FA_vec[j],
                    FR = FR,
                    IVI = IVI,
                ))
            end

        DR_ind = filter(x -> x.Ano == Anos[i] && x.Bloco == bloco, Fitossociologia).DR ./ 100
        S_ind = length(especies)
        N_ind = size(filter(x -> x.Bloco == bloco , df), 1)
        U_ind = sqrt(sum(filter(x -> x.Ano == Anos[i], Fitossociologia).U))

        append!(Indices, (CalcIndice(Anos[i], bloco, N_ind, S_ind, U_ind, DR_ind)))
        end
    end

    select!(Fitossociologia, Not([:U, :AB]))

    for col in names(Fitossociologia, Float64)
        Fitossociologia[!, col] = round.(Fitossociologia[!, col], digits = 2)
    end

    sort!(Fitossociologia, [:Ano, :Bloco, :IVI], rev = [false, false, true])

    salvar_planilha(Fitossociologia, joinpath(pwd(), "Resultados\\Tst.xlsx"))

    return Fitossociologia,Indices
end

function Phytosociology(dados_arvores::Vector{DataFrame}, Anos::Vector{Int64}, Area::Float64)
    Fitossociologia = DataFrame(
        Ano = Int64[],
        Bloco = Int64[],
        Parcela = Int64[],
        Especie = String[],
        N = Float64[],
        Fustes = Float64[],
        DA = Float64[],
        DR = Float64[],
        DoA = Float64[],
        DoR = Float64[],
        FA = Float64[],
        FR = Float64[],
        IVI = Float64[],
        AB = Float64[],
        U = Float64[],
    )

    Indices = DataFrame()

    for i in 1:length(Anos)
        df = dados_arvores[i]
        col = Symbol("DAP_", Anos[i])
        blocos = unique(df.Bloco)

        for bloco in blocos
            sub_bloco = filter(:Bloco => ==(bloco), df)
            especies_bloco = unique(sub_bloco.Nome_Cientifico)
            parcelas = unique(sub_bloco.Parcela)

            for parcela in parcelas
                sub_parcela = filter(:Parcela => ==(parcela), sub_bloco)
                especies = unique(sub_parcela.Nome_Cientifico)
                faixas = length(unique(sub_parcela.Faixa))    

                AB_vec     = Float64[]
                N_vec      = Float64[]
                Fustes_vec = Float64[]
                DA_vec     = Float64[]
                DoA_vec    = Float64[]
                FA_vec     = Float64[]
                U_vec      = Float64[]

                for especie in especies
                    sub = filter(:Nome_Cientifico => ==(especie), sub_parcela)
                    AB     = (pi*(sum(sub[:, col].^2)))/40000
                    N      = nrow(sub)/Area
                    Fustes = nrow(sub)/Area
                    U = length(unique(sub.Faixa))

                    DA  = N
                    DoA = (AB / Area)
                    FA = (U /faixas)*100

                    push!(AB_vec, AB)
                    push!(N_vec, N)
                    push!(Fustes_vec, Fustes)
                    push!(DA_vec, DA)
                    push!(DoA_vec, DoA)
                    push!(FA_vec, FA)
                    push!(U_vec, U)
                end

                soma_DA  = sum(DA_vec)
                soma_DoA = sum(DoA_vec)
                soma_FA = sum(FA_vec)

                for (j, especie) in enumerate(especies)
                    DR  = 100 * DA_vec[j] / soma_DA
                    DoR = 100 * DoA_vec[j] / soma_DoA
                    FR  = 100 * FA_vec[j]/ soma_FA
                    IVI = DR + DoR + FR

                    push!(Fitossociologia, (
                        Ano = Int64(Anos[i]),
                        Bloco = bloco,
                        Parcela = parcela,
                        Especie = especie,
                        AB = AB_vec[j],
                        U = U_vec[j],
                        N = N_vec[j],
                        Fustes = Fustes_vec[j],
                        DA = DA_vec[j],
                        DR = DR,
                        DoA = DoA_vec[j],
                        DoR = DoR,
                        FA = FA_vec[j],
                        FR = FR,
                        IVI = IVI,
                    ))
                end

                DR_ind = filter(x -> x.Ano == Anos[i], Fitossociologia).DR ./ 100
                S_ind = length(especies)
                N_ind = size(filter(x -> x.Bloco == bloco && x.Parcela == parcela , df), 1)
                U_ind = sqrt(sum(filter(x -> x.Ano == Anos[i], Fitossociologia).U))

                append!(Indices, (CalcIndice(Anos[i], bloco, parcela, N_ind, S_ind, U_ind, DR_ind)))
            end
        end
    end

    select!(Fitossociologia, Not([:U, :AB]))

    for col in names(Fitossociologia, Float64)
        Fitossociologia[!, col] = round.(Fitossociologia[!, col], digits = 2)
    end

    sort!(Fitossociologia, [:Ano, :Bloco, :Parcela, :IVI], rev = [false, false, false, true])

    salvar_planilha(Fitossociologia, joinpath(pwd(), "Resultados\\Tst.xlsx"))

    return Fitossociologia, Indices
end

function Phytosociology(dados_arvores::Vector{DataFrame}, Anos::Vector{Int64}, Area::Float64)
    Fitossociologia = DataFrame(
        Ano = Int64[],
        Bloco = Int64[],
        Parcela = Int64[],
        Faixa = Int64[],
        Especie = String[],
        N = Float64[],
        Fustes = Float64[],
        DA = Float64[],
        DR = Float64[],
        DoA = Float64[],
        DoR = Float64[],
        FA = Float64[],
        FR = Float64[],
        IVI = Float64[],
        AB = Float64[],
        U = Float64[],
    )

    Indices = DataFrame()

    for i in 1:length(Anos)
        df = dados_arvores[i]
        col = Symbol("DAP_", Anos[i])
        blocos = unique(df.Bloco)

        for bloco in blocos
            sub_bloco = filter(:Bloco => ==(bloco), df)
            parcelas = unique(sub_bloco.Parcela)

            for parcela in parcelas
                sub_parcela = filter(:Parcela => ==(parcela), sub_bloco)
                faixas = unique(sub_parcela.Faixa)

                for faixa in faixas
                    sub_faixa = filter(:Faixa => ==(faixa), sub_parcela)
                    especies = unique(sub_faixa.Nome_Cientifico)

                    AB_vec     = Float64[]
                    N_vec      = Float64[]
                    Fustes_vec = Float64[]
                    DA_vec     = Float64[]
                    DoA_vec    = Float64[]
                    FA_vec     = Float64[]
                    U_vec      = Float64[]

                    for especie in especies
                        sub = filter(:Nome_Cientifico => ==(especie), sub_faixa)
                        
                        n_faixas = length(unique(sub.Faixa))

                        AB     = (pi*(sum(sub[:, col].^2)))/40000
                        N      = nrow(sub)/Area
                        Fustes = nrow(sub)/Area
                        U      = length(unique(sub.Faixa))  # sempre 1 dentro de uma única faixa
                        DA  = N
                        DoA = (AB / Area)
                        FA  = (U / n_faixas)*100

                        push!(AB_vec, AB)
                        push!(N_vec, N)
                        push!(Fustes_vec, Fustes)
                        push!(DA_vec, DA)
                        push!(DoA_vec, DoA)
                        push!(FA_vec, FA)
                        push!(U_vec, U)
                    end

                    soma_DA  = sum(DA_vec)
                    soma_DoA = sum(DoA_vec)
                    soma_FA  = sum(FA_vec)

                    for (j, especie) in enumerate(especies)
                        DR  = 100 * DA_vec[j] / soma_DA
                        DoR = 100 * DoA_vec[j] / soma_DoA
                        FR  = 100 * FA_vec[j] / soma_FA
                        IVI = DR + DoR + FR

                        push!(Fitossociologia, (
                            Ano = Int64(Anos[i]),
                            Bloco = bloco,
                            Parcela = parcela,
                            Faixa = faixa,
                            Especie = especie,
                            AB = AB_vec[j],
                            U = U_vec[j],
                            N = N_vec[j],
                            Fustes = Fustes_vec[j],
                            DA = DA_vec[j],
                            DR = DR,
                            DoA = DoA_vec[j],
                            DoR = DoR,
                            FA = FA_vec[j],
                            FR = FR,
                            IVI = IVI,
                        ))
                    end
                    
                    DR_ind = filter(x -> x.Ano == Anos[i] && x.Bloco == bloco && x.Parcela == parcela && x.Faixa == faixa, Fitossociologia).DR ./ 100
                    S_ind = length(especies)
                    N_ind = size(filter(x -> x.Bloco == bloco && x.Parcela == parcela && x.Faixa == faixa, df), 1)
                    U_ind = sqrt(sum(filter(x -> x.Ano == Anos[i] && x.Bloco == bloco && x.Parcela == parcela && x.Faixa == faixa, Fitossociologia).U))

                    append!(Indices, (CalcIndice(Anos[i], bloco, parcela, faixa, N_ind, S_ind, U_ind, DR_ind)))
                end
            end
        end
    end

    for col in names(Fitossociologia, Float64)
        Fitossociologia[!, col] = round.(Fitossociologia[!, col], digits = 2)
    end

    sort!(Fitossociologia, [:Ano, :Bloco, :Parcela, :Faixa, :IVI], rev = [false, false, false, false, true])

    salvar_planilha(Fitossociologia, joinpath(pwd(), "Resultados\\Tst.xlsx"))
    
    for name in select(Indices[2], Not(["Ano", "Bloco", "Parcela", "Faixa"]))
        grafico_distribuicao_indice(Indices, Symbol("$name");                                                                                             
           caminho_saida = joinpath(pwd(), "Resultados", "Gráficos",                                                                                   
                                     "Distribuições", "$(name).png"))
    end
    return Fitossociologia, Indices
end


function Phytosociology(
    dados_arvores::Vector{DataFrame}, 
    Anos::Vector{Int64}, 
    Area::Float64)
end