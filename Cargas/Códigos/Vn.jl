# AeroDesign ITA - Bismarck 2021
# Script para envelope de voo longitudinal
#
#--------------------------------------------
using Plots; pyplot(); PyPlot.pygui(true) # Precisamos disso para plotar

#--------------------------------------------
## Inputs
# Constantes
rho = 1.16 # Densidade do ar a 1400m de altitude-densidade
g = 9.786 # Aceleração da gravidade

# Dados da aeronave
v_stall = 12.5 # m/s
v_cruise = 18.5 # m/s
v_dive = 26.0 # m/s

Sasa = 1.12 # Área da asa, m^2
Clmax = 1.27
Clmin = -1.0
CLa = 5.0 # C_L_alpha

m = 12.2 # MTOW, kg
cma = 0.39325 # Corda média aerodinâmica, m

# Definição dos fatores de carga limites
n_pos = 2.0
n_neg = -0.4*n_pos

# Velocidade de manobra pela FAR-23
v_man = v_stall*sqrt(n_pos)

# Velocidade limite que você quer plotar no gráfico
vlim = v_dive;

#--------------------------------------------
## Contas...
## Envelope de estol
# Vamos definir funções que deem o valor do n máximo em cada velocidade
# Estol positivo
n_stall_pos(v) = rho*v^2*Sasa*Clmax/(2*m*g)
# Estol positivo
n_stall_neg(v) = rho*v^2*Sasa*Clmin/(2*m*g)

## Limites de fator de carga
# Velocidade na qual o fator de carga é n_pos em estol
v_n_pos = sqrt(n_pos*2*m*g/(rho*Sasa*Clmax))
# Velocidade na qual o fator de carga é n_neg em estol
v_n_neg = sqrt(n_neg*2*m*g/(rho*Sasa*Clmin))

## Envelope de rajada
# Relação de massa
mu = 2*m*g/(Sasa*rho*g*cma*CLa)
# Fator de alívio de rajadas
Kg = 0.88*mu/(5.3+mu)

# Função da variação do fator de carga
Dn(V,u) = Kg*CLa*rho*V.^2*Sasa*u./(2*m*g*V)



#--------------------------------------------
## Plotando
step = 0.01 # De quanto em quanto tem um ponto
vs = 0:step:vlim

# Plot das curvas de estol
# Estol positivo
p1 = plot(n_stall_pos, 0:step:v_n_pos, label = "Curvas de estol",
xlabel = "Velocidade (m/s)",
ylabel = "Fator de carga",
ylims = (-1, 2.7),
xlims = (0, 30),
linecolor = :green,
legend = :topleft)

# Pontilhando após limite do envelope
plot!(p1, n_stall_pos, v_n_pos:step:vlim, linestyle = :dash, linecolor = :green, label = "")

# Estol negativo
plot!(p1,n_stall_neg, 0:step:v_n_neg, label = "", linecolor = :green)
# Pontilhando após limite do envelope
plot!(p1, n_stall_neg, v_n_neg:step:vlim, linestyle = :dash, linecolor = :green, label = "")

# Plot dos limites de fator de carga
plot!(p1, v_n_pos:step:vlim, n_pos*ones(length(v_n_pos:step:vlim)), linecolor = :green, label = "")
plot!(p1, v_n_neg:step:vlim, n_neg*ones(length(v_n_neg:step:vlim)), linecolor = :green, label = "")

# Velocidades de interesse
plot!(p1, [v_stall v_cruise v_man v_dive], seriestype = :vline, linestyle = :dash, linecolor = :black, linewidth = 0.5, label = "")

# Fechando o envelope
plot!(p1, vlim*ones(length(n_neg:step:n_pos)), n_neg:step:n_pos, linecolor =:red, label = "Limite de velocidade")

# Envelope de rajadas
# Velocidade de rajada 4 m/s até v_cruz
plot!(p1, 0:step:v_cruise, 1 .+ Dn(0:step:v_cruise,4), linestyle = :dash, linecolor = :blue, label = "Rajada de 4 m/s")
plot!(p1, 0:step:v_cruise, 1 .- Dn(0:step:v_cruise,4), linestyle = :dash, linecolor = :blue, label = "")
# Velocidade de rajada 2 m/s até v_dive
plot!(p1, 0:step:v_dive, 1 .+ Dn(0:step:v_dive,2), linestyle = :dash, linecolor = :cyan, label = "Rajada de 2 m/s")
plot!(p1, 0:step:v_dive, 1 .- Dn(0:step:v_dive,2), linestyle = :dash, linecolor = :cyan, label = "")
# Ligando os pontos finais dessas retas
plot!(p1, [v_cruise, v_dive], [1+Dn(v_cruise,4), 1+Dn(v_dive,2)], linestyle = :dash, linecolor = :black, label = "")
plot!(p1, [v_cruise, v_dive], [1-Dn(v_cruise,4), 1-Dn(v_dive,2)], linestyle = :dash, linecolor = :black, label = "")

savefig("Diagrama_Vn.png")