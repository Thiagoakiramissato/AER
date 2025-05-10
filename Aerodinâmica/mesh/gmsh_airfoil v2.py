#Codigo elaborado para automatizar a criação de malha 2D para aerofolios.
#Os arquivos .geo gerados são utilizadas dentro do Gmsh para criar a malha.
#Aerodesign - ITA - 2025
#Elaborado por: Kitassato T26
#Sinta-se livre para otimizar o codigo, criar outras versões e funcionalidades.
#Não se esqueça de registrar as melhorias para que o conhecimento não seja perdido.

import numpy as np
import gmsh #API do Gmsh para Python.

#Importar  aerofolio - ABERTO, ou seja, sem bordo de fuga fechado.
airfoil = 'airfoils/alexky.dat' #Determinar o diretório do aerofolio.
data = np.loadtxt(airfoil)
x_coord = data[:, 0]
y_coord = data[:, 1]

#Determinar parametros da malha.
ref = 0.003 #Refinamento local da malha.
near_ref = 0.1 #Refinamento no espaço proximo.
far_ref = 1.0 #Refinamento do espaço distante.
near_radius = 2.0 #Raio do espaço proximo.
far_radius = 30 #Raio do espaço distante.

#Contagem para os pontos e curvas do arquivo .geo
point = 0
curve = 0

#Consideração feitas para a geração da malha.

#1. Visto que a analise é bidimensional, o eixo z não é considerado. Todo z = 0.
#2. O ponto 1000 é o centro do espaço distante, o numero 1000 foi um valor genérico, poderia ser qualquer outro valor.
#   contanto que não houvesse conflito de indices com os demais pontos.
#3. Não é necessário refinar a malha no espaço distante, visto que o mesmo não é analisado. 
#   O valor de refinamento do espaço distante é apenas para garantir que a malha não seja muito grande.
#4. O final do código está integrado com o Gmsh, para gerar a malha 2D do aerofolio para o SU2.
#   caso seja outro CFD, mude o tipo do output. Não sei se precisa ter o Gmsh instalado, mas acho que sim.

with open('mesh/airfoil.geo', 'w') as f: #Escrever o arquivo de saida

    #Determinar a geometria do aerofolio e do espaço distante no formato do Gmsh.
   
    f.write('//-----------Definicao do aerofolio-----------\n\n')
    for i in range(len(x_coord)): #Escrever os pontos do aerofolio
        x = x_coord[i]
        y = y_coord[i]
        f.write(f'Point({point}) = {{{x}-0.5, {y}, 0, {ref}}};\n') #Pontos do aerofolio.
        point = point+1

    for i in range(len(x_coord)-1): #Ligar os pontos do aerofolio
        f.write(f'Line({curve}) = {{{i}, {i+1}}};\n') #Ligar os pontos do aerofolio.
        curve = curve+1
    f.write(f'Line({curve}) = {{{len(x_coord)-1}, 0}};\n') #Fechar o contorno do aerofolio
    curve = curve+1

    f.write(f'Point(1000) = {{0, 0, 0, {far_ref}}};\n') #Centro do espaço.

    f.write('\n//-----------Definicao do espaco proximo-----------\n\n')

    for i in range(4): #Escrever os pontos do espaço proximo.
        f.write(f'Point({point}) = {{{near_radius*np.cos(i*np.pi/2)}, {near_radius*np.sin(i*np.pi/2)}, 0, {near_ref}}};\n')
        point = point+1

    for i in range(3): #Ligar os pontos do espaço proximo.
        f.write(f'Circle({curve}) = {{{point-1-i}, 1000, {point-2-i}}};\n')
        curve = curve+1
        if i == 2: #Fechar o contorno do espaço proximo.
            f.write(f'Circle({curve}) = {{{point-2-i}, 1000, {point-1}}};\n')
            curve = curve+1

    f.write('\n//-----------Definicao do espaco distante-----------\n\n')

    for i in range(4): #Escrever os pontos do espaço distante.
        f.write(f'Point({point}) = {{{far_radius*np.cos(i*np.pi/2)}, {far_radius*np.sin(i*np.pi/2)}, 0, {far_ref}}};\n')
        point = point+1

    for i in range(3): #Ligar os pontos do espaço distante.
        f.write(f'Circle({curve}) = {{{point-1-i}, 1000, {point-2-i}}};\n')
        curve = curve+1
        if i == 2: #Fechar o contorno do espaço distante.
            f.write(f'Circle({curve}) = {{{point-2-i}, 1000, {point-1}}};\n')
            curve = curve+1

    #Determinar a superfície para ser malhada.

    f.write('\n//-----------Definicao das superficies-----------\n\n')

    f.write(f'Curve Loop(1) = {({curve-4,curve-3,curve-2,curve-1})};\n') #Curva do espaço distante.
    f.write(f'Curve Loop(2) = {({curve-8,curve-7,curve-6,curve-5})};\n') #Curva do espaço proximo.
    curve_indices = ', '.join([str(i) for i in range(len(x_coord))])  # Gera uma lista de índices das curvas
    f.write(f'Curve Loop(3) = {{{curve_indices}}};\n')  # Curva do aerofolio.
    f.write(f'Plane Surface(1) = {{1,2}};\n') #Superficie do espaço distante.
    f.write(f'Plane Surface(2) = {{2,3}};\n') #Superficie do espaço proximo.

    f.write('\n//-----------Definicao dos grupos fisicos-----------\n\n')

    #Determinar os grupos fisicos do problema para aplicar condições de contorno no SU2.
    f.write(f'Physical Curve("farfield") = {({curve-4,curve-3,curve-2,curve-1})};\n') #Grupo fisico do espaço distante.
    f.write(f'Physical Curve("airfoil")= {{{curve_indices}}};\n') #Grupo fisico do aerofolio.
    f.write(f'Physical Surface("domain") = {{1,2}};\n') #Grupo fisico do dominio.

