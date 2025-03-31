tic
clc
clear
close all

syms V omega

%% Entradas 
% seção típica
a_EA = -0.15; % posição do eixo elástico por unidade de semicorda
b = 0.127; % semicorda
m_w = 4.7174; % massa da seção de asa
r_theta = 0.0791; % raio de giração
I_w = r_theta^2*m_w; % momento de inércia de massa
x_cg_w = 0.0318; % posição do centro de massa em relação ao eixo elástico
% propriedades estruturais
f_h = 8.8968; % frequência natural do modo de flexão
wn_h = 2*pi*f_h;
K_h = wn_h^2*m_w;
g_h = 0;
C_h = g_h*K_h/wn_h;

f_phi = 10.2018; % frequência natural do modo de torção
wn_phi = 2*pi*f_phi;
K_phi = wn_phi^2*I_w;
g_phi = 0;
C_phi = g_phi*K_phi/wn_phi;

% aerodinâmica 
C_l_alpha = 2*pi; % lift-slope
rho = 1.225; % desidade do ar
k = @(V,omega) omega*b/V;

%% Aerodinâmica
% C_k = besselh(1,2,k)/(besselh(1,2,k)+1i*besselh(0,2,k)); % função de Theodorsen
C_k = @(V, omega) 1-0.165/(1-0.041*1i/k(V, omega))-0.335/(1-0.32*1i/k(V, omega)); % aproximação de Jones

F_k = @(V, omega) real(C_k(V, omega));
G_k = @(V, omega) imag(C_k(V, omega));
% derivadas aerodinâmicas
L_h       =  @(V, omega) 2*pi*(-k(V, omega)^2/2-k(V, omega)*G_k(V, omega));
L_h_dot   =  @(V, omega) 2*pi*F_k(V, omega);
L_phi     =  @(V, omega) 2*pi*(k(V, omega)^2*a_EA/2+F_k(V, omega)-k(V, omega)*G_k(V, omega)*(0.5-a_EA));
L_phi_dot =  @(V, omega) 2*pi*(0.5+F_k(V, omega)*(0.5-a_EA)+G_k(V, omega)/k(V, omega));
M_h       =  @(V, omega) 2*pi*(-k(V, omega)^2*a_EA/2-k(V, omega)*(0.5+a_EA)*G_k(V, omega));
M_h_dot   =  @(V, omega) 2*pi*((0.5+a_EA)*F_k(V, omega));
M_phi     =  @(V, omega) 2*pi*(k(V, omega)^2/2*(1/8+a_EA^2)+F_k(V, omega)*(0.5+a_EA)-k(V, omega)*G_k(V, omega)*(0.5+a_EA)*(0.5-a_EA));
M_phi_dot =  @(V, omega) 2*pi*(-k(V, omega)/2*(0.5-a_EA)+k(V, omega)*F_k(V, omega)*(0.5+a_EA)*(0.5-a_EA)+G_k(V, omega)/k(V, omega)*(0.5+a_EA));

% matriz de amortecimento aerodinâmico
C_aer_w = @(V,omega) rho*V*[b*L_h_dot(V,omega)     b^2*L_phi_dot(V,omega)
                           -b^2*M_h_dot(V,omega)  -b^3*M_phi_dot(V,omega)];
% matriz de rigidez aerodinâmica
K_aer_w = @(V,omega) rho*V^2*[L_h(V,omega)      b*L_phi(V,omega)
                             -b*M_h(V,omega)   -b^2*M_phi(V,omega)];

%% Dinâmica estrutural
% matriz de massa estrutural
M = [m_w          m_w*x_cg_w
     m_w*x_cg_w   m_w*r_theta^2];
% matriz de amortecimento estrutural
C = [K_h*g_h/wn_h    0
     0               K_phi*g_phi/wn_phi];
% matriz de rigidez estrutural
K = [K_h   0
     0     K_phi];

%% Aeroelástico
V_i = 0.001:0.1:60.001;
% Divergence
det = @(V) det(K+K_aer_w(V,0));
divergence_speed = fzero(det,mean(V_i));
if divergence_speed < 0
    divergence_speed = 0;
end

% Flutter
[Freevec, Freeval] = eig([zeros(2,2)  eye(2)
                         -M\K         -M\C]);
