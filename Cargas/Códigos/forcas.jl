# Código original em Julia. Existe uma versão em MATLAB com o mesmo nome
# Esse código é apenas para as forças nas Superficies
# Existe outro para os hinge-moments!

# COLOQUE ESSE ARQUIVO JUNTO COM A PASTA MATS! [JUNTO, NÃO DENTRO]
using MAT # Biblioteca para ler arquivos do MATLAB
using Plots # Biblioteca para gerar os gráficos

#################
# CONFIGURAÇÕES #
#################
# Seleção das condições e da superfícies
# Condições de 1 - 13 [Depende do que está sendo analisado]
condicoes = ["Mergulho","Cruzeiro","Manobra_N12","Manobra_N15"]

# Superficies: asa, eh, ev 
superficie = "asa"

#================================================================================#

# Iteração sobre as condicoes
# Uma iteração para cada gráfico de cada força [biblioteca plots funciona assim]  
# Codigo ta bem bronco mas o que importa é funcionar
# Variaveis das cargas aerodinamicas
cargas = ["Ty_$superficie", "Mx_$superficie","Qz_$superficie"]
forças = ["Momento torsor", "Momento fletor", "Força cortante"]
# Nome das forças e cargas
for i in eachindex(cargas)
    plot(0, 0, title="", minorgrid=true)
    # Nomeando o eixo x
    if superficie == "asa"
        xlabel!("Coordenada y da semiasa [m]")
    elseif superficie == "eh"
        xlabel!("Coordenada y da semienvergadura do EH [m]")
    elseif superficie == "ev"
        xlabel!("Coordenada z ao longo do EV [m]")
    end
    # Nomeando o eixo y
    if i == 1
        ylabel!("Momento torsor [N.m]")
    elseif i == 2
        ylabel!("Momento fletor [N.m]")
    elseif i == 3
        ylabel!("Força cortante [N]")
    end
    # Iterando sobre as condições

    for condicao in condicoes
        # Lendo as forças
        dados = matread("MATS/$(condicao)/$(condicao)_$(superficie).mat")
        pos = vec(dados["ys_$superficie"])
        f = vec(dados[cargas[i]])
        # Plotando forças
        plot!(pos, f, label="Condição $condicao")
    end
    savefig("$(forças[i]) $(superficie).png")
end