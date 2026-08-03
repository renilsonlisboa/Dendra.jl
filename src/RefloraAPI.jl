# taxonomia_api.jl
# Integração com o serviço web da Flora do Brasil (JBRJ/Reflora).

"""
    reflora_taxon(nome)

Consulta o serviço web da Flora do Brasil (JBRJ/Reflora) para o nome
taxonômico `nome` e retorna o JSON de resposta já parseado (via JSON3).
Lança um erro se a resposta HTTP não for bem-sucedida (status != 200).
"""
function reflora_taxon(nome::AbstractString)
    nm = HTTP.escapeuri(nome)
    url = "https://servicos.jbrj.gov.br/v2/flora/taxon/$(nm)"
    resp = HTTP.get(url)

    if resp.status == 200
        return JSON3.read(resp.body)
    else
        error("HTTP status $(resp.status); resposta: $(String(resp.body))")
    end
end

"""
    nomes_iguais(a, b)

Compara `a` e `b` ignorando `missing` e diferenças de
maiúsculas/minúsculas. Retorna `false` caso algum dos dois seja `missing`.
"""
function nomes_iguais(a, b)
    (ismissing(a) || ismissing(b)) && return false
    return lowercase(string(a)) == lowercase(string(b))
end
