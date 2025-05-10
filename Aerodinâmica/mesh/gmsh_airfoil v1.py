#Codigo elaborado para automatizar a criação de malha 2D para aerofolios.
#Os arquivos .geo gerados são utilizadas dentro do Gmsh para criar a malha.
#Aerodesign - ITA - 2025
#Elaborado por: Kitassato T26
#Sinta-se livre para otimizar o codigo, criar outras versões e funcionalidades.
#Não se esqueça de registrar as melhorias para que o conhecimento não seja perdido.

import numpy as np

#Importar  aerofolio
airfoil = 'airfoils/alexky.txt' #Determinar o diretório do aerofolio.
data = np.loadtxt(airfoil) 
x_coord = data[:, 0]
y_coord = data[:, 1]

#Determinar parametros da malha.
ref = 0.01 #Refinamento local da malha.
far_ref = 0.5 #Refinamento do espaço distante.
radius = 10 #Raio do espaço distante.

#Contagem para os pontos e curvas do arquivo .geo
point = 0
curve = 0

#Consideração feitas para a geração da malha.
#1. Visto que a analise é bidimensional, o eixo z não é considerado. Todo z = 0.
#2. O ponto 1000 é o centro do espaço distante, o numero 1000 foi um valor genérico, poderia ser qualquer outro valor.
#   contanto que não houvesse conflito de indices com os demais pontos.
#3. Não é necessário refinar a malha no espaço distante, visto que o mesmo não é analisado. 
#   O valor de refinamento do espaço distante é apenas para garantir que a malha não seja muito grande.

with open('airfoil.geo', 'w') as f: #Escrever o arquivo de saida

    #Determinar a geometria do aerofolio e do espaço distante no formato do Gmsh.
   
    for i in range(len(x_coord)): #Escrever os pontos do aerofolio
        x = x_coord[i]
        y = y_coord[i]
        f.write(f'Point({point}) = {{{x}, {y}, 0, {ref}}};\n') #Pontos do aerofolio.
        point = point+1

    for i in range(4): #Escrever os pontos do espaço distante.
        f.write(f'Point({point}) = {{{radius*np.cos(i*np.pi/2)}, {radius*np.sin(i*np.pi/2)}, 0, {far_ref}}};\n')
        point = point+1
    f.write(f'Point(1000) = {{0, 0, 0, {far_ref}}};\n') #Centro do espaço distante.

    for i in range(len(x_coord)-1): #Ligar os pontos do aerofolio e do espaço distante.
        f.write(f'Line({curve}) = {{{i}, {i+1}}};\n') #Ligar os pontos do aerofolio.
        curve = curve+1
    f.write(f'Line({curve}) = {{{len(x_coord)-1}, 0}};\n') #Fechar o contorno do aerofolio
    curve = curve+1

    for i in range(3): #Ligar os pontos do espaço distante.
        f.write(f'Circle({curve}) = {{{i+len(x_coord)}, 1000, {i+1+len(x_coord)}}};\n')
        curve = curve+1
        if i == 2: #Fechar o contorno do espaço distante.
            f.write(f'Circle({curve}) = {{{len(x_coord)+3}, 1000, {len(x_coord)}}};\n')
            curve = curve+1

    #Determinar a superfície para ser malhada.

    f.write(f'Curve Loop(1) = {({point-4,point-3,point-2,point-1})};\n') #Ligar os pontos do aerofolio e do espaço distante.
    curve_indices = ', '.join([str(i) for i in range(len(x_coord))])  # Gera uma lista de índices das curvas
    f.write(f'Curve Loop(2) = {{{curve_indices}}};\n')  # Escreve o Curve Loop no arquivo  
    f.write(f'Plane Surface(1) = {{1,2}};\n') #Determinar a superficie do aerofolio.

    #Determinar os grupos fisicos do problema para aplicar condições de contorno no SU2.
    f.write(f'Physical Curve("airfoil")= {{{curve_indices}}};\n') #Grupo fisico do aerofolio.