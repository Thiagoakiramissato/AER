%% Script para tirar as cargas aerodinâmicas na aeronave a partir do AVL
% Mago T-23
% Originalmente desenvolvido para LEV20 - projeto Inês
% Adaptado para asas voadoras => Viva-Voz T-27
% AeroDesign ITA

% O objetivo desse script é facilitar o cálculo das cargas aerodinâmicas
% a partir do AVL.

% Alguns comentários sobre o código
% Na pasta precisa ter o avl.exe, airfoils, arquivo .avl e uma pasta
% chamada MATS

% Como usar:
% 1 - Inserir dados da aeronave
% 2 - Inserir condição de voo e nomear condição
% 3 - Rodar
% Após rodar, ele exibirá uma tela com uma visão geral de tudo que foi
% calculado e também salvará um .mat com os esforços na pasta ~/MATS/nome
% da condição. Para plotar os gráficos para o relatório, é necessário um
% script auxiliar que pega esses .mats das condições críticas e plota tudo
% junto.

clear
% Constantes
[~, ~, ~, rho] = atmoscoesa(1400) % Colocar altitude-densidade considerada no projeto (SJC 1400m) -> analisar veracidades 
g = 9.786;

%% Inputs
% Nome do AVL
name = "MTN"; % Nome do arquivo .avl (sem o .avl) -> mudar para os AVL de acordo com o docs
mass = "MTN"; % Nome do arquivo .mass (sem o .mass)

y_asa = 80; % Número de seções da asa ao longo da envergadura no .avl
% Você vê isso assim no arquivo .avl:
% ############# - Asa
% SURFACE
% wing
% 8 1.0 80.0 -1.5
%       /\ esse é o número de seções ao longo da envergadura da asa
% Para saber mais sobre isso, ler a documentação do AVL (Importante).

%Dados da anv
m = 12.2; % Massa da aeronave, em kg

% Fatores de carga limite. Servem apenas para facilitar na hora de inserir
% os casos.
n_max = 2;
n_min = -1;

% (logo no primeira parte do AVL)
Sasa = 1.12; % Área de referência da asa, a partir do AVL, m^2 
cref = 0.39325; % Corda de referência (do AVL), m
b = 3.1; % Envergadura m

clmax = 1.27; %(Possibilidade de mudança)

% As velocidades servem só para facilitar na hora de inserir
v_stall = sqrt(2*m*g/(rho*Sasa*clmax));
v_dec = 1.1*v_stall;
v_cruz = 18.5;                % pessoal de desempenho
v_dive = 1.4*v_cruz;            % FAR 23
v_man = v_stall*sqrt(n_max);    % FAR 23

% Se a porcentagem da corda da asa onde a longarina está variar ao longo da
% envergadura, precisa de uma variável que contenha a porcentagem da corda a
% cada seção. Se não variar, só inserir a porcentagem mesmo.

% load x_perc_cx.mat; %Porcentagem da asa onde está a longarina
% x_perc = xs_cx;

x_perc = 0.25;              % Visto no CAD que o tubo está no quarto de corda
%OBS: eu preciso fazer isso porque o AVL fornece o valor do momento TORSOR
%no quarto de corda, e preciso transferir o novo momento para a posição
%definida acima xp (M0 -> M1)

% ESQUEMA
%    BA (bordo de ataque)
%    BF (bordo de fuga)
%    M_0 (resultado do momento no quarto de corda fornecido pelo AVL)
%    M_1 (momento resultante na longarina da aeronave, local que realmente
%    precisamos do valor para as análises de ESTRUTURA)
%    x_0 |------> (quarto de corda do AVL)  
%    x_p |---->   (local em que a longarina se encontra na aeronave real)
%         ________________________
%        /     . .                 \
%   BA   \_____|_|_________________/ BF
%              | |
%              | |
%            M_1  M_0
%

%% AVL
%CONFIGURAÇÃO

%Configurações do vôo

%Nome da condição de Vôo (serve apenas para nomear o arquivo resultante e deixar tudo certinho para quando for salvar)
cond = 'Cruzeiro';

%Velocidade escolhida
v_esc = v_cruz; 

%Reto e nivelado ou não
ret_e_niv = true; % True = C1, false = C2. Se tiver fator de carga é false.
n =  2; %Fator de carga. Só faz diferença se não for reto e nivelado
CL = 2*n*m*g/(rho*Sasa*v_esc^2);