Freeval = diag(Freeval);
[omega_i,zeta_i] = damp(Freeval);

sol(length(V_i),length(omega_i)) = struct('eigvec', [], 'eigval', [], 'w', [], 'f', [], 'zeta', []);

flutter_idx = zeros(1,length(omega_i));
% método p-k de análise aeroelástica
for j = 1:length(omega_i)
    wn_new = omega_i(j);
    eig_new = Freeval(j);
    for i = 1:length(V_i)
        V = V_i(i);
        erro = 1;
        while erro > 1e-3
            omega = wn_new;
            eig_old = eig_new;

            K_aero = K_aer_w(V,omega);
            C_aero = C_aer_w(V,omega);
        
            J = [zeros(2,2)             eye(2)
                -(M)\(K+K_aero)  -(M)\(C+C_aero)];
        
            [eigvec,eigval] = eig(J);
            eigval = diag(eigval);
            [eigval,i_sort] = sort(eigval);
            eigvec = eigvec(:,i_sort);
            
            [wn,zeta] = damp(eigval);
            
            [erro, idx] = min(abs(eigval-eig_old)); % Retorna o menor erro e o índice correspondente
            wn_new = wn(idx); % Obtém o elemento de wn correspondente ao erro
            eig_new = eigval(idx);
           
            sol(i,j).eigvec = eigvec(:,idx);
            sol(i,j).eigval = eigval(idx);
            sol(i,j).w = wn(idx);
            sol(i,j).f = wn(idx)/(2*pi); % frequências naturais
            sol(i,j).zeta = zeta(idx); % fatores de amortecimento
        end
        if any(real(sol(i,j).eigval)>1e-8) && flutter_idx(j)==0
            flutter_idx(j) = i;
        end  
    end
end
% interpolação para velocidade de flutter
flutter_i = min(flutter_idx(flutter_idx~=0));
flutter_j = find(flutter_idx == flutter_i,1);

if flutter_i>0
    pos_flutter_speed = V_i(flutter_i);
    pos_flutter_freq = sol(V_i==pos_flutter_speed,flutter_j).f;
    pos_flutter_zeta = sol(V_i==pos_flutter_speed,flutter_j).zeta;    

    pre_flutter_speed = V_i(flutter_i-1);
    pre_flutter_freq = sol(V_i==pre_flutter_speed,flutter_j).f;
    pre_flutter_zeta = sol(V_i==pre_flutter_speed,flutter_j).zeta; 

    flutter_speed = interp1([pre_flutter_zeta pos_flutter_zeta],[pre_flutter_speed pos_flutter_speed],0,'linear');
    flutter_freq  = interp1([pre_flutter_zeta pos_flutter_zeta],[pre_flutter_freq pos_flutter_freq],0,'linear');

    flutter_mech = sol(V_i==pos_flutter_speed,flutter_j).eigvec(1:2);
else
    flutter_speed = 0;
    flutter_freq = 0;
    flutter_zeta = 0;  
    flutter_mech = [0; 0];
end

%%
fprintf('Velocidade de Divergência: %f m/s\n',divergence_speed);
fprintf('Velocidade de Flutter: %f m/s\n',flutter_speed);
fprintf('Frequência de Flutter: %f Hz\n',flutter_freq);
fprintf('Mecanismo de Flutter:\n') % o mecanismo de flutter é o maior valor dentro do autovetor de flutter
fprintf('  Bending typical section: %f \n',abs(flutter_mech(1)))
fprintf('  Torsion typical section: %f \n',abs(flutter_mech(2)))

% O flutter vai ocorrer quando o fator de amortecimento \zeta cruzar o eixo
% das abcissas

figure
subplot(211)
hold on
for j = 1:size(sol, 2)
    f_values = [sol(:, j).f];
    plot(V_i, f_values);
end
xlabel('V_{\infty}')
ylabel('frequência [Hz]')
grid on
set(gca, 'XColor', 'none')
ax1=gca;

subplot(212)
hold on
for j = 1:size(sol, 2)
    zeta_values = [sol(:, j).zeta];
    plot(V_i, zeta_values);
end
xlabel('V_{\infty}')
ylabel('fator de amortecimento \zeta')
grid on
ax2 = gca;
linkaxes([ax1, ax2], 'x');
toc