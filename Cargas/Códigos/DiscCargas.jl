using Interpolations, Plots, MAT

# Código adaptado para discretizar cargas aerodinâmicas contínuas para cargas discretas a serem utilizadas no MEF.
# O código irá receber o input de cargas em .mat ou JSON, tanto faz, e discretizará utilizando interpolações.
# Código original : Gustavo Jun Asai - Açai T23
# Adaptação do Código : Thiago Akria Missato - Kitassato T26


#Determinação dos inputs de cargas.
Caso = "Enfl 17"
Condicao = "Mergulho"
Superficie = "asa"
n = 10 #Refinamento da discretização

#Leitura dos dados .

#loads = JSON.parsefile("loads02.json")
loads = matread("MATS/$(Caso)/$(Condicao)/$(Condicao)_$(Superficie).mat")
M = loads["Mx_$(Superficie)"]
V = loads["Qz_$(Superficie)"]
T = loads["Ty_$(Superficie)"]
b = loads["ys_$(Superficie)"]

# Debugging: Print dimensions and types of inputs
println("Dimensions of b: ", size(b))
println("Dimensions of V: ", size(V))
println("Dimensions of T: ", size(T))

# Ensure b, V, and T are 1D arrays
b = vec(b)
V = vec(V)
T = vec(T)

#Determinação das posições de cargas concentradas.

Yposic = range(0, b[end], length = n)
#Yposic = [0, 0.165]

# Debugging: Print ranges to ensure compatibility
println("Range of b: ", minimum(b), " to ", maximum(b))
println("Range of Yposic: ", minimum(Yposic), " to ", maximum(Yposic))

@enum DiscType trapz stairs
disc = trapz

########

Vinterp = extrapolate(interpolate((b,), V, Gridded(Linear())), Line())
Tinterp = extrapolate(interpolate((b,), T, Gridded(Linear())), Line())

Vres = Vinterp.(Yposic)
Tres = Tinterp.(Yposic)

if disc == trapz
    markershape = :none #:circle
    linetype = :path
elseif disc == stairs
    markershape = :none
    linetype = :steppost
end

Plots.scalefontsizes()
Plots.scalefontsizes(1.3)

plot(b, V, label="Carregamento aerodinâmico", minorgrid=true, legend=:topright, framestyle=:box, linewidth=2)
plot!(Yposic, Vres, markershape=markershape, label="Carregamento aplicado", linetype=linetype, linewidth=2)
ylabel!("Força cortante [N]")
xlabel!("Coordenada y da semi-envergadura da asa [m]")
savefig("DiscData/$(Caso)_$(Condicao)_V.png")

plot(b, T, label="Carregamento aerodinâmico", minorgrid=true, legend=:bottomright, framestyle=:box, linewidth=2)
plot!(Yposic, Tres, markershape=markershape, label="Carregamento aplicado", linetype=linetype, linewidth=2)
ylabel!("Momento torsor [N.m]")
xlabel!("Coordenada y da semi-envergadura da asa [m]")
savefig("DiscData/$(Caso)_$(Condicao)_T.png")

open("DiscData/$(Caso)_$(Condicao)_Discretizacao.txt", "w") do f
    println(f, "        V [N]     T [N.m]   b(m)")
    for i = 1:length(Yposic)-1
        print(f, "$i      $(round(Vres[i]-Vres[i+1], digits=3))     $(round(Tres[i]-Tres[i+1], digits=3))   $(Yposic[i]) \n")
    end
end


println("        V [N]     T [N.m]")
for i = 1:length(Yposic)-1
    println("$i      $(round(Vres[i]-Vres[i+1], digits=3))     $(round(Tres[i]-Tres[i+1], digits=3))")
end