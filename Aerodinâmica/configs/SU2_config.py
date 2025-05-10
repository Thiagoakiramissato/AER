#Codigo elaborado para realizar modificações no arquivo de configuração do SU2.
#Aerodesign - ITA - 2025
#Elaborado por: Kitassato T26
#Sinta-se livre para otimizar o codigo, criar outras versões e funcionalidades.
#Não se esqueça de registrar as melhorias para que o conhecimento não seja perdido.

import numpy as np

#Definir as alterações que são feitas no arquivo de configuração.

#Algumas explicações de parâmetros:

# 1. SOLVER: Método de solução do CFD. Pode ser 'INC_RANS ou 'INC_EULER'. Para a Aerodesign.
#   Caso INC_RANS: https://su2code.github.io/tutorials/Inc_Turbulent_NACA0012/

# 2. CFL_NUMBER: Determina a marcha no tempo para convergir o CFD.
#   Regra de bolso: Malha nova ou teste inicial(=0.5), 
#                   Simulação razoavelmente estável(=1.0),
#                   Malha refinada, já testada(>3.0).
#   Se fizer merda aqui o modelo pode acabar divergindo, então cuidado.

# 3. MGLEVEL: Número de níveis de malha para o método multigrid.
#   Regra de bolso: Malha nova ou teste inicial(=0),
#                   Simulação razoavelmente estável(=2),
#                   Malha refinada, já testada(>3).
#   Se fizer merda aqui o modelo pode acabar divergindo, então cuidado.

Veloc = 30.0 #Velocidade em m/s.
AOA = 10.0 #Ângulo de ataque em graus.
V = np.zeros(3) #Vetor de velocidade inicial.
V[0] = Veloc * np.cos(AOA*np.pi/180.0) #Componente X da velocidade inicial.
V[1] = Veloc * np.sin(AOA*np.pi/180.0) #Componente Y da velocidade inicial.

run = {
    'MESH_FILENAME': 'mesh/structured_alexky.su2', #Nome do arquivo de malha.
    'SOLVER': 'INC_RANS', #Metodo de solução do CFD.
    'KIND_TURB_MODEL': 'SA', #Modelo de turbulência. Pode ser 'SA' ou 'SST'.
    'INC_DENSITY_REF': 1.0,
    'INC_VELOCITY_REF': 1.0,
    'INC_TEMPERATURE_REF' : 1.0,
    'INC_VELOCITY_INIT': (V[0], V[1], 0.0), #Velocidade no caso de um escoamento incompressível.
    'REYNOLDS_NUMBER': 2.1e5,
    #'MACH_NUMBER': 0.06, #Não precisa de for INC.
    #'AOA': 5.0, #Ângulo de ataque do aerofolio. #Não precisa de for INC.
    'MARKER_EULER': 'airfoil', #Nome do grupo fisico feito na malha.
    'MARKER_FAR': 'farfield', #Nome do grupo fisico feito na malha.
    'REF_LENGTH': 1.0, #Comprimento de referência do aerofolio.
    'REF_ORIGIN_MOMENT_X' : 0.00, #X do ponto de referência para o momento.
    'REF_ORIGIN_MOMENT_Y' : 0.00, #Y do ponto de referência para o momento.
    'REF_ORIGIN_MOMENT_Z' : 0.00, #Z do ponto de referência para o momento.
    'CFL_NUMBER' : 25, #Número de CFL para o método de solução.
    'MGLEVEL' : 0, #Número de níveis de malha para o método multigrid.
    'ITER': 100000, #Número de iterações do solver.
    'CONV_RESIDUAL_MINVAL'  : -9, #Valor mínimo do resíduo para convergir.
}

#Definir o caminho dos inputs e outputs.

config = f'configs/template_{run["SOLVER"]}.cfg' #Nome de um arquivo base para o SU2.
output = f'configs/su2_{run["SOLVER"]}.cfg' #Nome da nova configuração do SU2.

#Função para realizar alterações no arquivo de configuração do SU2.

def SU2_config(input, output, new_configuration):

    new_config = [] # Lista para armazenar as novas linhas de configuração
    with open(input, 'r') as f:
        lines = f.readlines()

    for line in lines: 
        if line.strip().startswith('%') or '=' not in line: #Ignora os comentários.
            new_config.append(line) # Armazena as configurações de fato.
            continue

        param, value = line.split('=', 1)
        param = param.strip()

        if param in new_configuration: #Atualiza os valores de configuração.
            new_value = new_configuration[param]
            new_config.append(f"{param} = {new_value}\n")
        else:
            new_config.append(line)

    with open(output, 'w') as f:
        f.writelines(new_config)


#Executar a função de configuração.

SU2_config(config, output, run)
print(f"Arquivo de configuração {output} atualizado com sucesso!")


    

