import numpy as np

airfoil = 'alexky.txt' #Determinar o nome do aerofolio.
data = np.loadtxt(airfoil)

x_coord = data[:, 0]
y_coord = data[:, 1]
ref = 0.01 #Refinamento local da malha.
far_ref = 0.1 #Refinamento do espaço distante.
radius = 10 #Raio do espaço distante.

with open('airfoil.geo', 'w') as f: #Escrever o arquivo de saida

    #Determinar a geometria do aerofolio no formato do gmsh.
   
    for i in range(len(x_coord)): #Escrever os pontos do aerofolio e do espaço distante.
        x = x_coord[i]
        y = y_coord[i]
        f.write(f'Point({i}) = {{{x}, {y}, 0, {ref}}};\n') #Pontos do aerofolio.
        f.write(f'Point({i+500}) = {{{radius*np.cos(i*2*np.pi/len(x_coord))}, {radius*np.sin(i*2*np.pi/len(x_coord))}, 0, {far_ref}}};\n') #Pontos do espaço distante.
    f.write(f'Point(1000) = {{0, 0, 0, {far_ref}}};\n') #Centro do espaço distante.

    for i in range(len(x_coord)-1): #Ligar os pontos do aerofolio e do espaço distante.
        f.write(f'Line({i}) = {{{i}, {i+1}}};\n') #Ligar os pontos do aerofolio.
        f.write(f'Circle({i+500}) = {{{i+500}, 1000, {i+1+500}}};\n') #Ligar os pontos do espaço distante.

    f.write(f'Line({len(x_coord)-1}) = {{{len(x_coord)-1}, 0}};\n') #Fechar o contorno do aerofolio
    f.write(f'Circle({len(x_coord)}) = {{{len(x_coord)-1+500},1000 , 500}};\n') #Fechar o contorno do aerofolio

    #f.write(f'Point({len(x_coord)}) = {{0, 0, 0, {refine}}};\n') #Centro do espaço distante.
    #for i in range(4):
    #    f.write(f'Point({len(x_coord)+1+i}) = {{{radius*np.cos(i*np.pi/2)}, {radius*np.sin(i*np.pi/2)}, 0, {refine}}};\n') #Pontos do espaço distante.

    #for i in range(3): #Ligar os pontos do espaço distante.
    #    f.write(f'Circle({len(x_coord)+i+5}) = {{{len(x_coord)+i+1}, {len(x_coord)}, {len(x_coord)+i+2}}};\n')
    #    if i == 2:
    #        f.write(f'Circle({len(x_coord)+i+6}) = {{{len(x_coord)+4}, {len(x_coord)}, {len(x_coord)+1}}};\n') #Fechar o contorno do espaço distante.

    #Determinar a superfície para ser malhada.        