#Integração com o Gmsh para gerar a malha para o SU2.

gmsh.initialize() #Iniciar o Gmsh.
gmsh.open("mesh/airfoil.geo") #Abrir o arquivo .geo.
gmsh.model.geo.synchronize() #Sincronizar o modelo.
gmsh.model.mesh.generate(1) #Gerar a malha !D para o aerofolio.
gmsh.model.mesh.generate(2) #Gerar a malha 2D para o aerofolio.
gmsh.write("mesh/mesh.su2") #Escrever o arquivo de malha para o SU2.
gmsh.finalize()

#Correção de bug que eu não sei porque acontece.
#Por alguma razão o Gmsh quando cria a malha cria um grupo fisico a mais que buga o SU2.
#esse grupo nunca foi declarado, mas o Gmsh cria ele mesmo assim, então eu removi manual.

def corrigir(input_file, output_file, marker_to_remove):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("NMARK="):
            nmark_line_index = len(new_lines)
            nmark = int(line.split("=")[1].strip())
            new_lines.append(line)  # será atualizado depois
            i += 1
            continue

        if line.startswith("MARKER_TAG="):
            marker_name = line.split("=")[1].strip()
            if marker_name == marker_to_remove:
                i += 1  # pula MARKER_ELEMS
                elems = int(lines[i].split("=")[1].strip())
                i += 1 + elems  # pula as linhas de elementos também
                nmark -= 1  # atualiza contador
                continue
            else:
                new_lines.append(line)
                i += 1
                new_lines.append(lines[i])  # MARKER_ELEMS
                elems = int(lines[i].split("=")[1].strip())
                i += 1
                for _ in range(elems):
                    new_lines.append(lines[i])
                    i += 1
        else:
            new_lines.append(line)
            i += 1

    # Atualiza o valor de NMARK
    for j in range(len(new_lines)):
        if new_lines[j].startswith("NMARK="):
            new_lines[j] = f"NMARK= {nmark}\n"
            break

    with open(output_file, 'w') as f:
        f.writelines(new_lines)

corrigir("mesh/mesh.su2", "mesh/mesh.su2", "PhysicalLine0") #Corrigir o arquivo de malha para o SU2.