%Profundor
trim_prof = true; %Se sim, trima o profundor, se não, bota o ângulo
ang_prof = -15; %graus

%Aileron
trim_ail = true; %Se sim, trima o aileron, se não, bota o ângulo
ang_ail = -5; %graus

% OBS: Atentar ao referencial do AVL de ângulo das superfícies de controle!
%(referencial pensando no AVL -> qual ângulo leme, aileron ,...)

%Beta (ângulo de guinada)
beta = 0;

%Roll Rate
rollrate = 0; % rad/s
rollrate = rollrate*b/(2*v_esc); %Normalizando

% Rodando AVL (Criar o arquivo de texto que vai jogar no AVL)

if exist(strcat(name,'.fs'), 'file') == 2
  delete(strcat(name,'.fs'));
end
if exist(strcat(name,'.hm'), 'file') == 2
  delete(strcat(name,'.hm'));
end
if exist(strcat(name,'.run'), 'file') == 2
  delete(strcat(name,'.run'));
end

frun = fopen(strcat(name,'.run'),'W');
fprintf(frun,'LOAD %s.avl\n',name);
fprintf(frun,'MASS %s.mass\n',mass);
fprintf(frun,'MSET 0\n',name);
fprintf(frun,'OPER\n');
%Config de vôo
if ret_e_niv
    fprintf(frun,'C1\n'); %Tipo de voo
    % O seguinte ta como comment pq já são inclusas no .mass. Se não tiver
    % .mass, descomentar e definir as variáveis antes de rodar.
%     fprintf(frun,'M %.3f\n',m); %massa
%     fprintf(frun,'D %.3f\n',rho); %densidade do ar
%     fprintf(frun,'G %.3f\n',g); %gravidade
%     fprintf(frun,'X %.3f\n',x_cm); %x do cm
%     fprintf(frun,'Z %.3f\n',z_cm); %z do cm
    fprintf(frun,'V %.3f\n',v_esc); %velocidade escolhida
else
    fprintf(frun,'C2\n');
%     fprintf(frun,'M %.3f\n',m);
%     fprintf(frun,'D %.3f\n',rho);
%     fprintf(frun,'G %.3f\n',g);
%     fprintf(frun,'X %.3f\n',x_cm);
%     fprintf(frun,'Z %.3f\n',z_cm);
    fprintf(frun,'C %.3f\n',CL); %CL, incluindo fator de carga
    fprintf(frun,'V %.3f\n',v_esc);
end
fprintf(frun,'\n');
%PROFUNDOR
fprintf(frun,'D1\n');
if trim_prof
    fprintf(frun,'PM 0\n');
else
    fprintf(frun,'D1\n');
    fprintf(frun,'%f\n',ang_prof);
end
%AILERON
fprintf(frun,'D2\n');
if trim_ail
    fprintf(frun,'RM 0\n');
else
    fprintf(frun,'D2\n');
    fprintf(frun,'%f\n',ang_ail);
end
fprintf(frun,'B\n');
fprintf(frun,'B\n');
fprintf(frun,'%f\n', beta);
fprintf(frun,'R\n R\n %f\n', rollrate);
fprintf(frun,'X\n');
%Strip Forces (Forças nas seções)
fprintf(frun,'fs\n');
fprintf(frun,'%s',name,'.fs');
fprintf(frun,'\n');
%Hinge Moments (Momentos de dobradiça na superfície de controle)
fprintf(frun,'hm\n');
fprintf(frun,'%s',name,'.hm');
fprintf(frun,'\n');
fprintf(frun,'\n\n');
fprintf(frun,'QUIT\n');
fclose(frun);

dos(strcat('avl < ', name,'.run'));

%% Leitura do arquivo de strip forces
n1 = 21; % linha do arquivo .fs onde começa as coisas da asa
opts_w = delimitedTextImportOptions('DataLines',[n1 n1+y_asa-1],'Delimiter',' ','ConsecutiveDelimitersRule','join','LeadingDelimitersRule','ignore','TrailingDelimitersRule','ignore');
opts_w = setvartype(opts_w, 'double');
fs = strcat(name,'.fs');

fs_asa = readmatrix(fs,opts_w)';
ys_asa = fs_asa(2,:);

%que o espaçamento tem que estar igualmente espaçado pra poder usar
%linspace, se não tem que colocar os espaçamentos do jeito que está no AVL
%% Leitura do arquivo de hinge moments
hm = fopen(strcat(name,'.hm'),'r');
%Pula as primeiras 6 linhas do arquivo
for i = 1:6
    fgetl(hm);
