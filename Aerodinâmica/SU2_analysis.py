#Codigo elaborado para automatizar a criação de malha 2D para aerofolios.
#Os arquivos .geo gerados são utilizadas dentro do Gmsh para criar a malha.
#Aerodesign - ITA - 2025
#Elaborado por: Kitassato T26
#Sinta-se livre para otimizar o codigo, criar outras versões e funcionalidades.
#Não se esqueça de registrar as melhorias para que o conhecimento não seja perdido.

import numpy as np
import subprocess # Para executar o SU2 a partir do Python
import os #Para mover os arquivos de criar uma pasta (OPCIONAL)
import shutil #Para mover os arquivos de criar uma pasta (OPCIONAL)
import time #Para avaliar o tempo de execução do SU2 (RECOMENDADO)

#Parâmetros da simulação CFD.
solver = 'INC_RANS'
Mach = 0.06 #Número de Mach - Não precisa para INC.
Re = 2.1e5 #Número de Reynolds - Não precisa para INC.
Velocidade = 30.0 #Velocidade em m/s
AOA = 5.0 #Ângulo de ataque
su2_config = f'configs/su2_{solver}.cfg'  # Caminho do arquivo de configuração

#Função para executar o SU2 com um arquivo de configuração específico

def run_su2(config, su2_binary="SU2/SU2_CFD.exe", output="output_logs/su2_output.log"):
    with open(output, "w") as log:
        process = subprocess.run(
            [su2_binary, config],
            stdout=log,
            stderr=subprocess.STDOUT
        )
    
    if process.returncode == 0:
        print("Simulação CFD via SU2 concluída com sucesso.")

        #Criar pasta de mover os arquivos para organizar - OPCIONAL

        if solver == 'INC_RANS':
            folder = f"{solver}_V{Velocidade}_A{AOA}" #Nome da pasta que será criada para armazenar os arquivos de saída do SU2.
            to_move = ["flow.vtu","history.csv","surface_flow.csv"]

        else:
            folder = f"{solver}_M{Mach}_Re{Re}"
            to_move = ["flow.vtu","history.csv","surface_flow.csv"]
        #Mover os arquivos de saída para a pasta criada.

        if not os.path.exists(folder):
            os.makedirs(folder)
        for file in to_move:
            if os.path.exists(file):
                shutil.move(file, os.path.join(folder, file))

        #Move a nova pasta para a pasta de resultados.

        if not os.path.exists("results"):
            os.makedirs("results")

        shutil.move(folder,os.path.join("results",folder))

    else:
        print("Simulação CFD via SU2 não concluída. Cagou o pau em algum lugar")
        print("Verifique o arquivo de output log para mais detalhes.")

#Executa o SU2 com as configurações especificadas.

start = time.time() # Inicia o cronômetro
print("Iniciando a simulação CFD via SU2...")
run_su2(su2_config) #Executa o SU2.
end = time.time() # Para o cronômetro
print(f"Tempo de execução: {(end - start)/60:.2f} minutos") #Mostra o tempo de execução.