using MAT # Biblioteca para ler arquivos do MATLAB
using Plots # Biblioteca para gerar os gráficos

#################
# CONFIGURAÇÕES #
#################
# Seleção das condições
condicoes = [2, 3, 5, 7, 10, 11, 12, 13]

# Superfícies analisadas
superficies = ["ail", "leme", "prof"]
global h_crit_ail = 1 # Condição crítica para a superfície de aileron
global h_crit_prof = 1 # Condição crítica para a superfície de profundor
global h_crit_leme = 1 # Condição crítica para a superfície de leme
lista = [] # Lista para armazenar os dados dos Hinge-Moments

# Definição da struct para armazenar os momentos
struct HingeMoment
    condicao::Int
    ail::Float64
    leme::Float64
    prof::Float64
end

# Iteração sobre as condições
for i in eachindex(condicoes)
    condicao = condicoes[i]
    # Lendo os dados das forças a partir dos arquivos .mat
    ail = matread("MATS/condicao$(condicao)/condicao$(condicao)_Hm_ail.mat")
    prof = matread("MATS/condicao$(condicao)/condicao$(condicao)_Hm_prof.mat")
    leme = matread("MATS/condicao$(condicao)/condicao$(condicao)_Hm_leme.mat")

    # Criando a struct com os dados lidos
    h = HingeMoment(condicao, abs(ail["Hm_ail"]), abs(leme["Hm_leme"]), abs(prof["Hm_prof"]))
    
    # Adicionando o momento à lista
    push!(lista, h)

    # Atualizando a condição crítica para cada superfície
    if condicao == condicoes[1]
        continue
    end
    global h_crit_ail = (lista[h_crit_ail].ail < h.ail) ? i : h_crit_ail
    global h_crit_prof = (lista[h_crit_prof].prof < h.prof) ? i : h_crit_prof
    global h_crit_leme = (lista[h_crit_leme].leme < h.leme) ? i : h_crit_leme

end

# Configuração do gráfico
p = plot(layout=(length(condicoes), 1), size=(650, 800), minorgrid=true) # Configura o tamanho e o layout do gráfico
ylims!(0,4.7)
yticks!(0:3.5:4.7)

# Criação dos gráficos de barras
for i in eachindex(lista)
    item = lista[i]
    bar!(p[i], ["Aileron"], [item.ail], label="", legend=false, color=(i == h_crit_ail ? :red : :blue), title=(i == 1 ? "Momentos de dobradiça [kgf . cm]" : ""), ylabel="Cond. $(item.condicao)", xlabel="")
    annotate!(p[i], [(0.5, item.ail+0.6, text(string(round(item.ail, digits=2)), :center, 8, :black))])

    bar!(p[i], ["Profundor"], [item.prof], label="", legend=false, color=(i == h_crit_prof ? :red : :blue))
    annotate!(p[i], [(1.95, item.prof+0.6, text(string(round(item.prof, digits=2)), :center, 8, :black))])

    bar!(p[i], ["Leme"], [item.leme], label="", legend=false, color=(i == h_crit_leme ? :red : :blue))
    annotate!(p[i], [(3.35, item.leme+0.6, text(string(round(item.leme, digits=2)), :center, 8, :black))])
end

# Exibindo o gráfico
savefig("Hinge moments críticos.png")