end
Chinge_ail=fscanf(hm,' aileron          %f\n',1);
Chinge_prof=fscanf(hm,' elevator          %f\n',1);
fclose(hm);


%%
%-----------------------------------------------
%Fazendo as contas...
%-----------------------------------------------



%ASA
% Tratamento dos dados
M = tratar_fs_asa(fs_asa, v_esc, x_perc, rho);

Qz_asa = M(1,:);
Mx_asa = M(2,:);
Ty_asa = M(3,:);

%Hinge Moments-------------- (é adimensionalizado, aí faz essas
%multiplicações para tornar o momento DIMENSIONAL novamente)
Hm_ail = Chinge_ail*Sasa*cref*v_esc^2*rho/2;
Hm_ail = Hm_ail*100/g;

Hm_prof = Chinge_prof*Sasa*cref*v_esc^2*rho/2;
Hm_prof = Hm_prof*100/g;


%%
%-----------------------------------------------
%Impressão do resultado (para conferir se não tem merda no meio do caminho)
%-----------------------------------------------
tiledlayout(4,3)

ax1 = nexttile;
plot(ax1, ys_asa, Qz_asa)
title(ax1,'Força Cortante ASA');
ax2 = nexttile;
plot(ax2, ys_asa, Mx_asa)
title(ax2,'Momento Fletor ASA');
ax3 = nexttile;
plot(ax3, ys_asa, Ty_asa)
title(ax3,'Momento Torçor ASA');

x_bar = [1, 2];
y_bar = [Hm_ail, Hm_prof];
ax10 = nexttile([1 2]);
bar(ax10, x_bar, y_bar);
title(ax10,'HM (aileron, profundor)')

%% Me diz as coisas na raiz (também para fazer conferências)
disp("---------ASA---------");
disp("Qz");
disp(Qz_asa(1));
disp("Mx");
disp(Mx_asa(1));
disp("Ty");
disp(Ty_asa(1));
disp("-------HM-------");
disp("Profundor");
disp(Hm_prof);
disp("Leme");
disp("Aileron");
disp(Hm_ail);

copiar_planilha = [Qz_asa(1) Mx_asa(1) Ty_asa(1) Hm_prof Hm_ail];

%%
%-----------------------------------------------
%Salvando .mats
%-----------------------------------------------
mkdir MATS;
path = [pwd '\MATS'];
mkdir(path, cond);
path = [path '\' cond];

save(fullfile(path,strcat(cond,'_asa.mat')), 'Qz_asa', 'Mx_asa', 'Ty_asa', 'ys_asa');
save(fullfile(path,strcat(cond,'_Hm_ail.mat')),'Hm_ail');
save(fullfile(path,strcat(cond,'_Hm_prof.mat')),'Hm_prof');


%% funções

%função que ajeita os strip forces da asa (caixão da asa muda a % ao longo
%da corda)
function M = tratar_fs_asa(fs_analise, v_esc, x_perc, rho)
    fs_analise = transpose(fs_analise);
    
    %A posição de cada elemento da asa
    ys=fs_analise(:, 2);
    %Cordas de cada elemento
    cs=fs_analise(:, 3);
    %Cl de cada elemento
    Cls=fs_analise(:, 8);
    %Coeficiente de momento de cada elemento
    Cms=fs_analise(:, 11);
    %Transferência do momento para a posição do caixão
    x_perc_t = transpose(x_perc);
    Cms=Cms-Cls.*(0.25-x_perc_t);

    for i=1:length(ys)-1
        %Força cortante
        Qz(i)=trapz(ys(i:length(ys)), cs(i:length(ys)).*Cls(i:length(ys))*rho*v_esc^2/2);
        %Momento fletor
        Mx(i)=trapz(ys(i:length(ys)), (ys(i:length(ys))-ys(i)).*cs(i:length(ys)).*Cls(i:length(ys))*rho*v_esc^2/2);
        %Momento torsor
        Ty(i)=trapz(ys(i:length(ys)), cs(i:length(ys)).*Cms(i:length(ys))*rho*v_esc^2/2);
    end

    Qz(length(ys))=0.0;
    Mx(length(ys))=0.0;
    Ty(length(ys))=0.0;
    
    M(1,:) = Qz;
    M(2,:) = Mx;
    M(3,:) = Ty;
end